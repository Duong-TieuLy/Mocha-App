package com.mocha.momentservice.rest;

import com.mocha.momentservice.dto.FriendInfoDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserClient {

    private final RestTemplate restTemplate;

    private final String userServiceBaseUrl = "http://userservice:8082/api/users";

    public List<String> getFriendFirebaseUids(String firebaseUid) {
        String url = userServiceBaseUrl + "/follow/friends";

        HttpHeaders headers = new HttpHeaders();
        headers.set("X-User-Id", firebaseUid);

        HttpEntity<Void> entity = new HttpEntity<>(headers);

        ResponseEntity<FriendInfoDto[]> response =
                restTemplate.exchange(url, HttpMethod.GET, entity, FriendInfoDto[].class);

        if (response.getBody() == null) return new ArrayList<>();

        return Arrays.stream(response.getBody())
                .map(FriendInfoDto::getFirebaseUid)
                .collect(Collectors.toCollection(ArrayList::new));
    }
}
