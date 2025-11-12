package com.mocha.momentservice.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class MomentDTO {
    private Long id;
    private Long userId;
    private String imageUrl;
    private String caption;
    private LocalDateTime createdAt;
    private List<ReactionDTO> reactions;
}
