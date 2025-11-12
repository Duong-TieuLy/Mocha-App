package com.postservice.services;

import com.postservice.models.Reaction;
import com.postservice.models.ReactionType;
import com.postservice.repositories.ReactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ReactionService {

    private final ReactionRepository reactionRepository;

    public Reaction addReaction(Reaction reaction) {
        return reactionRepository.save(reaction);
    }

    public Map<String, Long> countReactionsByPost(Long postId) {
        List<Object[]> counts = reactionRepository.countByPostIdGroupByType(postId);
        Map<String, Long> result = new HashMap<>();
        for (Object[] row : counts) {
            result.put(((ReactionType) row[0]).name(), (Long) row[1]);
        }
        return result;
    }

    public Map<String, Long> countReactionsByComment(Long commentId) {
        List<Object[]> counts = reactionRepository.countByCommentIdGroupByType(commentId);
        Map<String, Long> result = new HashMap<>();
        for (Object[] row : counts) {
            result.put(((ReactionType) row[0]).name(), (Long) row[1]);
        }
        return result;
    }
}
