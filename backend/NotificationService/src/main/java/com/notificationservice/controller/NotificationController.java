package com.notificationservice.controller;

import com.notificationservice.dtos.FriendsNotificationRequest;
import com.notificationservice.dtos.SingleNotificationRequest;
import com.notificationservice.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/notification")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    // ================================
    // 1️⃣ Lưu FCM token
    // ================================
    @PostMapping("/save-token")
    public ResponseEntity<?> saveToken(@RequestBody Map<String, String> request) {

        String firebaseUid = request.get("firebaseUid");
        String fcmToken = request.get("fcmToken");

        if (firebaseUid == null || fcmToken == null) {
            return ResponseEntity.badRequest().body("firebaseUid hoặc fcmToken bị thiếu");
        }

        return ResponseEntity.ok(notificationService.saveToken(firebaseUid, fcmToken));
    }

    // ================================
    // 2️⃣ Gửi notification single user
    // ================================
    @PostMapping("/send")
    public ResponseEntity<?> sendNotification(@RequestBody SingleNotificationRequest req) {
        try {
            if (req.getFirebaseUid() == null) {
                return ResponseEntity.badRequest().body("firebaseUid bị thiếu");
            }

            notificationService.sendNotification(req);
            return ResponseEntity.ok("Notification sent");

        } catch (Exception e) {
            return ResponseEntity.status(500).body("Lỗi gửi thông báo: " + e.getMessage());
        }
    }

    // ================================
    // 3️⃣ Gửi notification tới bạn bè
    // ================================
    @PostMapping("/send-to-friends")
    public ResponseEntity<?> sendToFriends(@RequestBody FriendsNotificationRequest req) {
        try {
            if (req.getFirebaseUids() == null || req.getFirebaseUids().isEmpty()) {
                return ResponseEntity.badRequest().body("Danh sách firebaseUids bị trống");
            }

            notificationService.sendToFriends(req);
            return ResponseEntity.ok("Notification sent to friends");

        } catch (Exception e) {
            return ResponseEntity.status(500).body("Lỗi gửi thông báo: " + e.getMessage());
        }
    }
}
