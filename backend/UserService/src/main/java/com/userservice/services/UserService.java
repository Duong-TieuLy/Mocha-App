package com.userservice.services;

import com.userservice.dtos.UserProfileDto;
import com.userservice.mapper.UserMapper;
import com.userservice.models.User;
import com.userservice.repositories.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Lấy thông tin user theo Firebase UID
     */
    public Optional<User> findByFirebaseUid(String firebaseUid) {
        return userRepository.findByFirebaseUid(firebaseUid);
    }
    /**
     * Lấy thông tin profile
     */
    public Optional<UserProfileDto> getProfileByFirebaseUid(String firebaseUid) {
        return userRepository.findByFirebaseUid(firebaseUid).map(UserMapper::toProfileDto);
    }
    /**
     * Cập nhật hồ sơ người dùng
     */
    public User updateProfile(String uid, User updated) {
        User user = userRepository.findByFirebaseUid(uid).orElseGet(() -> {
            User u = new User();
            u.setFirebaseUid(uid);
            u.setCreatedAt(LocalDateTime.now());
            return u;
        });

        // Cập nhật các trường có thể null-safe
        if (updated.getFullName() != null) user.setFullName(updated.getFullName());
        if (updated.getBio() != null) user.setBio(updated.getBio());
        if (updated.getInterests() != null) user.setInterests(updated.getInterests());
        if (updated.getPhotoUrl() != null) user.setPhotoUrl(updated.getPhotoUrl());

        user.setUpdatedAt(LocalDateTime.now());
        return userRepository.save(user);
    }

    /**
     * Đồng bộ user từ AuthService → UserService
     * Nếu user chưa tồn tại thì tạo mới chỉ với firebaseUid
     */
    public User syncUser(User newUser) {
        if (newUser.getFirebaseUid() == null || newUser.getFirebaseUid().isEmpty()) {
            throw new IllegalArgumentException("Firebase UID cannot be null or empty");
        }

        return userRepository.findByFirebaseUid(newUser.getFirebaseUid())
                .orElseGet(() -> {
                    newUser.setCreatedAt(LocalDateTime.now());
                    newUser.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(newUser);
                });
    }
}
