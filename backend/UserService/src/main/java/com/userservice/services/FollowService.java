package com.userservice.services;

import com.userservice.models.User;
import com.userservice.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class FollowService {

    private final UserRepository userRepository;
    private final FriendService friendService;
    private final EntityManager entityManager;

    /**
     * Follow user và tự động tạo friendship nếu mutual follow
     */
    @Transactional
    public void followUser(Long followerId, Long followingId) {
        log.info("==> START followUser: {} -> {}", followerId, followingId);
        
        if (followerId.equals(followingId)) {
            throw new IllegalArgumentException("Cannot follow yourself");
        }

        // ✅ Kiểm tra users tồn tại
        if (!userRepository.existsById(followerId)) {
            throw new RuntimeException("Follower not found: " + followerId);
        }
        if (!userRepository.existsById(followingId)) {
            throw new RuntimeException("User to follow not found: " + followingId);
        }

        // ✅ Kiểm tra đã follow chưa
        boolean alreadyFollowing = userRepository.isFollowing(followerId, followingId);
        if (alreadyFollowing) {
            log.warn("User {} already following user {}", followerId, followingId);
            throw new IllegalStateException("Already following this user");
        }

        log.debug("All checks passed, inserting follow relationship");

        // ✅ CRITICAL FIX: Insert trực tiếp vào bảng join, tránh lazy loading
        userRepository.insertFollowing(followerId, followingId);
        
        // ✅ Flush để đảm bảo data được persist
        entityManager.flush();
        
        log.info("✅ User {} followed user {} successfully", followerId, followingId);

        // ✅ Kiểm tra và tạo friendship nếu mutual follow
        try {
            friendService.createFriendshipIfMutualFollow(followerId, followingId);
        } catch (Exception e) {
            log.error("❌ Error creating friendship between {} and {}: {}", 
                     followerId, followingId, e.getMessage(), e);
            // Không throw exception để follow vẫn thành công
        }
        
        log.info("==> END followUser: {} -> {}", followerId, followingId);
    }

    /**
     * Unfollow user và xóa friendship
     */
    @Transactional
    public void unfollowUser(Long followerId, Long followingId) {
        log.info("==> START unfollowUser: {} -> {}", followerId, followingId);
        
        // ✅ Kiểm tra users tồn tại
        if (!userRepository.existsById(followerId)) {
            throw new RuntimeException("Follower not found: " + followerId);
        }
        if (!userRepository.existsById(followingId)) {
            throw new RuntimeException("User not found: " + followingId);
        }

        // ✅ Kiểm tra có đang follow không
        boolean isFollowing = userRepository.isFollowing(followerId, followingId);
        if (!isFollowing) {
            throw new IllegalStateException("Not following this user");
        }

        // ✅ Thực hiện unfollow bằng native query
        userRepository.deleteFollowing(followerId, followingId);
        
        // ✅ Flush ngay
        entityManager.flush();

        log.info("✅ User {} unfollowed user {}", followerId, followingId);

        // Xóa friendship nếu tồn tại
        try {
            friendService.deleteFriendshipIfExists(followerId, followingId);
        } catch (Exception e) {
            log.error("❌ Error deleting friendship between {} and {}: {}", 
                     followerId, followingId, e.getMessage(), e);
        }
        
        log.info("==> END unfollowUser: {} -> {}", followerId, followingId);
    }

    /**
     * Lấy danh sách người đang follow
     */
    @Transactional(readOnly = true)
    public List<User> getFollowing(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        return user.getFollowing().stream().collect(Collectors.toList());
    }

    /**
     * Lấy danh sách followers
     */
    @Transactional(readOnly = true)
    public List<User> getFollowers(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        return user.getFollowers().stream().collect(Collectors.toList());
    }

    /**
     * Đếm số người đang follow
     */
    @Transactional(readOnly = true)
    public long countFollowing(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        return user.getFollowing().size();
    }

    /**
     * Đếm số followers
     */
    @Transactional(readOnly = true)
    public long countFollowers(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        return user.getFollowers().size();
    }

    /**
     * Kiểm tra user A có đang follow user B không
     */
    @Transactional(readOnly = true)
    public boolean isFollowing(Long followerId, Long followingId) {
        return userRepository.isFollowing(followerId, followingId);
    }
}
