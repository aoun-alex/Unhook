package com.example.unhook.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.unhook.workers.UsageCheckWorker
import com.example.unhook.workers.DailyResetWorker

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "Unhook.BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "Device rebooted or app updated, scheduling monitoring")

                // Schedule the workers
                try {
                    UsageCheckWorker.schedulePeriodicCheck(context)
                    DailyResetWorker.scheduleDailyReset(context)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to schedule monitoring", e)
                }
            }
        }
    }
}