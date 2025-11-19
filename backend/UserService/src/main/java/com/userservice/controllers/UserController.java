package com.userservice.controllers;

import com.userservice.dtos.UserProfileDto;
import com.userservice.dtos.UserSyncDto;
import com.userservice.mapper.UserMapper;
import com.userservice.models.User;
import com.userservice.services.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private static final Logger log = LoggerFactory.getLogger(UserController.class);
    private final UserService service;

    public UserController(UserService service) {
        this.service = service;
    }

    // ========================================
    // 🆕 CHAT API ENDPOINTS
    // ========================================

    /**
     * 🔥 GET /api/users/firebase/{firebaseUid}
     * Lấy thông tin user theo Firebase UID (cho Chat Service)
     */
    @GetMapping("/firebase/{firebaseUid}")
    public ResponseEntity<?> getUserByFirebaseUid(@PathVariable String firebaseUid) {
        log.info("🔍 GET /api/users/firebase/{} — getting user for chat", firebaseUid);

        try {
            User user = service.findByFirebaseUid(firebaseUid)
                    .orElseThrow(() -> new RuntimeException("User not found with firebaseUid: " + firebaseUid));

            // Trả về full user object (bao gồm id, firebaseUid, fullName, photoUrl, etc.)
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            log.error("❌ Error getting user by firebaseUid: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * 🔥 GET /api/users/{userId}/following
     * Lấy danh sách người mà user đang follow (bạn bè cho chat)
     */
    @GetMapping("/{userId}/following")
    public ResponseEntity<?> getFollowing(@PathVariable Long userId) {
        log.info("👥 GET /api/users/{}/following — getting friends list", userId);

        try {
            List<User> following = service.getFollowing(userId);

            // Convert to simple DTO for chat
            List<Map<String, Object>> result = following.stream()
                    .map(user -> Map.of(
                            "id", user.getId(),
                            "firebaseUid", user.getFirebaseUid(),
                            "fullName", user.getFullName() != null ? user.getFullName() : "",
                            "username", user.getUsername() != null ? user.getUsername() : "",
                            "email", user.getEmail() != null ? user.getEmail() : "",
                            "photoUrl", user.getPhotoUrl() != null ? user.getPhotoUrl() : "",
                            "status", user.getStatus() != null ?
                                    Map.of("status", user.getStatus().getStatus()) :
                                    Map.of("status", "offline")
                    ))
                    .collect(Collectors.toList());

            log.info("✅ Found {} following users for userId={}", result.size(), userId);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("❌ Error getting following list: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * 🔥 GET /api/users/{userId}/followers
     * Lấy danh sách người đang follow user này
     */
    @GetMapping("/{userId}/followers")
    public ResponseEntity<?> getFollowers(@PathVariable Long userId) {
        log.info("👥 GET /api/users/{}/followers — getting followers list", userId);

        try {
            List<User> followers = service.getFollowers(userId);

            List<Map<String, Object>> result = followers.stream()
                    .map(user -> Map.of(
                            "id", user.getId(),
                            "firebaseUid", user.getFirebaseUid(),
                            "fullName", user.getFullName() != null ? user.getFullName() : "",
                            "username", user.getUsername() != null ? user.getUsername() : "",
                            "photoUrl", user.getPhotoUrl() != null ? user.getPhotoUrl() : ""
                    ))
                    .collect(Collectors.toList());

            log.info("✅ Found {} followers for userId={}", result.size(), userId);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("❌ Error getting followers list: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // ========================================
    // EXISTING ENDPOINTS (KEEP AS IS)
    // ========================================

    @GetMapping("/search")
    public ResponseEntity<List<UserProfileDto>> searchUsers(
            @RequestHeader("X-User-Id") String uid,
            @RequestParam(required = false) String keyword) {

        log.info("🔍 GET /api/users/search — keyword={}, uid={}", keyword, uid);

        if (keyword == null || keyword.trim().isEmpty()) {
            log.warn("⚠️ Search keyword is empty");
            return ResponseEntity.badRequest().build();
        }

        List<User> users = service.searchUsers(keyword, uid);

        List<UserProfileDto> result = users.stream()
                .map(UserMapper::toProfileDto)
                .collect(Collectors.toList());

        log.info("✅ Found {} users matching keyword: {}", result.size(), keyword);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/me")
    public ResponseEntity<UserProfileDto> getMyProfile(
            @RequestHeader("X-User-Id") String uid) {

        log.info("📥 GET /api/users/me — uid={}", uid);

        UserProfileDto dto = service.getUserProfile(uid);
        if (dto == null) {
            log.warn("⚠️ User not found for uid={}", uid);
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(dto);
    }

    @GetMapping("/{uid}")
    public ResponseEntity<UserProfileDto> getUserProfile(@PathVariable String uid) {

        log.info("📥 GET /api/users/{} — getting profile", uid);

        UserProfileDto dto = service.getUserProfile(uid);
        if (dto == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(dto);
    }

    @GetMapping("/profile")
    public ResponseEntity<UserProfileDto> getCompactProfile(@RequestHeader("X-User-Id") String uid) {
        log.info("📥 GET /api/users/profile — uid={}", uid);
        return service.findByFirebaseUid(uid)
                .map(UserMapper::toProfileDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping(value = "/upload-photo", consumes = "multipart/form-data")
    public ResponseEntity<String> uploadPhoto(
            @RequestHeader("X-User-Id") String uid,
            @RequestPart("file") MultipartFile file) {

        try {
            String url = service.uploadUserAvatar(uid, file);
            return ResponseEntity.ok(url);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Upload failed");
        }
    }

    @PutMapping("/me")
    public ResponseEntity<User> updateProfile(
            @RequestHeader("X-User-Id") String uid,
            @RequestBody UserProfileDto dto) {
        log.info("📤 PUT /api/users/me — uid={}, updateDto={}", uid, dto);
        User saved = service.updateProfileFromDto(uid, dto);
        return ResponseEntity.ok(saved);
    }

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