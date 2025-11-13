package com.mocha.momentservice.service;

import com.mocha.momentservice.enums.ReactionType;
import com.mocha.momentservice.model.Moment;
import com.mocha.momentservice.model.Reaction;
import com.mocha.momentservice.repository.ReactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ReactionService {

    private final ReactionRepository reactionRepository;
//    private final NotificationService notificationService; // Gọi service gửi thông báo

    // Tạo hoặc cập nhật reaction
    public Reaction reactToMoment(Moment moment, Long userId, ReactionType type) {
        Optional<Reaction> existing = reactionRepository.findByMomentIdAndUserId(moment.getId(), userId);
        Reaction reaction;
        if (existing.isPresent()) {
            reaction = existing.get();
            reaction.setReactionType(type);
        } else {
            reaction = Reaction.builder()
                    .moment(moment)
                    .userId(userId)
                    .reactionType(type)
                    .build();
        }
        Reaction saved = reactionRepository.save(reaction);

        // Gửi notification cho chủ moment
//        notificationService.sendReactionNotification(moment.getUserId(), userId, type, moment.getId());

        return saved;
    }

    // Xóa reaction
    public void removeReaction(Long momentId, Long userId) {
        reactionRepository.deleteByMomentIdAndUserId(momentId, userId);
    }

    // Lấy tất cả reactions cho moment
    public List<Reaction> getReactions(Long momentId) {
        return reactionRepository.findByMomentId(momentId);
    }

    // Thống kê số lượng reaction theo type
    public List<Object[]> countReactionsByType(Long momentId) {
        return reactionRepository.countReactionsByType(momentId);
    }

    public boolean hasReacted(Long momentId, Long userId) {
        return reactionRepository.existsByMomentIdAndUserId(momentId, userId);
    }

}