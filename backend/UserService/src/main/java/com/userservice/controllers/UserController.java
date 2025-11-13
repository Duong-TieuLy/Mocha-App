package com.userservice.controllers;

import com.userservice.dtos.UserProfileDto;
import com.userservice.dtos.UserSyncDto;
import com.userservice.mapper.UserMapper;
import com.userservice.models.User;
import com.userservice.services.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private static final Logger log = LoggerFactory.getLogger(UserController.class);
    private final UserService service;

    public UserController(UserService service) {
        this.service = service;
    }

    // Tìm user theo email hoặc tên hiển thị
    @GetMapping("/search")
    public ResponseEntity<List<User>> searchUsers(
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String name) {

        if (email != null) {
            return service.findByEmail(email)
                    .map(user -> ResponseEntity.ok(List.of(user)))
                    .orElse(ResponseEntity.ok(List.of()));
        } else if (name != null) {
            return ResponseEntity.ok(service.searchByFullName(name));
        }
        return ResponseEntity.ok(List.of());
    }

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
    public ResponseEntity<User> syncUser(@RequestBody UserSyncDto dto) {
        log.info("🔄 POST /api/users/sync — data={}", dto);

        if (dto.getFirebaseUid() == null || dto.getFirebaseUid().isEmpty()) {
            log.error("❌ Missing firebaseUid in sync request");
            return ResponseEntity.badRequest().build();
        }
        User user = new User();
        user.setFirebaseUid(dto.getFirebaseUid());
        user.setEmail(dto.getEmail());
        user.setFullName(dto.getFullName());
        user.setUsername(dto.getUsername());
        user.setBio(dto.getBio());
        user.setInterests(dto.getInterests());
        user.setPhotoUrl(dto.getPhotoUrl());

        User saved = service.syncUser(user);
        return ResponseEntity.ok(saved);
    }
}
