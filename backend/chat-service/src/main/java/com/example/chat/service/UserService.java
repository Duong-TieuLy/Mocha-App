package com.example.chat.service;

import com.example.chat.model.BlockedUser;
import com.example.chat.repository.BlockedUserRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class UserService {

    private final BlockedUserRepository blockedUserRepo;

    public UserService(BlockedUserRepository blockedUserRepo) {
        this.blockedUserRepo = blockedUserRepo;
    }

    /**
     * Block a user
     * @param userId the user who wants to block someone
     * @param blockedUserId the user to be blocked
     */
    public void blockUser(String userId, String blockedUserId) {
        // Kiểm tra tồn tại để tránh duplicate
        boolean exists = blockedUserRepo.existsByUserIdAndBlockedUserId(userId, blockedUserId);
        if (!exists) {
            blockedUserRepo.save(new BlockedUser(userId, blockedUserId, Instant.now()));
        }
    }

    /**
     * Optional: check if a user is blocked
     */
    public boolean isBlocked(String userId, String blockedUserId) {
        return blockedUserRepo.existsByUserIdAndBlockedUserId(userId, blockedUserId);
    }
}
