package com.mocha.momentservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class FriendInfoDto {
    private Long userId;
    private String firebaseUid;
    private String fullName;
    private String photoUrl;
    private String email;
}