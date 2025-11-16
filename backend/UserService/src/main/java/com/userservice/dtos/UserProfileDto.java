package com.userservice.dtos;

import java.time.LocalDate;
import java.util.List;

import com.userservice.enums.Gender;

import lombok.Data;

@Data
public class UserProfileDto {
    private Long id;
    private String firebaseUid;
    private String fullName;
    private String username;
    private String email;
    private String bio;
    private List<String> interests;
    private String photoUrl;
    private LocalDate dateOfBirth;
    private String location;
    private Gender gender;
    private String phoneNumber;
    private int followersCount;
    private int followingCount;
    private String createdAt;
}
