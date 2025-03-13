package com.example.unhook.utils

object Constants {
    const val EXTRA_PACKAGE_NAME = "com.example.unhook.packageName"
    const val METHOD_CHANNEL_NAME = "com.example.unhook/usage_tracking"
    const val TRACKER_SERVICE_NOTIFICATION_ID = 1001

    // Method channel methods
    const val METHOD_CHECK_ACCESSIBILITY_PERMISSION = "checkAccessibilityPermission"
    const val METHOD_REQUEST_ACCESSIBILITY_PERMISSION = "requestAccessibilityPermission"
    const val METHOD_START_TRACKING_SERVICE = "startTrackingService"
    const val METHOD_STOP_TRACKING_SERVICE = "stopTrackingService"
    const val METHOD_GET_CURRENT_APP = "getCurrentApp"
}