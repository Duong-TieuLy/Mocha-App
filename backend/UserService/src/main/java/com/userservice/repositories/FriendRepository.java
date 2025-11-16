package com.userservice.repositories;

import com.userservice.models.Friend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {

    /**
     * Tìm friendship giữa 2 user (bất kể thứ tự)
     */
    @Query("SELECT f FROM Friend f WHERE " +
            "(f.user1.id = :userId1 AND f.user2.id = :userId2) OR " +
            "(f.user1.id = :userId2 AND f.user2.id = :userId1)")
    Optional<Friend> findByUsers(@Param("userId1") Long userId1,
                                 @Param("userId2") Long userId2);

    /**
     * Lấy tất cả bạn bè của một user
     */
    @Query("SELECT f FROM Friend f WHERE f.user1.id = :userId OR f.user2.id = :userId")
    List<Friend> findAllByUserId(@Param("userId") Long userId);

    /**
     * Đếm số lượng bạn bè
     */
    @Query("SELECT COUNT(f) FROM Friend f WHERE f.user1.id = :userId OR f.user2.id = :userId")
    long countFriendsByUserId(@Param("userId") Long userId);
}