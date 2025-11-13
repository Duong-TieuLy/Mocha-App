package com.userservice.mapper;

import com.userservice.dtos.UserProfileDto;
import com.userservice.models.User;

import java.time.format.DateTimeFormatter;

public class UserMapper {

    public static UserProfileDto toProfileDto(User user) {
        if (user == null) return null;

        UserProfileDto dto = new UserProfileDto();
        dto.setId(user.getId());
        dto.setFirebaseUid(user.getFirebaseUid());
        dto.setFullName(user.getFullName());
        dto.setBio(user.getBio());
        dto.setInterests(user.getInterests());
        dto.setPhotoUrl(user.getPhotoUrl());

        // Đếm follower/following an toàn
        dto.setFollowersCount(user.getFollowers() != null ? user.getFollowers().size() : 0);
        dto.setFollowingCount(user.getFollowing() != null ? user.getFollowing().size() : 0);

        if (user.getCreatedAt() != null) {
            dto.setCreatedAt(user.getCreatedAt()
                    .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
        }

        return dto;
    }
}
