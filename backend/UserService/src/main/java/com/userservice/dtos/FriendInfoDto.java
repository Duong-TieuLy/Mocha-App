package com.userservice.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class FriendInfoDto {
    private String firebaseUid;
    private String fullName;
    private String photoUrl;
    private String email;
}