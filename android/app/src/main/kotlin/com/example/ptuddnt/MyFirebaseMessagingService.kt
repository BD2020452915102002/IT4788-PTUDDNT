package com.example.ptuddnt

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.util.Log

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        // Xử lý tin nhắn nhận được từ FCM tại đây
        remoteMessage.notification?.let {
            Log.d("FCM", "Message Notification Title: ${it.title}")
            Log.d("FCM", "Message Notification Body: ${it.body}")
            // Hiển thị thông báo tới người dùng nếu cần thiết
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Gửi token mới đến máy chủ của bạn nếu cần thiết
        Log.d("FCM", "Refreshed token: $token")
    }
}