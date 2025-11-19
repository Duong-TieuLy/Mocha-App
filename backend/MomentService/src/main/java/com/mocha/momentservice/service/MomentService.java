package com.mocha.momentservice.service;

import com.mocha.momentservice.model.Moment;
import com.mocha.momentservice.repository.MomentRepository;
import com.mocha.momentservice.clients.UserClient;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.stream.Collectors;

import java.util.Arrays;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MomentService {

    private final MomentRepository momentRepository;
    private final UserClient userClient;

    public Moment createMoment(String firebaseUid, String imageUrl, String caption, List<String> allowedUids) {
        if (allowedUids == null || allowedUids.isEmpty()) {
            allowedUids = userClient.getFriendFirebaseUids(firebaseUid);
        }

        Moment moment = Moment.builder()
                .firebaseUid(firebaseUid)
                .imageUrl(imageUrl)
                .caption(caption)
                .allowedUids(!allowedUids.isEmpty() ? String.join(",", allowedUids) : null)
                .build();
        return momentRepository.save(moment);
    }

    /**
     * Feed chỉ hiển thị moments của bạn bè + được phép xem
     */
    public Page<Moment> getFeed(String firebaseUid, Pageable pageable) {
        List<String> friendUids = new ArrayList<>(userClient.getFriendFirebaseUids(firebaseUid));
        friendUids.add(firebaseUid); // bao gồm chính user

        Page<Moment> allMoments = momentRepository.findByFirebaseUidInOrderByCreatedAtDesc(friendUids, pageable);

        List<Moment> filtered = allMoments.getContent().stream()
                .filter(moment -> {
                    if (moment.getAllowedUids() == null || moment.getAllowedUids().isEmpty()) {
                        return true;
                    }
                    List<String> allowed = Arrays.asList(moment.getAllowedUids().split(","));
                    return allowed.contains(firebaseUid);
                })
                .collect(Collectors.toList());

        return new PageImpl<>(filtered, pageable, allMoments.getTotalElements());
    }

    public Page<Moment> getUserMoments(String firebaseUid, Pageable pageable) {
        return momentRepository.findByFirebaseUidOrderByCreatedAtDesc(firebaseUid, pageable);
    }

    public void deleteMoment(String firebaseUid, Long momentId) {
        Moment moment = momentRepository.findById(momentId)
                .orElseThrow(() -> new IllegalArgumentException("Moment not found"));

        // Chỉ cho phép chủ sở hữu xóa
        if (!moment.getFirebaseUid().equals(firebaseUid)) {
            throw new SecurityException("You are not allowed to delete this moment");
        }

        momentRepository.delete(moment);
    }
}