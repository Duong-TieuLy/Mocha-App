package com.userservice.controllers;

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

    @PutMapping("/me")
    public ResponseEntity<User> updateProfile(
            @RequestHeader("X-User-Id") String uid,
            @RequestBody User updated) {
        log.info("📤 PUT /api/users/me — uid={}, update={}", uid, updated);
        User saved = service.updateProfile(uid, updated);
        return ResponseEntity.ok(saved);
    }

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
