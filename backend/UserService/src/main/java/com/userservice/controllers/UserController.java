package com.userservice.controllers;

import com.userservice.dtos.UserProfileDto;
import com.userservice.mapper.UserMapper;
import com.userservice.models.User;
import com.userservice.services.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private static final Logger log = LoggerFactory.getLogger(UserController.class);
    private final UserService service;

    public UserController(UserService service) {
        this.service = service;
    }

    /**
     * 🔹 Lấy thông tin đầy đủ User (raw entity)
     */
    @GetMapping("/me")
    public ResponseEntity<User> getProfile(@RequestHeader("X-User-Id") String uid) {
        log.info("📥 GET /api/users/me — uid={}", uid);

        return service.findByFirebaseUid(uid)
                .map(ResponseEntity::ok)
                .orElseGet(() -> {
                    log.warn("⚠️ User not found for uid={}", uid);
                    return ResponseEntity.notFound().build();
                });
    }

    /**
     * 🔹 Lấy thông tin hồ sơ gọn (dành cho frontend hiển thị)
     */
    @GetMapping("/profile")
    public ResponseEntity<UserProfileDto> getCompactProfile(@RequestHeader("X-User-Id") String uid) {
        log.info("📥 GET /api/users/profile — uid={}", uid);
        return service.findByFirebaseUid(uid)
                .map(UserMapper::toProfileDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 🔹 Cập nhật hồ sơ người dùng
     */
    @PutMapping("/me")
    public ResponseEntity<User> updateProfile(
            @RequestHeader("X-User-Id") String uid,
            @RequestBody User updated) {
        log.info("📤 PUT /api/users/me — uid={}, update={}", uid, updated);
        User saved = service.updateProfile(uid, updated);
        return ResponseEntity.ok(saved);
    }

    /**
     * 🔹 Đồng bộ user từ AuthService
     */
    @PostMapping("/sync")
    public ResponseEntity<User> syncUser(@RequestBody User newUser) {
        log.info("🔄 POST /api/users/sync — data={}", newUser);

        if (newUser.getFirebaseUid() == null || newUser.getFirebaseUid().isEmpty()) {
            log.error("❌ Missing firebaseUid in sync request");
            return ResponseEntity.badRequest().build();
        }

        User saved = service.syncUser(newUser);
        log.info("✅ Synced user with firebaseUid={}", saved.getFirebaseUid());
        return ResponseEntity.ok(saved);
    }
}
