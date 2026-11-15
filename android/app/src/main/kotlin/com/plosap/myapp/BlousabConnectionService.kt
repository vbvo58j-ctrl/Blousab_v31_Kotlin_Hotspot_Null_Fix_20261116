package com.plosap.myapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Keeps an Android foreground connected-device process while the app is
 * in the background. It does not restart the Flutter engine after a kill,
 * nor bypass an OS force-stop or OEM battery restrictions.
 */
class BlousabConnectionService : Service() {
    companion object {
        const val CHANNEL = "blousab_connection_status"
        const val NOTIFICATION_ID = 2281
    }
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                CHANNEL, "اتصال بلوساب", NotificationManager.IMPORTANCE_LOW
            ).apply { description = "استمرار استقبال بلوساب عند استخدام تطبيقات أخرى" })
        }
        val openApp = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL)
        } else {
            Notification.Builder(this)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_blousab)
            .setContentTitle("بلوساب نشط")
            .setContentText("جارٍ استقبال الرسائل والبحث عن أجهزة بلوساب المتاحة")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        // No "fake connectivity" status if Android kills the Flutter process.
        return START_NOT_STICKY
    }
}
