package com.example.chat.repository;

import com.example.chat.model.BlockedUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BlockedUserRepository extends JpaRepository<BlockedUser, String> {

    boolean existsByUserIdAndBlockedUserId(String userId, String blockedUserId);

    // Optional: Kiểm tra xem user A có block user B không
    default boolean isBlocked(String userId, String blockedUserId) {
        return existsByUserIdAndBlockedUserId(userId, blockedUserId);
    }
}