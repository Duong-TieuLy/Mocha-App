package com.userservice.controllers;

import com.userservice.models.UserStatus;
import com.userservice.services.StatusService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users/status")
public class StatusController {
    private final StatusService service;

    public StatusController(StatusService service) {
        this.service = service;
    }

    @PutMapping("/{userId}")
    public ResponseEntity<UserStatus> updateStatus(
            @PathVariable Long userId,
            @RequestParam boolean online) {
        return ResponseEntity.ok(service.updateStatus(userId, online));
    }

    @GetMapping("/{userId}")
    public ResponseEntity<UserStatus> getStatus(@PathVariable Long userId) {
        return ResponseEntity.ok(service.getStatus(userId));
    }
}
