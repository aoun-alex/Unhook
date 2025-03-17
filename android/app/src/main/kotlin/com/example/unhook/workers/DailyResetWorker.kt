package com.example.unhook.workers

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.WorkManager
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import com.example.unhook.utils.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit
import java.util.Calendar

class DailyResetWorker(
    private val appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    companion object {
        private const val TAG = "DailyResetWorker"
        const val WORK_NAME = "daily_reset_work"

        // Schedule the daily reset worker
        fun scheduleDailyReset(context: Context) {
            val workManager = WorkManager.getInstance(context)

            // Create a calendar for midnight next day
            val calendar = Calendar.getInstance()
            val now = calendar.timeInMillis

            // Set time to next midnight
            calendar.add(Calendar.DAY_OF_YEAR, 1)
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)

            // Calculate initial delay
            val initialDelayMillis = calendar.timeInMillis - now
            val initialDelayMinutes = TimeUnit.MILLISECONDS.toMinutes(initialDelayMillis)

            Log.d(TAG, "Scheduling daily reset in $initialDelayMinutes minutes")

            // Create periodic work request that runs daily
            val resetWorkRequest = PeriodicWorkRequestBuilder<DailyResetWorker>(
                24, TimeUnit.HOURS
            )
                .setInitialDelay(initialDelayMillis, TimeUnit.MILLISECONDS)
                .build()

            // Enqueue unique work to ensure only one instance runs
            workManager.enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.CANCEL_AND_REENQUEUE,
                resetWorkRequest
            )
        }
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Running daily usage reset")

            // Send broadcast to Flutter to reset the usage data
            val intent = Intent(Constants.ACTION_RESET_USAGE_DATA)
            intent.setPackage(appContext.packageName)
            appContext.sendBroadcast(intent)

            // Schedule the regular usage checks
            UsageCheckWorker.schedulePeriodicCheck(appContext)

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error in daily reset worker", e)
            Result.retry()
        }
    }
}