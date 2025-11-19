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

    private final UserRepository userRepository;
    private final FriendRepository friendRepository;

    @Transactional
    public void followUser(String currentFirebaseUid, Long targetUserId) {

        User currentUser = userRepository.findByFirebaseUidWithFollowing(currentFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        User targetUser = userRepository.findByIdWithFollowing(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        if (Objects.equals(currentUser.getId(), targetUser.getId())) {
            throw new RuntimeException("Cannot follow yourself");
        }

        if (currentUser.getFollowing().contains(targetUser)) {
            throw new RuntimeException("Already following this user");
        }

        // thêm follow
        currentUser.getFollowing().add(targetUser);
        userRepository.save(currentUser);

        // tạo friendship nếu follow qua lại
        if (targetUser.getFollowing().contains(currentUser)) {
            createFriendship(currentUser, targetUser);
        }
    }

    @Transactional
    public void unfollowUser(String currentFirebaseUid, Long targetUserId) {

        User currentUser = userRepository.findByFirebaseUidWithFollowing(currentFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        currentUser.getFollowing().remove(targetUser);
        userRepository.save(currentUser);

        friendRepository.findByUsers(currentUser.getId(), targetUser.getId())
                .ifPresent(friendRepository::delete);
    }

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
    }

    public boolean isFollowing(String firebaseUid, Long targetUserId) {
        User currentUser = userRepository.findByFirebaseUidWithFollowing(firebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        return currentUser.getFollowing().stream()
                .anyMatch(u -> u.getId().equals(targetUserId));
    }

    public boolean areFriends(String firebaseUid, Long targetUserId) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        return friendRepository.findByUsers(user.getId(), targetUserId).isPresent();
    }

    public List<User> getFollowers(String firebaseUid) {

        User currentUser = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        return userRepository.findFollowers(currentUser.getId());
    }

    public List<User> getFollowing(String firebaseUid) {

        User currentUser = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        return userRepository.findFollowing(currentUser.getId());
    }

    public Map<String, Long> getFollowStats(String firebaseUid) {
        User currentUser = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        Map<String, Long> stats = new HashMap<>();
        stats.put("followers", userRepository.countFollowers(currentUser.getId()));
        stats.put("following", userRepository.countFollowing(currentUser.getId()));
        stats.put("friends", friendRepository.countFriendsByUserId(currentUser.getId()));
        return stats;
    }

    // Danh sách bạn bè
    public List<FriendInfoDto> getFriendList(String firebaseUid) {

        User currentUser = userRepository.findByFirebaseUid(firebaseUid)
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