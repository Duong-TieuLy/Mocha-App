package com.notificationservice.dtos;

import lombok.Data;
import java.util.Map;

@Data
public class SingleNotificationRequest {
    private String firebaseUid;
    private String title;
    private String body;
    private Map<String, String> data;
}
