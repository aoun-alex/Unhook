package com.example.unhook.utils

object Constants {
    const val EXTRA_PACKAGE_NAME = "com.example.unhook.packageName"
    const val METHOD_CHANNEL_NAME = "com.example.unhook/usage_tracking"
    const val TRACKER_SERVICE_NOTIFICATION_ID = 1001

    // Method channel methods
    const val METHOD_CHECK_USAGE_STATS_PERMISSION = "checkUsageStatsPermission"
    const val METHOD_REQUEST_USAGE_STATS_PERMISSION = "requestUsageStatsPermission"
    const val METHOD_START_USAGE_MONITORING = "startUsageMonitoring"
    const val METHOD_STOP_USAGE_MONITORING = "stopUsageMonitoring"
    const val METHOD_CHECK_SPECIFIC_APP_USAGE = "checkSpecificAppUsage"
    const val METHOD_CANCEL_INTENSIVE_CHECKS = "cancelIntensiveChecks"

    // Broadcast actions for communication with Flutter
    const val ACTION_CHECK_ALL_APP_USAGE = "com.example.unhook.CHECK_ALL_APP_USAGE"
    const val ACTION_USAGE_UPDATE = "com.example.unhook.USAGE_UPDATE"
    const val ACTION_RESET_USAGE_DATA = "com.example.unhook.RESET_USAGE_DATA"

    // Extra keys for broadcast intents
    const val EXTRA_USAGE_MINUTES = "com.example.unhook.usageMinutes"
    const val EXTRA_LIMIT_REACHED = "com.example.unhook.limitReached"
}