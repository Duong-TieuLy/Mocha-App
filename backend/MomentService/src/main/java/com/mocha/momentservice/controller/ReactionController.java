package com.mocha.momentservice.controller;

import com.mocha.momentservice.enums.ReactionType;
import com.mocha.momentservice.model.Moment;
import com.mocha.momentservice.model.Reaction;
import com.mocha.momentservice.service.MomentService;
import com.mocha.momentservice.service.ReactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/reactions")
@RequiredArgsConstructor
public class ReactionController {

    private final ReactionService reactionService;
    private final MomentService momentService;

    // React/unreact 1 moment
    @PostMapping
    public ResponseEntity<Reaction> reactToMoment(
            @RequestParam Long momentId,
            @RequestParam Long userId,
            @RequestParam ReactionType reactionType
    ) {
        Moment moment = momentService.getUserMoments(userId, null) // chỉ để lấy moment bằng id
                .stream()
                .filter(m -> m.getId().equals(momentId))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Moment not found"));

        Reaction reaction = reactionService.reactToMoment(moment, userId, reactionType);
        return ResponseEntity.ok(reaction);
    }

    // Xóa reaction
    @DeleteMapping
    public ResponseEntity<Void> removeReaction(
            @RequestParam Long momentId,
            @RequestParam Long userId
    ) {
        reactionService.removeReaction(momentId, userId);
        return ResponseEntity.noContent().build();
    }

    // Lấy tất cả reactions cho moment
    @GetMapping("/{momentId}")
    public ResponseEntity<List<Reaction>> getReactions(@PathVariable Long momentId) {
        List<Reaction> reactions = reactionService.getReactions(momentId);
        return ResponseEntity.ok(reactions);
    }

    // Thống kê reactions theo type
    @GetMapping("/{momentId}/count")
    public ResponseEntity<List<Object[]>> countReactions(@PathVariable Long momentId) {
        List<Object[]> stats = reactionService.countReactionsByType(momentId);
        return ResponseEntity.ok(stats);
    }

}

