package com.mocha.momentservice.repository;

import com.mocha.momentservice.model.Reaction;
import com.mocha.momentservice.enums.ReactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReactionRepository extends JpaRepository<Reaction, Long> {

    Optional<Reaction> findByMomentIdAndUserId(Long momentId, Long userId);

    List<Reaction> findByMomentId(Long momentId);

    @Query("SELECT r.reactionType, COUNT(r) FROM Reaction r WHERE r.moment.id = :momentId GROUP BY r.reactionType")
    List<Object[]> countReactionsByType(@Param("momentId") Long momentId);

    Long countByMomentId(Long momentId);

    void deleteByMomentIdAndUserId(Long momentId, Long userId);

    boolean existsByMomentIdAndUserId(Long momentId, Long userId);
}