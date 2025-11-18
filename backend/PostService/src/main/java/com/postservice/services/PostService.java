package com.postservice.services;

import com.postservice.clients.NotificationClient;
import com.postservice.clients.UserClient;
import com.postservice.models.Post;
import com.postservice.repositories.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;
    private final UserClient userClient;
    private final NotificationClient notificationClient;

    public List<Post> getAllPosts() {
        return postRepository.findAll();
    }

    public Post getPostById(Long id) {
        return postRepository.findById(id).orElseThrow(() -> new RuntimeException("Post not found"));
    }

    public Post getPostByFirebaseUid(String firebaseUid) {
        return postRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    public Post createPost(Post post) {
        Post savedPost = postRepository.save(post);
        System.out.println("Post saved, id = " + savedPost.getId());

        try {
            List<String> friendUids = userClient.getFriendFirebaseUids(post.getFirebaseUid());
            System.out.println("Friend UIDs: " + friendUids);

            if (!friendUids.isEmpty()) {
                String title = "Bạn của bạn vừa đăng bài!";
                String body = post.getContent() != null ? post.getContent() : "Đã có bài viết mới";

                notificationClient.sendNotificationToFriends(friendUids, title, body,
                        Map.of("postId", savedPost.getId().toString()));
                System.out.println("Notification call sent to NotificationService");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return savedPost;
    }

    public void deletePost(Long id) {
        postRepository.deleteById(id);
    }
}
