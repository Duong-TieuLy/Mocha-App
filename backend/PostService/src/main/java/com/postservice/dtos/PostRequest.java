package com.postservice.dtos;

import lombok.Data;

@Data
public class PostRequest {
    private String firebaseUid;
    private String content;
    private String images;
}
