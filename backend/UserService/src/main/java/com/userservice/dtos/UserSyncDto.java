package com.userservice.dtos;

import lombok.Data;
import java.util.List;

@Data
public class UserSyncDto {
    private String firebaseUid;
    private String email;
    private String fullName;
    private String username;
    private String bio;
    private List<String> interests;
    private String photoUrl;
}
