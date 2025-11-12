package com.userservice.controllers;

import com.userservice.dtos.FriendRequestDTO;
import com.userservice.dtos.FriendshipResponseDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.userservice.dtos.UserDTO;
import com.userservice.services.FriendService;

import java.util.List;

@RestController
@RequestMapping("/api/friends")
@RequiredArgsConstructor
public class FriendController {
    
    private final FriendService friendService;
    
    @PostMapping("/request")
    public ResponseEntity<FriendshipResponseDTO> sendFriendRequest(
            @RequestHeader("X-User-Id") Long userId,
            @RequestBody FriendRequestDTO request) {
        FriendshipResponseDTO response = friendService.sendFriendRequest(userId, request.getReceiverId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    @PutMapping("/request/{requestId}/accept")
    public ResponseEntity<FriendshipResponseDTO> acceptFriendRequest(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long requestId) {
        FriendshipResponseDTO response = friendService.acceptFriendRequest(userId, requestId);
        return ResponseEntity.ok(response);
    }
    
    @PutMapping("/request/{requestId}/reject")
    public ResponseEntity<FriendshipResponseDTO> rejectFriendRequest(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long requestId) {
        FriendshipResponseDTO response = friendService.rejectFriendRequest(userId, requestId);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/requests/pending")
    public ResponseEntity<List<FriendshipResponseDTO>> getPendingRequests(
            @RequestHeader("X-User-Id") Long userId) {
        List<FriendshipResponseDTO> requests = friendService.getPendingRequests(userId);
        return ResponseEntity.ok(requests);
    }
    
    @GetMapping
    public ResponseEntity<List<UserDTO>> getFriends(
            @RequestHeader("X-User-Id") Long userId) {
        List<UserDTO> friends = friendService.getFriends(userId);
        return ResponseEntity.ok(friends);
    }
    
    @GetMapping("/check/{friendId}")
    public ResponseEntity<Boolean> checkFriendship(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long friendId) {
        boolean areFriends = friendService.areFriends(userId, friendId);
        return ResponseEntity.ok(areFriends);
    }
    
    @DeleteMapping("/{friendId}")
    public ResponseEntity<Void> unfriend(
            @RequestHeader("X-User-Id") Long userId,
            @PathVariable Long friendId) {
        friendService.unfriend(userId, friendId);
        return ResponseEntity.noContent().build();
    }
}
