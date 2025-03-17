package com.example.unhook

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.app.AppOpsManager
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.work.WorkManager
import com.example.unhook.utils.Constants
import com.example.unhook.workers.UsageCheckWorker
import com.example.unhook.workers.DailyResetWorker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "Unhook.MainActivity"
        private const val USAGE_EVENTS_CHANNEL = "com.example.unhook/usage_events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private val usageUpdateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Constants.ACTION_USAGE_UPDATE) {
                val packageName = intent.getStringExtra(Constants.EXTRA_PACKAGE_NAME) ?: return
                val usageMinutes = intent.getIntExtra(Constants.EXTRA_USAGE_MINUTES, 0)
                val limitReached = intent.getBooleanExtra(Constants.EXTRA_LIMIT_REACHED, false)

                // Send the data to Flutter via event channel
                val eventData = HashMap<String, Any>()
                eventData["type"] = "usage_update"
                eventData["packageName"] = packageName
                eventData["usageMinutes"] = usageMinutes
                eventData["limitReached"] = limitReached

                eventSink?.success(eventData)
            } else if (intent?.action == Constants.ACTION_CHECK_ALL_APP_USAGE) {
                // Notify Flutter to check all app usage
                val eventData = HashMap<String, Any>()
                eventData["type"] = "check_all_apps"
                eventSink?.success(eventData)
            } else if (intent?.action == Constants.ACTION_RESET_USAGE_DATA) {
                // Notify Flutter to reset usage data
                val eventData = HashMap<String, Any>()
                eventData["type"] = "reset_usage_data"
                eventSink?.success(eventData)
            }
        }
    }

    private val streamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            eventSink = events
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                Constants.METHOD_CHECK_USAGE_STATS_PERMISSION -> {
                    result.success(isUsageStatsPermissionGranted())
                }
                Constants.METHOD_REQUEST_USAGE_STATS_PERMISSION -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                Constants.METHOD_START_USAGE_MONITORING -> {
                    startUsageMonitoring()
                    result.success(null)
                }
                Constants.METHOD_STOP_USAGE_MONITORING -> {
                    stopUsageMonitoring()
                    result.success(null)
                }
                Constants.METHOD_CHECK_SPECIFIC_APP_USAGE -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val limitMinutes = call.argument<Int>("limitMinutes") ?: 0
                    val appName = call.argument<String>("appName") ?: packageName

                    checkSpecificAppUsage(packageName, limitMinutes, appName)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Set up event channel for receiving updates from workers
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_EVENTS_CHANNEL)
        eventChannel?.setStreamHandler(streamHandler)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Register broadcast receiver
        val filter = IntentFilter().apply {
            addAction(Constants.ACTION_USAGE_UPDATE)
            addAction(Constants.ACTION_CHECK_ALL_APP_USAGE)
            addAction(Constants.ACTION_RESET_USAGE_DATA)
        }
        registerReceiver(usageUpdateReceiver, filter, RECEIVER_NOT_EXPORTED)
    }

    override fun onDestroy() {
        unregisterReceiver(usageUpdateReceiver)
        super.onDestroy()
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    private fun startUsageMonitoring() {
        // Schedule the periodic usage checks
        UsageCheckWorker.schedulePeriodicCheck(this)

        // Schedule the daily reset
        DailyResetWorker.scheduleDailyReset(this)

        Log.d(TAG, "Started usage monitoring")
    }

    private fun stopUsageMonitoring() {
        // Cancel all work
        WorkManager.getInstance(this).cancelUniqueWork(UsageCheckWorker.WORK_NAME)
        WorkManager.getInstance(this).cancelUniqueWork(DailyResetWorker.WORK_NAME)

        Log.d(TAG, "Stopped usage monitoring")
    }

    private fun checkSpecificAppUsage(packageName: String, limitMinutes: Int, appName: String) {
        // Schedule an immediate check for a specific app
        UsageCheckWorker.scheduleIntensiveCheck(this, packageName, limitMinutes, appName, 0)
    }
}