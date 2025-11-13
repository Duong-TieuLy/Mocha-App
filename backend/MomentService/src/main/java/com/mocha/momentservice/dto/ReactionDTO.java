package com.mocha.momentservice.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ReactionDTO {
    private Long id;
    private Long userId;
    private String reactionType;
    private LocalDateTime createdAt;
}