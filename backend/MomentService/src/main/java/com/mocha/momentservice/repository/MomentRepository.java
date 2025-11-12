package com.mocha.momentservice.repository;


import com.mocha.momentservice.model.Moment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MomentRepository extends JpaRepository<Moment, Long> {

    @Query("SELECT m FROM Moment m WHERE m.userId IN :userIds ORDER BY m.createdAt DESC")
    Page<Moment> findByUserIdIn(@Param("userIds") List<Long> userIds, Pageable pageable);

    Page<Moment> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    @Query("SELECT m FROM Moment m WHERE m.userId = :userId AND m.createdAt >= :since ORDER BY m.createdAt DESC")
    List<Moment> findRecentMomentsByUser(@Param("userId") Long userId, @Param("since") LocalDateTime since);

    Long countByUserId(Long userId);

    void deleteByIdAndUserId(Long id, Long userId);
}
