package com.userservice.services;

import com.userservice.models.User;
import com.userservice.models.Friend;
import com.userservice.repositories.UserRepository;
import com.userservice.repositories.FriendRepository;
import com.userservice.dtos.FriendInfoDto;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@RequiredArgsConstructor
public class FollowService {

    private static final Logger log = LoggerFactory.getLogger(FollowService.class);

    private final UserRepository userRepository;
    private final FriendRepository friendRepository;

    /**
     * Follow một user
     * Nếu follow qua lại → tạo quan hệ bạn bè
     */
    @Transactional
    public void followUser(String currentUserFirebaseUid, Long targetUserId) {

        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        if (currentUser.getId().equals(targetUser.getId())) {
            throw new RuntimeException("Cannot follow yourself");
        }

        // Kiểm tra đã follow chưa
        if (currentUser.getFollowing().contains(targetUser)) {
            throw new RuntimeException("Already following this user");
        }

        // Lưu follow
        currentUser.getFollowing().add(targetUser);
        userRepository.saveAndFlush(currentUser); // đảm bảo insert record

        // Nếu target cũng follow current → tạo friend
        if (targetUser.getFollowing().contains(currentUser)) {
            createFriendship(currentUser, targetUser);
        }

        log.info("User {} followed user {}", currentUser.getId(), targetUser.getId());
    }

    /**
     * Unfollow một user
     * Nếu đang là bạn → gỡ friend
     */
    @Transactional
    public void unfollowUser(String currentUserFirebaseUid, Long targetUserId) {

        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        currentUser.getFollowing().remove(targetUser);
        userRepository.save(currentUser);

        // Gỡ friend nếu có
        friendRepository.findByUsers(currentUser.getId(), targetUser.getId())
                .ifPresent(friendRepository::delete);

        log.info("User {} unfollowed user {}", currentUser.getId(), targetUser.getId());
    }

    /**
     * Tạo quan hệ bạn bè khi follow qua lại
     */
    @Transactional
    public void createFriendship(User a, User b) {
        if (friendRepository.findByUsers(a.getId(), b.getId()).isPresent()) return;

        Friend f = new Friend();
        if (a.getId() < b.getId()) {
            f.setUser1(a);
            f.setUser2(b);
        } else {
            f.setUser1(b);
            f.setUser2(a);
        }

        friendRepository.save(f);
        log.info("Friendship created between {} and {}", a.getId(), b.getId());
    }

    /**
     * Kiểm tra đang follow
     */
    public boolean isFollowing(String currentUserFirebaseUid, Long targetUserId) {
        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));
        return currentUser.getFollowing().stream()
                .anyMatch(u -> u.getId().equals(targetUserId));
    }

    /**
     * Kiểm tra có phải bạn bè
     */
    public boolean areFriends(String currentUserFirebaseUid, Long targetUserId) {
        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));
        return friendRepository.findByUsers(currentUser.getId(), targetUserId).isPresent();
    }

    /**
     * Lấy danh sách followers
     */
    public Set<User> getFollowers(String currentUserFirebaseUid) {
        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));
        return currentUser.getFollowers();
    }

    /**
     * Lấy danh sách following
     */
    public Set<User> getFollowing(String currentUserFirebaseUid) {
        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));
        return currentUser.getFollowing();
    }

    /**
     * Thống kê follow/following
     */
    public Map<String, Long> getFollowStats(String currentUserFirebaseUid) {
        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));
        Map<String, Long> stats = new HashMap<>();
        stats.put("followers", (long) currentUser.getFollowers().size());
        stats.put("following", (long) currentUser.getFollowing().size());
        stats.put("friends", friendRepository.countFriendsByUserId(currentUser.getId()));
        return stats;
    }

    public List<FriendInfoDto> getFriendList(String currentUserFirebaseUid) {

        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        List<Friend> friendships = friendRepository.findAllByUserId(currentUser.getId());

        return friendships.stream()
                .map(f -> f.getOtherUser(currentUser.getId())) // lấy người bạn còn lại
                .filter(Objects::nonNull)
                .map(user -> new FriendInfoDto(
                        user.getId(),
                        user.getFirebaseUid(),
                        user.getFullName(),
                        user.getPhotoUrl(),
                        user.getEmail()
                ))
                .toList();
    }
}