package com.mocha.momentservice.controller;

import com.mocha.momentservice.dto.CreateMomentRequest;
import com.mocha.momentservice.model.Moment;
import com.mocha.momentservice.service.MomentService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/moments")
@RequiredArgsConstructor
public class MomentController {

    private final MomentService momentService;

    /**
     * Tạo moment mới
     * Nếu allowedUids null → mặc định cho tất cả bạn bè
     */
    @PostMapping("/create")
    public ResponseEntity<Moment> createMoment(
            @RequestHeader("X-User-Id") String firebaseUid,
            @RequestBody CreateMomentRequest request
    ) {
        Moment moment = momentService.createMoment(
                firebaseUid,
                request.getImageUrl(),
                request.getCaption(),
                request.getAllowedUids() // có thể null
        );
        return ResponseEntity.ok(moment);
    }

    /**
     * Feed bạn bè + những moment được phép xem
     */
    @GetMapping("/feed")
    public ResponseEntity<Page<Moment>> getFeed(
            @RequestHeader("X-User-Id") String firebaseUid,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Page<Moment> feed = momentService.getFeed(firebaseUid, PageRequest.of(page, size));
        return ResponseEntity.ok(feed);
    }

    /**
     * Lấy tất cả moment của một user
     */
    @GetMapping("/user")
    public ResponseEntity<Page<Moment>> getUserMoments(
            @RequestHeader("X-User-Id") String firebaseUid,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Page<Moment> moments = momentService.getUserMoments(firebaseUid, PageRequest.of(page, size));
        return ResponseEntity.ok(moments);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteMoment(
            @RequestHeader("X-User-Id") String firebaseUid ,
            @PathVariable Long id
    ) {
        try {
            momentService.deleteMoment(firebaseUid, id);
            return ResponseEntity.ok("Moment deleted successfully");
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(e.getMessage());
        }
    }
}
