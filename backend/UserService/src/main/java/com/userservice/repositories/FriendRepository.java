package com.userservice.repositories;

import com.userservice.enums.FriendshipStatus;
import com.userservice.models.Friend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {

    // ===== THÊM @Query cho method này =====
    @Query("SELECT f FROM Friend f WHERE f.sender.id = :senderId AND f.receiver.id = :receiverId")
    Optional<Friend> findBySenderIdAndReceiverId(
            @Param("senderId") Long senderId,
            @Param("receiverId") Long receiverId
    );

    // Lấy tất cả friendship theo status
    @Query("SELECT f FROM Friend f WHERE " +
            "(f.sender.id = :userId OR f.receiver.id = :userId) " +
            "AND f.status = :status")
    List<Friend> findByUserIdAndStatus(
            @Param("userId") Long userId,
            @Param("status") FriendshipStatus status
    );

    // Lấy lời mời đang chờ (người nhận)
    @Query("SELECT f FROM Friend f " +
            "JOIN FETCH f.sender " +
            "WHERE f.receiver.id = :userId AND f.status = 'PENDING'")
    List<Friend> findPendingRequestsByReceiverId(@Param("userId") Long userId);

    // Lấy danh sách bạn bè
    @Query("SELECT f FROM Friend f " +
            "JOIN FETCH f.sender " +
            "JOIN FETCH f.receiver " +
            "WHERE (f.sender.id = :userId OR f.receiver.id = :userId) " +
            "AND f.status = 'ACCEPTED'")
    List<Friend> findFriendsByUserId(@Param("userId") Long userId);

    // Kiểm tra đã là bạn
    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END " +
            "FROM Friend f WHERE " +
            "((f.sender.id = :userId1 AND f.receiver.id = :userId2) OR " +
            "(f.sender.id = :userId2 AND f.receiver.id = :userId1)) " +
            "AND f.status = 'ACCEPTED'")
    boolean areFriends(
            @Param("userId1") Long userId1,
            @Param("userId2") Long userId2
    );

    // Kiểm tra đã có request chưa
    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END " +
            "FROM Friend f WHERE " +
            "((f.sender.id = :userId1 AND f.receiver.id = :userId2) OR " +
            "(f.sender.id = :userId2 AND f.receiver.id = :userId1))")
    boolean existsBetweenUsers(
            @Param("userId1") Long userId1,
            @Param("userId2") Long userId2
    );
}