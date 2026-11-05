package com.conceptos.cplan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createMessagesChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.conceptos.cplan/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Per device + signing key, and survives OS updates (unlike
                    // Build.ID, which the app used to send as its appid).
                    "getAndroidId" -> result.success(
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                    )
                    else -> result.notImplemented()
                }
            }
    }

    // FCM posts to this channel (default_notification_channel_id in the
    // manifest). High importance so messages pop up as they did with OneSignal.
    private fun createMessagesChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "messages",
            "Berichten",
            NotificationManager.IMPORTANCE_HIGH,
        )
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }
}
