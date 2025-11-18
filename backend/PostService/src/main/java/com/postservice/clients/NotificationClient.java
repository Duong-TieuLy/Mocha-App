package com.postservice.clients;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class NotificationClient {

    private final RestTemplate restTemplate;

    private static final String SINGLE_NOTIFICATION_URL =
            "http://notificationservice:8085/api/notification/send";

    private static final String FRIENDS_NOTIFICATION_URL =
            "http://notificationservice:8085/api/notification/send-to-friends";

    public void sendNotification(String firebaseUid,
                                 String title,
                                 String body,
                                 Map<String, String> data) {
        try {
            Map<String, Object> request = Map.of(
                    "firebaseUid", firebaseUid,
                    "title", title,
                    "body", body,
                    "data", data
            );

            restTemplate.postForObject(SINGLE_NOTIFICATION_URL, request, String.class);

        } catch (Exception e) {
            System.out.println("Lỗi gửi notification: " + e.getMessage());
        }
    }

    public void sendNotificationToFriends(List<String> firebaseUids,
                                          String title,
                                          String body,
                                          Map<String, String> data) {
        try {
            Map<String, Object> request = Map.of(
                    "firebaseUids", firebaseUids,
                    "title", title,
                    "body", body,
                    "data", data
            );

            restTemplate.postForObject(FRIENDS_NOTIFICATION_URL, request, String.class);
        } catch (Exception e) {
            System.out.println("Lỗi gửi notification cho friends: " + e.getMessage());
        }
    }
}
