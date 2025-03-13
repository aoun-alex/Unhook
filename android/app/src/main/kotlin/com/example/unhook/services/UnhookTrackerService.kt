package com.example.unhook.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.unhook.MainActivity
import com.example.unhook.R
import com.example.unhook.services.UnhookAccessibilityService.Companion.ACTION_NEW_APP_LAUNCHED
import com.example.unhook.services.UnhookAccessibilityService.Companion.ACTION_START_MANUAL_TRACKING
import com.example.unhook.services.UnhookAccessibilityService.Companion.ACTION_STOP_MANUAL_TRACKING
import com.example.unhook.utils.Constants
import java.util.Timer
import java.util.TimerTask
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import java.util.SortedMap
import java.util.TreeMap

class UnhookTrackerService : Service() {
    companion object {
        private const val TAG = "Unhook.TrackerService"
        private const val NOTIFICATION_CHANNEL_ID = "unhook_tracking_channel"
        private const val POLL_INTERVAL_MS = 1000L // 1 second polling when using fallback
    }

    private val binder = LocalBinder()
    private var currentApp: String = ""
    private var isAccessibilityEnabled = false
    private var pollTimer: Timer? = null

    // Broadcast receiver for app launch events
    private val appLaunchReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                ACTION_NEW_APP_LAUNCHED -> {
                    val packageName = intent.getStringExtra(Constants.EXTRA_PACKAGE_NAME) ?: return
                    handleAppLaunch(packageName)
                }
                ACTION_START_MANUAL_TRACKING -> {
                    isAccessibilityEnabled = false
                    startManualTracking()
                }
                ACTION_STOP_MANUAL_TRACKING -> {
                    isAccessibilityEnabled = true
                    stopManualTracking()
                }
            }
        }
    }

    inner class LocalBinder : Binder() {
        fun getService(): UnhookTrackerService = this@UnhookTrackerService
    }

    override fun onCreate() {
        super.onCreate()

        // Create notification channel
        createNotificationChannel()

        // Register broadcast receiver
        val filter = IntentFilter().apply {
            addAction(ACTION_NEW_APP_LAUNCHED)
            addAction(ACTION_START_MANUAL_TRACKING)
            addAction(ACTION_STOP_MANUAL_TRACKING)
        }
        registerReceiver(appLaunchReceiver, filter)

        // Start as foreground service
        startForeground(Constants.TRACKER_SERVICE_NOTIFICATION_ID, createNotification())

        // Check if accessibility service is running
        isAccessibilityEnabled = isAccessibilityServiceEnabled()
        if (!isAccessibilityEnabled) {
            startManualTracking()
        }

        Log.d(TAG, "Tracker service created")
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceClassName = UnhookAccessibilityService::class.java.canonicalName
        val enabledServices = android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.contains(packageName + "/" + serviceClassName)
    }

    private fun startManualTracking() {
        Log.d(TAG, "Starting manual tracking via UsageStatsManager")
        stopManualTracking() // Clear any existing timer

        pollTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    val foregroundApp = getForegroundAppPackageName()
                    if (foregroundApp != null && foregroundApp != currentApp) {
                        handleAppLaunch(foregroundApp)
                    }
                }
            }, 0, POLL_INTERVAL_MS)
        }
    }

    private fun stopManualTracking() {
        pollTimer?.cancel()
        pollTimer = null
    }

    private fun getForegroundAppPackageName(): String? {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            // Get usage stats for the last 10 seconds
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, time - 10000, time)

            // Find the app that was used most recently
            if (stats != null) {
                val sortedMap: SortedMap<Long, UsageStats> = TreeMap()
                for (usageStats in stats) {
                    sortedMap[usageStats.lastTimeUsed] = usageStats
                }
                if (sortedMap.isNotEmpty()) {
                    return sortedMap[sortedMap.lastKey()]?.packageName
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app", e)
        }
        return null
    }

    private fun handleAppLaunch(packageName: String) {
        Log.d(TAG, "App launched: $packageName")
        currentApp = packageName
        // Use this method to handle app launches - store them or notify Flutter via method channel
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        return START_STICKY
    }

    override fun onDestroy() {
        stopManualTracking()
        unregisterReceiver(appLaunchReceiver)
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Usage Tracking"
            val descriptionText = "Tracks app usage in the background"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(getString(R.string.tracker_service_notification_title))
            .setContentText(getString(R.string.tracker_service_notification_content))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    fun getCurrentApp(): String {
        return currentApp
    }
}