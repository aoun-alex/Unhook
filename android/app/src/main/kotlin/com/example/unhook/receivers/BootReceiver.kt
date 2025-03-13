package com.example.unhook.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.unhook.services.UnhookTrackerService

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "Unhook.BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "Device rebooted or app updated, starting tracker service")

                // Start the tracker service
                try {
                    val serviceIntent = Intent(context, UnhookTrackerService::class.java)
                    context.startService(serviceIntent)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start tracker service", e)
                }
            }
        }
    }
}