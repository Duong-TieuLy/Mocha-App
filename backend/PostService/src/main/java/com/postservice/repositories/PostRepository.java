package com.postservice.repositories;

import com.postservice.models.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PostRepository extends JpaRepository<Post, Long> {
    Optional<Post> findByFirebaseUid(String firebaseUid);
    // Lấy tất cả post của user với paging, sắp xếp theo createdAt giảm dần
    Page<Post> findAllByFirebaseUidOrderByCreatedAtDesc(String firebaseUid, Pageable pageable);

    // Lấy tất cả post với paging, sắp xếp theo createdAt giảm dần (cho explore page)
    Page<Post> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
