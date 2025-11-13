package com.userservice.controllers;

import com.userservice.dtos.FriendshipResponseDTO;
import com.userservice.services.FriendService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/friendships")
@RequiredArgsConstructor
public class FriendController {

    private final FriendService friendshipService;

    /**
     * Lấy danh sách bạn bè
     * GET /api/friendships/{userId}
     */
    @GetMapping("/{userId}")
    public ResponseEntity<List<FriendshipResponseDTO>> getFriends(
            @PathVariable Long userId) {
        List<FriendshipResponseDTO> friends = friendshipService.getFriends(userId);
        return ResponseEntity.ok(friends);
    }

    /**
     * Kiểm tra 2 user có phải bạn bè không
     * GET /api/friendships/check?userId1=1&userId2=2
     */
    @GetMapping("/check")
    public ResponseEntity<Map<String, Boolean>> checkFriendship(
            @RequestParam Long userId1,
            @RequestParam Long userId2) {
        boolean areFriends = friendshipService.areFriends(userId1, userId2);
        Map<String, Boolean> response = new HashMap<>();
        response.put("areFriends", areFriends);
        return ResponseEntity.ok(response);
    }

    /**
     * Lấy số lượng bạn bè
     * GET /api/friendships/{userId}/count
     */
    @GetMapping("/{userId}/count")
    public ResponseEntity<Map<String, Long>> countFriends(
            @PathVariable Long userId) {
        long count = friendshipService.countFriends(userId);
        Map<String, Long> response = new HashMap<>();
        response.put("friendCount", count);
        return ResponseEntity.ok(response);
    }

    /**
     * Lấy danh sách ID của bạn bè (tối ưu cho queries)
     * GET /api/friendships/{userId}/ids
     */
    @GetMapping("/{userId}/ids")
    public ResponseEntity<List<Long>> getFriendIds(
            @PathVariable Long userId) {
        List<Long> friendIds = friendshipService.getFriendIds(userId);
        return ResponseEntity.ok(friendIds);
    }
}