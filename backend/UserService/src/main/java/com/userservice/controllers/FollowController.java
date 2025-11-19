package com.userservice.controllers;

import com.userservice.services.FollowService;
import com.userservice.dtos.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users/follow")
@RequiredArgsConstructor
public class FollowController {

    private final FollowService followService;

    @PostMapping("/{userId}")
    public ResponseEntity<ApiResponse> follow(@PathVariable Long userId,
                                              @RequestHeader("X-User-Id") String firebaseUid) {
        followService.followUser(firebaseUid, userId);
        return ResponseEntity.ok(new ApiResponse(true, "Followed successfully"));
    }

    @DeleteMapping("/{userId}")
    public ResponseEntity<ApiResponse> unfollow(@PathVariable Long userId,
                                                @RequestHeader("X-User-Id") String firebaseUid) {
        followService.unfollowUser(firebaseUid, userId);
        return ResponseEntity.ok(new ApiResponse(true, "Unfollowed successfully"));
    }

    @GetMapping("/check/{userId}")
    public ResponseEntity<Boolean> isFollowing(@PathVariable Long userId,
                                               @RequestHeader("X-User-Id") String firebaseUid) {
        return ResponseEntity.ok(followService.isFollowing(firebaseUid, userId));
    }

    @GetMapping("/friends/{userId}")
    public ResponseEntity<Boolean> areFriends(@PathVariable Long userId,
                                              @RequestHeader("X-User-Id") String firebaseUid) {
        return ResponseEntity.ok(followService.areFriends(firebaseUid, userId));
    }

    @GetMapping("/followers")
    public ResponseEntity<?> followers(@RequestHeader("X-User-Id") String firebaseUid) {
        return ResponseEntity.ok(followService.getFollowers(firebaseUid));
    }

    @GetMapping("/following")
    public ResponseEntity<?> following(@RequestHeader("X-User-Id") String firebaseUid) {
        return ResponseEntity.ok(followService.getFollowing(firebaseUid));
    }

    @GetMapping("/friends")
    public ResponseEntity<?> getFriends(@RequestHeader("X-User-Id") String firebaseUid) {
        return ResponseEntity.ok(followService.getFriendList(firebaseUid));
    }

    @GetMapping("/stats")
    public ResponseEntity<?> stats(@RequestHeader("X-User-Id") String firebaseUid) {
        return ResponseEntity.ok(followService.getFollowStats(firebaseUid));
    }
}


