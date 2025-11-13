package com.userservice.dtos;

import lombok.Data;

@Data
public class UserProfileDto {
    private Long id;
    private String firebaseUid;
    private String fullName;
    private String bio;
    private String interests;
    private String photoUrl;
    private int followersCount;
    private int followingCount;
    private String createdAt;
}
