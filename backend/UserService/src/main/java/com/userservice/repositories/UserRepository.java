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
    // Tìm theo tên hiển thị (có thể match một phần)
    List<User> findByFullName(String fullName);

    Optional<User> findByEmail(String email);

    /**
     * ✅ Kiểm tra user có đang follow user khác không (dùng query trực tiếp - FAST)
     * Tránh lazy loading N+1 problem
     */
    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END " +
           "FROM User u JOIN u.following f " +
           "WHERE u.id = :followerId AND f.id = :followingId")
    boolean isFollowing(@Param("followerId") Long followerId, 
                       @Param("followingId") Long followingId);
    
    /**
     * ✅ Thêm follow relationship trực tiếp vào bảng join (tránh lazy loading)
     * CRITICAL: Dùng native query để insert trực tiếp, không trigger lazy loading
     */
    @Modifying
    @Query(value = "INSERT INTO user_following (follower_id, following_id) VALUES (:followerId, :followingId)", 
           nativeQuery = true)
    void insertFollowing(@Param("followerId") Long followerId, 
                        @Param("followingId") Long followingId);
    
    /**
     * ✅ Xóa follow relationship trực tiếp (tránh lazy loading)
     */
    @Modifying
    @Query(value = "DELETE FROM user_following WHERE follower_id = :followerId AND following_id = :followingId", 
           nativeQuery = true)
    void deleteFollowing(@Param("followerId") Long followerId, 
                        @Param("followingId") Long followingId);
}

