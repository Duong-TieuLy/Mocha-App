package com.example.chat.repository;

import com.example.chat.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, String> {

    List<Message> findTop100ByConversationIdOrderByCreatedAtDesc(String conversationId);

    List<Message> findTop100ByConversationIdOrderByCreatedAtAsc(String conversationId);

    @Query("SELECT m FROM Message m WHERE m.senderId = :userId OR m.receiverId = :userId ORDER BY m.createdAt DESC")
    List<Message> findTop100BySenderIdOrReceiverIdOrderByCreatedAtDesc(@Param("userId") String userId);

    // ✅ Thêm method này để deleteAllByConversationId hoạt động
    List<Message> findByConversationId(String conversationId);
}
