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
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.stream.Collectors;

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
    public ResponseEntity<List<UserProfileDto>> searchUsers(
            @RequestHeader("X-User-Id") String uid,
            @RequestParam(required = false) String keyword) {

        log.info("🔍 GET /api/users/search — keyword={}, uid={}", keyword, uid);

        if (keyword == null || keyword.trim().isEmpty()) {
            log.warn("⚠️ Search keyword is empty");
            return ResponseEntity.badRequest().build();
        }

        List<User> users = service.searchUsers(keyword, uid); // truyền uid để loại bỏ bản thân

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


    /**
     * 🔹 Cập nhật hồ sơ người dùng
     */
    @PutMapping("/me")
    public ResponseEntity<User> updateProfile(
            @RequestHeader("X-User-Id") String uid,
            @RequestBody UserProfileDto dto) {
        log.info("📤 PUT /api/users/me — uid={}, updateDto={}", uid, dto);
        User saved = service.updateProfileFromDto(uid, dto);
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
