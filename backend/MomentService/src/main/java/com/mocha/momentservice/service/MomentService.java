package com.mocha.momentservice.service;

import com.mocha.momentservice.model.Moment;
import com.mocha.momentservice.repository.MomentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MomentService {

    private final MomentRepository momentRepository;

    // Tạo moment mới
    public Moment createMoment(Moment moment) {
        return momentRepository.save(moment);
    }

    // Lấy feed của bạn bè
    public Page<Moment> getFeed(List<Long> friendIds, Pageable pageable) {
        return momentRepository.findByUserIdIn(friendIds, pageable);
    }

    // Lấy moments của 1 user
    public Page<Moment> getUserMoments(Long userId, Pageable pageable) {
        return momentRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
    }

    // Xóa moment
    public void deleteMoment(Long momentId, Long userId) {
        momentRepository.deleteByIdAndUserId(momentId, userId);
    }

    // Thống kê
    public Long countMoments(Long userId) {
        return momentRepository.countByUserId(userId);
    }

}

