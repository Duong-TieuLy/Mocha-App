package com.mocha.momentservice.controller;

import com.mocha.momentservice.model.Moment;
import com.mocha.momentservice.service.MomentService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/moments")
@RequiredArgsConstructor
public class MomentController {

    private final MomentService momentService;

    // Tạo moment mới
    @PostMapping
    public ResponseEntity<Moment> createMoment(@RequestBody Moment moment) {
        Moment saved = momentService.createMoment(moment);
        return ResponseEntity.ok(saved);
    }

    // Lấy feed của bạn bè (paginated)
    @GetMapping("/feed")
    public ResponseEntity<Page<Moment>> getFeed(
            @RequestParam List<Long> friendIds,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Page<Moment> feed = momentService.getFeed(friendIds, PageRequest.of(page, size));
        return ResponseEntity.ok(feed);
    }

    // Lấy moments của 1 user
    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<Moment>> getUserMoments(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Page<Moment> moments = momentService.getUserMoments(userId, PageRequest.of(page, size));
        return ResponseEntity.ok(moments);
    }

    // Xóa moment
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMoment(@PathVariable Long id, @RequestParam Long userId) {
        momentService.deleteMoment(id, userId);
        return ResponseEntity.noContent().build();
    }

}

