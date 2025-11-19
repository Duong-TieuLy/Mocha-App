package com.userservice.repositories;

import com.userservice.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByFirebaseUid(String firebaseUid);

    // Tìm kiếm theo keyword
    @Query("""
        SELECT DISTINCT u FROM User u 
        WHERE LOWER(u.fullName) LIKE LOWER(CONCAT('%', :keyword, '%')) 
           OR LOWER(u.email) LIKE LOWER(CONCAT('%', :keyword, '%'))
    """)
    List<User> searchByKeyword(@Param("keyword") String keyword);

    // Ai đang follow user này
    @Query("""
        SELECT u FROM User u 
        JOIN u.following f 
        WHERE f.id = :userId
    """)
    List<User> findFollowers(@Param("userId") Long userId);

    // User này đang follow ai
    @Query("""
        SELECT f FROM User u 
        JOIN u.following f 
        WHERE u.id = :userId
    """)
    List<User> findFollowing(@Param("userId") Long userId);

    @Query("""
        SELECT COUNT(u) FROM User u 
        JOIN u.following f 
        WHERE f.id = :userId
    """)
    long countFollowers(@Param("userId") Long userId);

    @Query("""
        SELECT COUNT(f) FROM User u 
        JOIN u.following f 
        WHERE u.id = :userId
    """)
    long countFollowing(@Param("userId") Long userId);

    @Query("""
        SELECT u FROM User u 
        LEFT JOIN FETCH u.following 
        WHERE u.id = :userId
    """)
    Optional<User> findByIdWithFollowing(@Param("userId") Long userId);

    @Query("""
        SELECT u FROM User u 
        LEFT JOIN FETCH u.following 
        WHERE u.firebaseUid = :firebaseUid
    """)
    Optional<User> findByFirebaseUidWithFollowing(@Param("firebaseUid") String firebaseUid);

    @Query("""
        SELECT COUNT(u) > 0 FROM User u 
        JOIN u.following f 
        WHERE u.id = :userId AND f.id = :targetId
    """)
    boolean isUserFollowingTarget(
            @Param("userId") Long userId,
            @Param("targetId") Long targetId
    );
}
