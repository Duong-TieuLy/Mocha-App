package com.userservice.repositories;

import com.userservice.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User,Long> {
    Optional<User> findByFirebaseUid(String firebaseUid);

    /**
     * ✅ Tìm kiếm user theo từ khóa trong CẢ fullName VÀ email
     * Trả về kết quả nếu từ khóa xuất hiện trong bất kỳ trường nào
     */
    @Query("SELECT DISTINCT u FROM User u WHERE " +
            "LOWER(u.fullName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(u.email) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<User> searchByKeyword(@Param("keyword") String keyword);

    /**
     * Lấy danh sách người đang follow user này
     */
    @Query("SELECT u FROM User u JOIN u.following f WHERE f.id = :userId")
    List<User> findFollowers(@Param("userId") Long userId);

    /**
     * Lấy danh sách người mà user này đang follow
     */
    @Query("SELECT f FROM User u JOIN u.following f WHERE u.id = :userId")
    List<User> findFollowing(@Param("userId") Long userId);

    /**
     * Đếm số người follow
     */
    @Query("SELECT COUNT(u) FROM User u JOIN u.following f WHERE f.id = :userId")
    long countFollowers(@Param("userId") Long userId);

    /**
     * Đếm số người đang follow
     */
    @Query("SELECT COUNT(f) FROM User u JOIN u.following f WHERE u.id = :userId")
    long countFollowing(@Param("userId") Long userId);

    /**
     * Tìm user theo ID và eager load following relationship
     */
    @Query("SELECT u FROM User u LEFT JOIN FETCH u.following WHERE u.id = :userId")
    Optional<User> findByIdWithFollowing(@Param("userId") Long userId);

    /**
     * Tìm user theo Firebase UID và eager load following relationship
     */
    @Query("SELECT u FROM User u LEFT JOIN FETCH u.following WHERE u.firebaseUid = :firebaseUid")
    Optional<User> findByFirebaseUidWithFollowing(@Param("firebaseUid") String firebaseUid);

    /**
     * Kiểm tra xem user1 có đang follow user2 không
     */
    @Query("SELECT COUNT(u) > 0 FROM User u JOIN u.following f WHERE u.id = :userId AND f.id = :targetId")
    boolean isUserFollowingTarget(@Param("userId") Long userId, @Param("targetId") Long targetId);
}


