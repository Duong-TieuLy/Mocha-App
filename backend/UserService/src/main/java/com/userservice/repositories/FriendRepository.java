package com.userservice.repositories;

import com.userservice.models.Friend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {

    /**
     * Kiểm tra xem 2 user có phải bạn bè không (dùng Long ID - FAST)
     */
    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END FROM Friend f " +
            "WHERE (f.user1.id = :userId1 AND f.user2.id = :userId2) " +
            "OR (f.user1.id = :userId2 AND f.user2.id = :userId1)")
    boolean existsByUserIds(@Param("userId1") Long userId1, @Param("userId2") Long userId2);

    /**
     * Tìm friendship giữa 2 user (dùng Long ID - FAST)
     */
    @Query("SELECT f FROM Friend f " +
            "WHERE (f.user1.id = :userId1 AND f.user2.id = :userId2) " +
            "OR (f.user1.id = :userId2 AND f.user2.id = :userId1)")
    Optional<Friend> findByUserIds(@Param("userId1") Long userId1, @Param("userId2") Long userId2);

    /**
     * Lấy danh sách bạn bè của 1 user (dùng Long ID - FAST với index)
     */
    @Query("SELECT f FROM Friend f " +
            "LEFT JOIN FETCH f.user1 " +
            "LEFT JOIN FETCH f.user2 " +
            "WHERE f.user1.id = :userId OR f.user2.id = :userId")
    List<Friend> findAllByUserId(@Param("userId") Long userId);

    /**
     * Đếm số lượng bạn bè (dùng Long ID - FAST)
     */
    @Query("SELECT COUNT(f) FROM Friend f " +
            "WHERE f.user1.id = :userId OR f.user2.id = :userId")
    long countByUserId(@Param("userId") Long userId);

    /**
     * Xóa friendship (dùng Long ID - FAST)
     */
    @Modifying
    @Query("DELETE FROM Friend f " +
            "WHERE (f.user1.id = :userId1 AND f.user2.id = :userId2) " +
            "OR (f.user1.id = :userId2 AND f.user2.id = :userId1)")
    void deleteByUserIds(@Param("userId1") Long userId1, @Param("userId2") Long userId2);

    /**
     * Lấy danh sách ID của tất cả bạn bè (tối ưu cho query - FASTEST)
     */
    @Query("SELECT CASE WHEN f.user1.id = :userId THEN f.user2.id ELSE f.user1.id END " +
            "FROM Friend f " +
            "WHERE f.user1.id = :userId OR f.user2.id = :userId")
    List<Long> findAllFriendIdsByUserId(@Param("userId") Long userId);
}