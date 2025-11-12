package com.postservice.dtos;

import lombok.Data;

@Data
public class CommentRequest {
    private String firebaseUid;
    private String content;
}
