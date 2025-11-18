package com.postservice.clients;

import lombok.RequiredArgsConstructor;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class UserClient {

    private final RestTemplate restTemplate;

    private final String USER_SERVICE_URL = "http://userservice:8082/api/users/follow/followers";

    public List<String> getFriendFirebaseUids(String firebaseUid) {

        HttpHeaders headers = new HttpHeaders();
        headers.add("X-User-Id", firebaseUid);

        HttpEntity<Void> entity = new HttpEntity<>(headers);

        ResponseEntity<List<Map<String, Object>>> response =
                restTemplate.exchange(
                        USER_SERVICE_URL,
                        HttpMethod.GET,
                        entity,
                        new ParameterizedTypeReference<List<Map<String, Object>>>() {}
                );

        List<Map<String, Object>> friends = response.getBody();

        if (friends == null) return List.of();

        return friends.stream()
                .map(f -> (String) f.get("firebaseUid"))
                .toList();
    }
}
