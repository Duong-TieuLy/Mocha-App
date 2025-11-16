package com.postservice.controllers;

import com.postservice.dtos.PostRequest;
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
    public ResponseEntity<?> getAllPosts() {
        List<Post> posts = postService.getAllPosts();
        List<Map<String, Object>> result = new ArrayList<>();

        for (Post p : posts) {
            Map<String, Object> postMap = new HashMap<>();
            postMap.put("post", p);
            postMap.put("reactions", reactionService.countReactionsByPost(p.getId()));
            result.add(postMap);
        }
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getPost(@PathVariable Long id) {
        Post post = postService.getPostById(id);
        Map<String, Object> response = new HashMap<>();
        response.put("post", post);
        response.put("reactions", reactionService.countReactionsByPost(id));
        return ResponseEntity.ok(response);
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
