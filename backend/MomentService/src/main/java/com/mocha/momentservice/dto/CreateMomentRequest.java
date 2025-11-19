package com.mocha.momentservice.dto;

import lombok.Data;

import java.util.List;

@Data
public class CreateMomentRequest {
    private String imageUrl;
    private String caption;
    private List<String> allowedUids;
}
