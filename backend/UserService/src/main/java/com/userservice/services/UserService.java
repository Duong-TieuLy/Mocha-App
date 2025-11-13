package com.userservice.services;

import com.userservice.dtos.UserProfileDto;
import com.userservice.mapper.UserMapper;
import com.userservice.models.User;
import com.userservice.repositories.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
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

    // 🔹 Tìm theo email
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    // 🔹 Tìm theo tên hiển thị (fullName)
    public List<User> searchByFullName(String fullName) {
        return userRepository.findByFullName(fullName);
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

        if (updated.getFullName() != null) user.setFullName(updated.getFullName());
        if (updated.getBio() != null) user.setBio(updated.getBio());
        if (updated.getInterests() != null) user.setInterests(updated.getInterests());
        if (updated.getPhotoUrl() != null) user.setPhotoUrl(updated.getPhotoUrl());
        if (updated.getEmail() != null) user.setEmail(updated.getEmail()); // ✅ cập nhật email

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
                .map(existing -> {
                    // Cập nhật email và tên nếu có thay đổi
                    if (newUser.getEmail() != null) existing.setEmail(newUser.getEmail());
                    if (newUser.getFullName() != null) existing.setFullName(newUser.getFullName());
                    existing.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(existing);
                })
                .orElseGet(() -> {
                    newUser.setCreatedAt(LocalDateTime.now());
                    newUser.setUpdatedAt(LocalDateTime.now());
                    return userRepository.save(newUser);
                });
    }
}
