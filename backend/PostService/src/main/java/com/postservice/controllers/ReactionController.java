package com.postservice.controllers;

import com.postservice.models.*;
import com.postservice.repositories.*;
import com.postservice.services.ReactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/reactions")
@RequiredArgsConstructor
public class ReactionController {

    private final ReactionService reactionService;
    private final ReactionRepository reactionRepository;
    private final PostRepository postRepository;
    private final CommentRepository commentRepository;

    /**
     * 🎯 Thả cảm xúc cho một bài Post
     */
    @PostMapping("/post/{postId}")
    public ResponseEntity<?> reactToPost(
            @PathVariable Long postId,
            @RequestParam String firebaseUid,
            @RequestParam ReactionType type) {

        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        // Kiểm tra xem user đã thả reaction nào trước đó chưa
        Reaction existing = reactionRepository.findByFirebaseUidAndPostId(firebaseUid, postId);
        if (existing != null) {
            existing.setType(type); // đổi loại cảm xúc
            reactionRepository.save(existing);
        } else {
            Reaction reaction = new Reaction();
            reaction.setFirebaseUid(firebaseUid);
            reaction.setType(type);
            reaction.setPost(post);
            reactionRepository.save(reaction);
        }

        Map<String, Long> reactions = reactionService.countReactionsByPost(postId);
        return ResponseEntity.ok(reactions);
    }

    /**
     * 💬 Thả cảm xúc cho một Comment
     */
    @PostMapping("/comment/{commentId}")
    public ResponseEntity<?> reactToComment(
            @PathVariable Long commentId,
            @RequestParam String firebaseUid,
            @RequestParam ReactionType type) {

        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("Comment not found"));

        Reaction existing = reactionRepository.findByFirebaseUidAndCommentId(firebaseUid, commentId);
        if (existing != null) {
            existing.setType(type);
            reactionRepository.save(existing);
        } else {
            Reaction reaction = new Reaction();
            reaction.setFirebaseUid(firebaseUid);
            reaction.setType(type);
            reaction.setComment(comment);
            reactionRepository.save(reaction);
        }

        Map<String, Long> reactions = reactionService.countReactionsByComment(commentId);
        return ResponseEntity.ok(reactions);
    }

    /**
     * ❌ Bỏ cảm xúc (unreact)
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> removeReaction(@PathVariable Long id) {
        reactionRepository.deleteById(id);
        return ResponseEntity.ok("Reaction removed successfully");
    }
}
