package com.example.unhook

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import com.example.unhook.services.UnhookAccessibilityService
import com.example.unhook.services.UnhookTrackerService
import com.example.unhook.utils.Constants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "Unhook.MainActivity"
    }

    private var methodChannel: MethodChannel? = null
    private var trackerService: UnhookTrackerService? = null
    private var boundToService = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as UnhookTrackerService.LocalBinder
            trackerService = binder.getService()
            boundToService = true
            Log.d(TAG, "Bound to tracker service")
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            trackerService = null
            boundToService = false
            Log.d(TAG, "Unbound from tracker service")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                Constants.METHOD_CHECK_ACCESSIBILITY_PERMISSION -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                Constants.METHOD_REQUEST_ACCESSIBILITY_PERMISSION -> {
                    requestAccessibilityPermission()
                    result.success(null)
                }
                Constants.METHOD_START_TRACKING_SERVICE -> {
                    startTrackerService()
                    result.success(null)
                }
                Constants.METHOD_STOP_TRACKING_SERVICE -> {
                    stopTrackerService()
                    result.success(null)
                }
                Constants.METHOD_GET_CURRENT_APP -> {
                    val currentApp = trackerService?.getCurrentApp() ?: ""
                    result.success(currentApp)
                }
                else -> result.notImplemented()
            }
        }

        // Bind to tracker service if it's running
        bindTrackerService()
    }

    private fun bindTrackerService() {
        val intent = Intent(this, UnhookTrackerService::class.java)
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceClassName = UnhookAccessibilityService::class.java.canonicalName
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.contains(packageName + "/" + serviceClassName)
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun startTrackerService() {
        val intent = Intent(this, UnhookTrackerService::class.java)
        startService(intent)

        if (!boundToService) {
            bindTrackerService()
        }
    }

    private fun stopTrackerService() {
        val intent = Intent(this, UnhookTrackerService::class.java)
        stopService(intent)

        if (boundToService) {
            unbindService(serviceConnection)
            boundToService = false
        }
    }

    override fun onDestroy() {
        if (boundToService) {
            unbindService(serviceConnection)
            boundToService = false
        }
        super.onDestroy()
    }
}