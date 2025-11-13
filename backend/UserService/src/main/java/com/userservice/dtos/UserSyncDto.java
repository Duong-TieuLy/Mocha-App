package com.userservice.dtos;

import lombok.Data;

@Data
public class UserSyncDto {
    private String firebaseUid;
    private String email;
    private String fullName;
    private String username;
    private String bio;
    private String interests;
    private String photoUrl;
}
