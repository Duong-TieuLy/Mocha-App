package com.example.chat.controller;

import com.example.chat.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/{userId}/block")
    public ResponseEntity<?> blockUser(
            @PathVariable String userId,
            @RequestParam String blockedUserId
    ) {
        try {
            userService.blockUser(userId, blockedUserId);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "User blocked successfully"
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }
}