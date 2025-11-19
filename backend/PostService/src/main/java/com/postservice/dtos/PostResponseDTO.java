package com.postservice.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class PostResponseDTO {
    private String firebaseUid;
    private String content;
    private String images;
    private int likeCount;
    private int commentCount; // số lượng comment
}
