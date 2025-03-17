package com.example.unhook.workers

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.Data
import androidx.work.workDataOf
import com.example.unhook.MainActivity
import com.example.unhook.R
import com.example.unhook.utils.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

class UsageCheckWorker(
    private val appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    companion object {
        private const val TAG = "UsageCheckWorker"

        const val WORK_NAME = "usage_check_work"
        const val INTENSIVE_WORK_NAME = "intensive_check_work"

        const val KEY_PACKAGE_NAME = "package_name"
        const val KEY_LIMIT_MINUTES = "limit_minutes"
        const val KEY_APP_NAME = "app_name"

        const val NOTIFICATION_CHANNEL_WARNING = "unhook_warning_channel"
        const val NOTIFICATION_CHANNEL_ALERT = "unhook_alert_channel"

        // Notification IDs - use a base and add app hash to avoid collisions
        const val NOTIFICATION_ID_WARNING = 2001
        const val NOTIFICATION_ID_LIMIT = 3001

        // Schedule a standard periodic check
        fun schedulePeriodicCheck(context: Context) {
            val workManager = WorkManager.getInstance(context)

            // Cancel any existing work first
            workManager.cancelUniqueWork(WORK_NAME)

            // Create a new work request
            val workRequest = androidx.work.PeriodicWorkRequestBuilder<UsageCheckWorker>(
                20, TimeUnit.MINUTES, // Run every 20 minutes
                5, TimeUnit.MINUTES  // With 5-minute flexibility
            ).build()

            // Enqueue the work as unique, so we don't have multiple workers running
            workManager.enqueueUniquePeriodicWork(
                WORK_NAME,
                androidx.work.ExistingPeriodicWorkPolicy.CANCEL_AND_REENQUEUE,
                workRequest
            )

            Log.d(TAG, "Scheduled periodic usage check")
        }

        // Schedule an intensive check for apps nearing their limits
        fun scheduleIntensiveCheck(
            context: Context,
            packageName: String,
            limitMinutes: Int,
            appName: String,
            delayMinutes: Int = 5
        ) {
            val workManager = WorkManager.getInstance(context)

            // Create input data
            val inputData = workDataOf(
                KEY_PACKAGE_NAME to packageName,
                KEY_LIMIT_MINUTES to limitMinutes,
                KEY_APP_NAME to appName
            )

            // Create a new work request that will run once after the delay
            val workRequest = OneTimeWorkRequestBuilder<UsageCheckWorker>()
                .setInputData(inputData)
                .setInitialDelay(delayMinutes.toLong(), TimeUnit.MINUTES)
                .addTag(packageName) // Tag with package name for identification
                .build()

            // Enqueue the work
            workManager.enqueue(workRequest)

            Log.d(TAG, "Scheduled intensive check for $packageName in $delayMinutes minutes")
        }

        // Cancel intensive checks for a specific package
        fun cancelIntensiveChecks(context: Context, packageName: String) {
            val workManager = WorkManager.getInstance(context)
            workManager.cancelAllWorkByTag(packageName)
            Log.d(TAG, "Cancelled intensive checks for $packageName")
        }
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        Log.d(TAG, "Starting usage check work")

        try {
            // Initialize notification channels
            createNotificationChannels()

            // Check if we're doing an intensive check for a specific app
            val packageName = inputData.getString(KEY_PACKAGE_NAME)
            if (packageName != null) {
                // This is an intensive check for a specific app
                val limitMinutes = inputData.getInt(KEY_LIMIT_MINUTES, 0)
                val appName = inputData.getString(KEY_APP_NAME) ?: packageName

                if (limitMinutes > 0) {
                    checkSpecificApp(packageName, limitMinutes, appName)
                }
            } else {
                // This is a regular check for all apps with limits
                checkAllApps()
            }

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error in usage check worker", e)
            Result.failure()
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = appContext.getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager

            // Warning channel (80% of limit)
            val warningChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_WARNING,
                appContext.getString(R.string.warning_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = appContext.getString(R.string.warning_channel_description)
            }

            // Alert channel (95% of limit or limit reached)
            val alertChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ALERT,
                appContext.getString(R.string.alert_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = appContext.getString(R.string.alert_channel_description)
            }

            notificationManager.createNotificationChannel(warningChannel)
            notificationManager.createNotificationChannel(alertChannel)
        }
    }

    private suspend fun checkAllApps() {
        Log.d(TAG, "Checking all apps with limits")

        // This method would communicate with Flutter to get all apps with limits
        // and check their usage

        // Trigger the method channel to ask Flutter to perform the check
        val intent = Intent(Constants.ACTION_CHECK_ALL_APP_USAGE)
        intent.setPackage(appContext.packageName)
        appContext.sendBroadcast(intent)
    }

    private suspend fun checkSpecificApp(packageName: String, limitMinutes: Int, appName: String) {
        Log.d(TAG, "Checking specific app: $packageName")

        // Get the usage stats manager
        val usageStatsManager = appContext.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        // Calculate timeframe (today)
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)

        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        // Query usage stats for today
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        // Find the stats for our package
        var totalTimeInForeground = 0L
        for (stat in stats) {
            if (stat.packageName == packageName) {
                totalTimeInForeground += stat.totalTimeInForeground
            }
        }

        // Convert to minutes
        val usageMinutes = (totalTimeInForeground / (1000 * 60)).toInt()

        // Calculate percentage of limit
        val percentUsed = (usageMinutes.toDouble() / limitMinutes.toDouble()) * 100

        Log.d(TAG, "App usage for $packageName: $usageMinutes min (${percentUsed.toInt()}% of limit)")

        // Check if notification flags are already set for today
        val sharedPrefs = appContext.getSharedPreferences("notification_flags", Context.MODE_PRIVATE)
        val todayDate = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())

        val limitReachedFlagKey = "${packageName}_limit_reached_$todayDate"
        val nearLimitFlagKey = "${packageName}_near_limit_$todayDate"
        val approachingLimitFlagKey = "${packageName}_approaching_limit_$todayDate"

        val limitReachedNotified = sharedPrefs.getBoolean(limitReachedFlagKey, false)
        val nearLimitNotified = sharedPrefs.getBoolean(nearLimitFlagKey, false)
        val approachingLimitNotified = sharedPrefs.getBoolean(approachingLimitFlagKey, false)

        // Update Flutter about the current usage in all cases
        val isLimitReached = percentUsed >= 100
        sendUsageUpdateToDart(packageName, usageMinutes, isLimitReached)

        // Check if we need to show notifications or schedule more checks
        when {
            percentUsed >= 100 && !limitReachedNotified -> {
                // Limit reached and not yet notified for today
                showLimitReachedNotification(packageName, usageMinutes, limitMinutes, appName)

                // Save that we've shown this notification today
                sharedPrefs.edit().putBoolean(limitReachedFlagKey, true).apply()
            }
            percentUsed >= 95 && !nearLimitNotified -> {
                // Near limit (95%+) and not yet notified for today
                showNearLimitNotification(packageName, usageMinutes, limitMinutes, appName)

                // Save that we've shown this notification today
                sharedPrefs.edit().putBoolean(nearLimitFlagKey, true).apply()

                // Schedule more frequent checks
                scheduleIntensiveCheck(appContext, packageName, limitMinutes, appName, 2)
            }
            percentUsed >= 80 && !approachingLimitNotified -> {
                // Approaching limit (80%+) and not yet notified for today
                showApproachingLimitNotification(packageName, usageMinutes, limitMinutes, appName)

                // Save that we've shown this notification today
                sharedPrefs.edit().putBoolean(approachingLimitFlagKey, true).apply()

                // Schedule more frequent checks
                scheduleIntensiveCheck(appContext, packageName, limitMinutes, appName, 5)
            }
            percentUsed >= 95 -> {
                // Already notified, but still near limit, schedule checks
                scheduleIntensiveCheck(appContext, packageName, limitMinutes, appName, 2)
            }
            percentUsed >= 80 -> {
                // Already notified, but still approaching limit, schedule checks
                scheduleIntensiveCheck(appContext, packageName, limitMinutes, appName, 5)
            }
        }
    }

    private fun sendUsageUpdateToDart(packageName: String, usageMinutes: Int, limitReached: Boolean) {
        val intent = Intent(Constants.ACTION_USAGE_UPDATE)
        intent.setPackage(appContext.packageName)
        intent.putExtra(Constants.EXTRA_PACKAGE_NAME, packageName)
        intent.putExtra(Constants.EXTRA_USAGE_MINUTES, usageMinutes)
        intent.putExtra(Constants.EXTRA_LIMIT_REACHED, limitReached)
        appContext.sendBroadcast(intent)
    }

    private fun showApproachingLimitNotification(packageName: String, usageMinutes: Int, limitMinutes: Int, appName: String) {
        val pendingIntent = createPendingIntent()

        val notification = NotificationCompat.Builder(appContext, NOTIFICATION_CHANNEL_WARNING)
            .setContentTitle(appContext.getString(R.string.approaching_limit_title))
            .setContentText(appContext.getString(
                R.string.approaching_limit_text,
                appName,
                usageMinutes,
                limitMinutes
            ))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val notificationManager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Use a unique notification ID based on the package name
        val notificationId = NOTIFICATION_ID_WARNING + packageName.hashCode() % 1000
        notificationManager.notify(notificationId, notification)
    }

    private fun showNearLimitNotification(packageName: String, usageMinutes: Int, limitMinutes: Int, appName: String) {
        val pendingIntent = createPendingIntent()

        val notification = NotificationCompat.Builder(appContext, NOTIFICATION_CHANNEL_ALERT)
            .setContentTitle(appContext.getString(R.string.near_limit_title))
            .setContentText(appContext.getString(
                R.string.near_limit_text,
                appName,
                usageMinutes,
                limitMinutes,
                limitMinutes - usageMinutes
            ))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val notificationManager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Use a unique notification ID based on the package name
        val notificationId = NOTIFICATION_ID_WARNING + packageName.hashCode() % 1000
        notificationManager.notify(notificationId, notification)
    }

    private fun showLimitReachedNotification(packageName: String, usageMinutes: Int, limitMinutes: Int, appName: String) {
        val pendingIntent = createPendingIntent()

        val notification = NotificationCompat.Builder(appContext, NOTIFICATION_CHANNEL_ALERT)
            .setContentTitle(appContext.getString(R.string.limit_reached_title))
            .setContentText(appContext.getString(
                R.string.limit_reached_text,
                appName,
                usageMinutes,
                limitMinutes
            ))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val notificationManager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Use a unique notification ID based on the package name
        val notificationId = NOTIFICATION_ID_LIMIT + packageName.hashCode() % 1000
        notificationManager.notify(notificationId, notification)
    }

    private fun createPendingIntent(): PendingIntent {
        val intent = Intent(appContext, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP

        return PendingIntent.getActivity(
            appContext,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )
    }
}