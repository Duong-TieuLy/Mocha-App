package com.userservice.dtos;

import lombok.Data;

@Data
public class UserProfileDTO {
    private String fullName;
    private String bio;
    private String interests;
    private String photoUrl;
}