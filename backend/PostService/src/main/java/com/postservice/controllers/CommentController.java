package com.postservice.controllers;

import com.postservice.dtos.CommentRequest;
import com.postservice.models.Comment;
import com.postservice.services.CommentService;
import com.postservice.services.ReactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;

@RestController
@RequestMapping("/api/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;
    private final ReactionService reactionService;

    @PostMapping("/post/{postId}")
    public ResponseEntity<?> createComment(@PathVariable Long postId, @RequestBody CommentRequest commentRequest) {
        Comment comment = new Comment();
        comment.setFirebaseUid(commentRequest.getFirebaseUid());
        comment.setContent(commentRequest.getContent());
        comment.setCreatedAt(Instant.now());
        return ResponseEntity.ok(commentService.createComment(postId, comment));
    }

    @GetMapping("/{commentId}/reactions")
    public ResponseEntity<?> getCommentReactions(@PathVariable Long commentId) {
        Map<String, Long> reactions = reactionService.countReactionsByComment(commentId);
        return ResponseEntity.ok(reactions);
    }
}
