package com.userservice.controllers;

import com.userservice.models.User;
import com.userservice.services.FollowService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/follow")
@RequiredArgsConstructor
@Slf4j  // ✅ Thêm logging
public class FollowController {

    private final FollowService followService;

    /**
     * Follow user
     * POST /api/follow/{followingId}
     * Header: X-User-Id (ID của người đang thực hiện follow)
     */
    @PostMapping("/{followingId}")
    public ResponseEntity<Map<String, String>> followUser(
            @RequestHeader("X-User-Id") Long followerId,
            @PathVariable Long followingId) {
        log.info("🎯 Controller received follow request: {} -> {}", followerId, followingId);
        try {
            followService.followUser(followerId, followingId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "Successfully followed user");
            log.info("✅ Controller: Follow successful");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.error("❌ Controller: IllegalArgumentException - {}", e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage() != null ? e.getMessage() : "Invalid argument");
            return ResponseEntity.badRequest().body(error);
        } catch (IllegalStateException e) {
            log.error("❌ Controller: IllegalStateException - {}", e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage() != null ? e.getMessage() : "Invalid state");
            return ResponseEntity.badRequest().body(error);
        } catch (RuntimeException e) {
            log.error("❌ Controller: RuntimeException - {}", e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage() != null ? e.getMessage() : "Runtime error occurred");
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            log.error("❌ Controller: Unexpected exception - {}", e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage() != null ? e.getMessage() : "An unexpected error occurred");
            error.put("type", e.getClass().getSimpleName());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Unfollow user
     * DELETE /api/follow/{followingId}
     */
    @DeleteMapping("/{followingId}")
    public ResponseEntity<Map<String, String>> unfollowUser(
            @RequestHeader("X-User-Id") Long followerId,
            @PathVariable Long followingId) {
        log.info("🎯 Controller received unfollow request: {} -> {}", followerId, followingId);
        try {
            followService.unfollowUser(followerId, followingId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "Successfully unfollowed user");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("❌ Controller: Unfollow error - {}", e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage() != null ? e.getMessage() : "Error during unfollow");
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Lấy danh sách người đang follow
     * GET /api/follow/{userId}/following
     */
    @GetMapping("/{userId}/following")
    public ResponseEntity<List<User>> getFollowing(@PathVariable Long userId) {
        List<User> following = followService.getFollowing(userId);
        return ResponseEntity.ok(following);
    }

    /**
     * Lấy danh sách followers
     * GET /api/follow/{userId}/followers
     */
    @GetMapping("/{userId}/followers")
    public ResponseEntity<List<User>> getFollowers(@PathVariable Long userId) {
        List<User> followers = followService.getFollowers(userId);
        return ResponseEntity.ok(followers);
    }

    /**
     * Đếm số người đang follow
     * GET /api/follow/{userId}/following/count
     */
    @GetMapping("/{userId}/following/count")
    public ResponseEntity<Map<String, Long>> countFollowing(@PathVariable Long userId) {
        long count = followService.countFollowing(userId);
        Map<String, Long> response = new HashMap<>();
        response.put("followingCount", count);
        return ResponseEntity.ok(response);
    }

    /**
     * Đếm số followers
     * GET /api/follow/{userId}/followers/count
     */
    @GetMapping("/{userId}/followers/count")
    public ResponseEntity<Map<String, Long>> countFollowers(@PathVariable Long userId) {
        long count = followService.countFollowers(userId);
        Map<String, Long> response = new HashMap<>();
        response.put("followerCount", count);
        return ResponseEntity.ok(response);
    }

    /**
     * Kiểm tra có đang follow không
     * GET /api/follow/check?followerId=1&followingId=2
     */
    @GetMapping("/check")
    public ResponseEntity<Map<String, Boolean>> checkFollowing(
            @RequestParam Long followerId,
            @RequestParam Long followingId) {
        boolean isFollowing = followService.isFollowing(followerId, followingId);
        Map<String, Boolean> response = new HashMap<>();
        response.put("isFollowing", isFollowing);
        return ResponseEntity.ok(response);
    }
}