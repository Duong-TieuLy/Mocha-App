package com.userservice.services;

import com.userservice.dtos.UserProfileDto;
import com.userservice.enums.Gender;
import com.userservice.mapper.UserMapper;
import com.userservice.models.User;
import com.userservice.repositories.UserRepository;
import org.apache.commons.io.FilenameUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.nio.file.Path;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

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

    public List<User> searchUsers(String keyword, String excludeUid) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return List.of();
        }

        List<User> users = userRepository.searchByKeyword(keyword.trim());

        // Loại bỏ user hiện tại
        if (excludeUid != null && !excludeUid.isEmpty()) {
            users.removeIf(u -> excludeUid.equals(u.getFirebaseUid()));
        }

        return users;
    }


    public String uploadUserAvatar(String uid, MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        // sanitize extension
        String original = file.getOriginalFilename();
        String ext = "";
        if (original != null && original.contains(".")) {
            ext = "." + FilenameUtils.getExtension(original);
        }

        String filename = uid + "_" + UUID.randomUUID() + ext;
        Path folder = Paths.get("uploads", "avatars");
        Files.createDirectories(folder);
        Path path = folder.resolve(filename);

        // write file
        Files.write(path, file.getBytes());

        // set URL accessible: build absolute url based on current request host
        String baseUrl = ServletUriComponentsBuilder.fromCurrentContextPath().build().toUriString();
        String url = baseUrl + "/static/avatars/" + filename;

        // Lưu url vào User
        User user = userRepository.findByFirebaseUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setPhotoUrl(url);
        userRepository.save(user);

        return url;
    }


    /**
     * Cập nhật hồ sơ người dùng
     */
    public User updateProfileFromDto(String uid, UserProfileDto dto) {
        User user = userRepository.findByFirebaseUid(uid).orElseGet(() -> {
            User u = new User();
            u.setFirebaseUid(uid);
            u.setCreatedAt(LocalDateTime.now());
            return u;
        });

        if (dto.getFullName() != null) user.setFullName(dto.getFullName());
        if (dto.getBio() != null) user.setBio(dto.getBio());

        // interests: convert List<String> -> comma separated string
        if (dto.getInterests() != null) {
            user.setInterests(dto.getInterests());
        }

        if (dto.getPhotoUrl() != null) user.setPhotoUrl(dto.getPhotoUrl());
        if (dto.getUsername() != null) user.setUsername(dto.getUsername());
        if (dto.getLocation() != null) user.setLocation(dto.getLocation());
        if (dto.getPhoneNumber() != null) user.setPhoneNumber(dto.getPhoneNumber());

        if (dto.getDateOfBirth() != null) {
            user.setDateOfBirth(dto.getDateOfBirth());
        }
        if (dto.getGender() != null) {
            try {
                user.setGender(dto.getGender());
            } catch (IllegalArgumentException e) {
                // invalid gender string: ignore or throw BadRequest
            }
        }
        user.setUpdatedAt(LocalDateTime.now());
        return userRepository.save(user);
    }

    public UserProfileDto getUserProfile(String uid) {
        return userRepository.findByFirebaseUid(uid)
                .map(UserMapper::toProfileDto)
                .orElse(null);
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
