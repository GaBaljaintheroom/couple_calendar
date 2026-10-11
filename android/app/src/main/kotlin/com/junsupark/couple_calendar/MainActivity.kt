package com.junsupark.couple_calendar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createEventChannel()
    }

    /**
     * 푸시 알림 채널. AndroidManifest의 default_notification_channel_id("events")와 같고,
     * 서버(functions/index.js)도 이 채널로 보낸다. 이미 있으면 아무 일도 하지 않는다.
     */
    private fun createEventChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "events",
            "일정 알림",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = "상대가 등록한 새 일정과 오늘 일정을 알려줘요" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
