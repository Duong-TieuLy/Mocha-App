package com.userservice.services;

import com.userservice.models.User;
import com.userservice.models.UserStatus;
import com.userservice.repositories.UserStatusRepository;
import com.userservice.repositories.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class StatusService {
    private final UserRepository userRepository;
    private final UserStatusRepository userStatusRepository;

    public StatusService(UserRepository userRepository, UserStatusRepository userStatusRepository) {
        this.userRepository = userRepository;
        this.userStatusRepository = userStatusRepository;
    }

    public UserStatus updateStatus(Long userId, boolean online) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        UserStatus status = userStatusRepository.findById(userId)
                .orElse(new UserStatus());

        status.setUser(user);
        status.setOnline(online);
        status.setLastSeen(LocalDateTime.now());

        return userStatusRepository.save(status);
    }

    public UserStatus getStatus(Long userId) {
        return userStatusRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User status not found"));
    }
}
