package com.postservice.services;

import com.postservice.models.Post;
import com.postservice.repositories.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import java.util.List;
import com.postservice.dtos.PostResponseDTO;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;

    // Lấy post của một user theo page & size
    public List<PostResponseDTO> getPostsByUser(String firebaseUid, int page, int size) {
        PageRequest pageable = PageRequest.of(page, size);
        Page<Post> postPage = postRepository.findAllByFirebaseUidOrderByCreatedAtDesc(firebaseUid, pageable);

        return postPage.getContent().stream().map(post ->
                new PostResponseDTO(
                        post.getFirebaseUid(),
                        post.getContent(),
                        post.getImages(),
                        post.getLikeCount(),
                        post.getComments() != null ? post.getComments().size() : 0
                )
        ).toList();
    }

    // Lấy tất cả post (Explore Page) theo page & size
    public List<PostResponseDTO> getAllPosts(int page, int size) {
        PageRequest pageable = PageRequest.of(page, size);
        Page<Post> postPage = postRepository.findAllByOrderByCreatedAtDesc(pageable);

        return postPage.getContent().stream().map(post ->
                new PostResponseDTO(
                        post.getFirebaseUid(),
                        post.getContent(),
                        post.getImages(),
                        post.getLikeCount(),
                        post.getComments() != null ? post.getComments().size() : 0
                )
        ).toList();
    }

    public Post createPost(Post post) {
        return postRepository.save(post);
    }

    public void deletePost(Long id) {
        postRepository.deleteById(id);
    }
}
