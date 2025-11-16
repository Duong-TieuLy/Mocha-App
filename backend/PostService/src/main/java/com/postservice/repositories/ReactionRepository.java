package com.postservice.repositories;

import com.postservice.models.Reaction;
import lombok.experimental.PackagePrivate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReactionRepository extends JpaRepository<Reaction, Long> {
    @Query("SELECT r.type, COUNT(r) FROM Reaction r WHERE r.post.id = :postId GROUP BY r.type")
    List<Object[]> countByPostIdGroupByType(@Param("postId") Long postId);

    @Query("SELECT r.type, COUNT(r) FROM Reaction r WHERE r.comment.id = :commentId GROUP BY r.type")
    List<Object[]> countByCommentIdGroupByType(@Param("commentId") Long commentId);

    @Query("SELECT r FROM Reaction r WHERE r.firebaseUid = :uid AND r.post.id = :postId")
    Reaction findByFirebaseUidAndPostId(@Param("uid") String firebaseUid, @Param("postId") Long postId);

    @Query("SELECT r FROM Reaction r WHERE r.firebaseUid = :uid AND r.comment.id = :commentId")
    Reaction findByFirebaseUidAndCommentId(@Param("uid") String firebaseUid, @Param("commentId") Long commentId);
}
