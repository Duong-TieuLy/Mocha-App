package com.userservice.services;

import com.userservice.dtos.FriendshipResponseDTO;
import com.userservice.dtos.UserDTO;
import com.userservice.models.Friend;
import com.userservice.models.User;
import com.userservice.repositories.FriendRepository;
import com.userservice.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class FriendService {

    private final FriendRepository friendRepository;
    private final UserRepository userRepository;

    // ============================================================
    // ===============   SEND FRIEND REQUEST   =====================
    // ============================================================

    @Transactional
    public void unfriend(String currentUserFirebaseUid, Long targetUserId) {

        User currentUser = userRepository.findByFirebaseUid(currentUserFirebaseUid)
                .orElseThrow(() -> new RuntimeException("Current user not found"));

        User targetUser = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        // Kiểm tra quan hệ bạn
        Friend friendship = friendRepository.findByUsers(currentUser.getId(), targetUserId)
                .orElseThrow(() -> new RuntimeException("Not friends"));

        // Xóa friend
        friendRepository.delete(friendship);

        log.info("🗑️ Users {} and {} are no longer friends", currentUser.getId(), targetUserId);
    }
}
