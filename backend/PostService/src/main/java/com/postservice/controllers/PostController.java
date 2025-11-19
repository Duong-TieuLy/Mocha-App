package com.postservice.controllers;

import com.postservice.dtos.PostRequest;
import com.postservice.dtos.PostResponseDTO;
import com.postservice.models.Post;
import com.postservice.services.PostService;
import com.postservice.services.ReactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;
    private final ReactionService reactionService;

    @GetMapping
    public ResponseEntity<List<PostResponseDTO>> getPosts(
            @RequestParam(required = false) String firebaseUid,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        List<PostResponseDTO> posts;
        if (firebaseUid != null && !firebaseUid.isEmpty()) {
            posts = postService.getPostsByUser(firebaseUid, page, size);
        } else {
            posts = postService.getAllPosts(page, size);
        }
        return ResponseEntity.ok(posts);
    }

    @PostMapping
    public ResponseEntity<?> createPost(@RequestBody PostRequest postRequest) {
        Post post = new Post();
        post.setFirebaseUid(postRequest.getFirebaseUid());
        post.setContent(postRequest.getContent());
        post.setImages(postRequest.getImages());
        post.setCreatedAt(Instant.now());
        return ResponseEntity.ok(postService.createPost(post));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePost(@PathVariable Long id) {
        postService.deletePost(id);
        return ResponseEntity.ok("Deleted successfully");
    }

}