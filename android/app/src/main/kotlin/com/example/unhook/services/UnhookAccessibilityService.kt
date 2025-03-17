package com.example.unhook.services

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.unhook.utils.Constants

class UnhookAccessibilityService : AccessibilityService() {
    companion object {
        private const val TAG = "Unhook.AccessibilityService"
        const val ACTION_START_MANUAL_TRACKING = "com.example.unhook.startManualTracking"
        const val ACTION_STOP_MANUAL_TRACKING = "com.example.unhook.stopManualTracking"
        const val ACTION_NEW_APP_LAUNCHED = "com.example.unhook.newAppLaunched"
    }

    private val ignoredPackages: Set<String> = setOf(
        "com.android.systemui"
    )

    private var lastActiveApp: String = ""

    override fun onServiceConnected() {
        Log.d(TAG, "Accessibility service connected")
        // Broadcast that accessibility tracking is active, so the fallback can be disabled
        val intent = Intent(ACTION_STOP_MANUAL_TRACKING)
        intent.setPackage(packageName)
        sendBroadcast(intent)
        super.onServiceConnected()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Only interested in certain event types for app tracking
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // Ignore system UI and self
        if (packageName == this.packageName || ignoredPackages.contains(packageName)) {
            return
        }

        // Only broadcast if the app has changed
        if (packageName != lastActiveApp) {
            lastActiveApp = packageName
            broadcastNewAppLaunch(packageName)
            Log.d(TAG, "App changed: $packageName")
        }
    }

    private fun broadcastNewAppLaunch(packageName: String) {
        try {
            val intent = Intent(ACTION_NEW_APP_LAUNCHED).apply {
                setPackage(this@UnhookAccessibilityService.packageName)
                putExtra(Constants.EXTRA_PACKAGE_NAME, packageName)
            }
            sendBroadcast(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to broadcast app launch event", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }

    override fun onDestroy() {
        // Broadcast that accessibility tracking has stopped, so fallback can be enabled
        val intent = Intent(ACTION_START_MANUAL_TRACKING)
        intent.setPackage(packageName)
        sendBroadcast(intent)

        Log.d(TAG, "Accessibility service destroyed")
        super.onDestroy()
    }
}