package com.example.chat.repository;

import com.example.chat.model.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, String> {

    // ✅ GIỮ NGUYÊN - Query cũ cho direct chat
    List<Conversation> findByUser1OrUser2OrderByLastTimeDesc(String user1, String user2);

    // 🆕 Tìm tất cả conversations của 1 user (cả direct và group)
    @Query("SELECT DISTINCT c FROM Conversation c LEFT JOIN c.memberIds m WHERE " +
            "(c.type = 'direct' AND (c.user1 = :userId OR c.user2 = :userId)) OR " +
            "(c.type = 'group' AND m = :userId) " +
            "ORDER BY c.lastTime DESC")
    List<Conversation> findAllByUserId(@Param("userId") String userId);

    // 🆕 Tìm conversation direct giữa 2 user
    @Query("SELECT c FROM Conversation c WHERE c.type = 'direct' AND " +
            "((c.user1 = :user1 AND c.user2 = :user2) OR (c.user1 = :user2 AND c.user2 = :user1))")
    Optional<Conversation> findDirectConversation(@Param("user1") String user1, @Param("user2") String user2);

    // 🆕 Tìm tất cả group conversations của user
    @Query("SELECT c FROM Conversation c JOIN c.memberIds m WHERE m = :userId AND c.type = 'group' ORDER BY c.lastTime DESC")
    List<Conversation> findGroupsByUserId(@Param("userId") String userId);
}