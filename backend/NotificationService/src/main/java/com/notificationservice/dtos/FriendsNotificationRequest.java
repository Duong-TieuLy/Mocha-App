package com.notificationservice.dtos;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class FriendsNotificationRequest {
    private List<String> firebaseUids;
    private String title;
    private String body;
    private Map<String, String> data;
}