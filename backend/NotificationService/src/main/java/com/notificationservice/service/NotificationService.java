package com.notificationservice.service;

import com.google.firebase.messaging.*;
import com.notificationservice.dtos.FriendsNotificationRequest;
import com.notificationservice.dtos.SingleNotificationRequest;
import com.notificationservice.model.UserToken;
import com.notificationservice.repository.UserTokenRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class NotificationService {

    @Autowired
    private UserTokenRepository userTokenRepository;

    // ================================
    // 1️⃣ Lưu token
    // ================================
    public UserToken saveToken(String firebaseUid, String fcmToken) {

        if (firebaseUid == null || fcmToken == null || fcmToken.isBlank()) {
            throw new RuntimeException("firebaseUid hoặc fcmToken null");
        }

        UserToken token = userTokenRepository.findByFcmToken(fcmToken)
                .orElseGet(UserToken::new);

        token.setFirebaseUid(firebaseUid);
        token.setFcmToken(fcmToken);
        token.setUpdatedAt(LocalDateTime.now());

        return userTokenRepository.save(token);
    }

    // ================================
    // 2️⃣ Gửi từ DTO (single)
    // ================================
    public void sendNotification(SingleNotificationRequest req) {
        sendNotificationToFirebaseUid(
                req.getFirebaseUid(),
                req.getTitle(),
                req.getBody(),
                req.getData()
        );
    }

    // ================================
    // 3️⃣ Gửi từ DTO (friends)
    // ================================
    public void sendToFriends(FriendsNotificationRequest req) {
        sendNotificationToMultiple(
                req.getFirebaseUids(),
                req.getTitle(),
                req.getBody(),
                req.getData()
        );
    }

    // ================================
    // 4️⃣ Logic gửi notification
    // ================================
    public void sendNotificationToFirebaseUid(
            String firebaseUid,
            String title,
            String body,
            Map<String, String> data) {

        List<UserToken> tokens = userTokenRepository.findAllByFirebaseUid(firebaseUid);

        if (tokens.isEmpty()) {
            throw new RuntimeException("Không tìm thấy FCM token của user: " + firebaseUid);
        }

        for (UserToken token : tokens) {

            Message.Builder builder = Message.builder()
                    .setToken(token.getFcmToken());

            if (title != null || body != null) {
                builder.setNotification(
                        Notification.builder()
                                .setTitle(title)
                                .setBody(body)
                                .build()
                );
            }

            if (data != null && !data.isEmpty()) {
                builder.putAllData(data);
            }

            try {
                FirebaseMessaging.getInstance().send(builder.build());

            } catch (FirebaseMessagingException e) {

                String error = String.valueOf(e.getErrorCode());

                // Token không hợp lệ → xóa
                if ("registration-token-not-registered".equals(error) ||
                        "invalid-argument".equals(error)) {

                    userTokenRepository.delete(token);
                } else {
                    throw new RuntimeException("Lỗi gửi FCM: " + error, e);
                }
            }
        }
    }

    // ================================
    // 5️⃣ Gửi tới nhiều user
    // ================================
    public void sendNotificationToMultiple(
            List<String> firebaseUids,
            String title,
            String body,
            Map<String, String> data) {

        for (String uid : firebaseUids) {
            try {
                sendNotificationToFirebaseUid(uid, title, body, data);
            } catch (Exception e) {
                System.out.println("Lỗi gửi cho user " + uid + ": " + e.getMessage());
            }
        }
    }
}
