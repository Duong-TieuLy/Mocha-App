package com.postservice.controllers;

import com.postservice.dtos.PostRequest;
import com.postservice.models.Post;
import com.postservice.services.PostService;
import com.postservice.services.ReactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
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
    public ResponseEntity<?> createPost(
            @RequestParam("caption") String caption,
            @RequestParam(value = "image", required = false) MultipartFile image,
            @RequestHeader("X-User-Id") String firebaseUid) {

        List<String> imageUrls = new ArrayList<>();
        String uploadDir = System.getProperty("user.dir") + "/uploads";
        File uploadFolder = new File(uploadDir);

        if (!uploadFolder.exists() && !uploadFolder.mkdirs()) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Could not create upload folder");
        }

        if (image != null && !image.isEmpty()) {
            String fileName = System.currentTimeMillis() + "_" + image.getOriginalFilename();
            File dest = new File(uploadFolder, fileName);

            try {
                image.transferTo(dest);
                String baseUrl = "http://localhost:8084";
                imageUrls.add(baseUrl + "/uploads/" + fileName);
            } catch (IOException e) {
                e.printStackTrace();
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("Could not save image");
            }
        }

        Post post = new Post();
        post.setFirebaseUid(firebaseUid);
        post.setContent(caption);
        post.setImages(imageUrls.isEmpty() ? null : String.join(",", imageUrls));
        post.setCreatedAt(Instant.now());

        Post savedPost = postService.createPost(post);

        return ResponseEntity.status(HttpStatus.CREATED).body(savedPost);
    }


    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePost(@PathVariable Long id) {
        postService.deletePost(id);
        return ResponseEntity.ok("Deleted successfully");
    }
}
