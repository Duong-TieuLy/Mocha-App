package com.example.chat.repository;

import com.example.chat.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, String> {

    // Lấy 100 tin nhắn gần nhất theo conversationId (DESC)
    List<Message> findTop100ByConversationIdOrderByCreatedAtDesc(String conversationId);

    // Lấy 100 tin nhắn theo conversationId theo thứ tự tăng dần (ASC)
    List<Message> findTop100ByConversationIdOrderByCreatedAtAsc(String conversationId);

    // Lấy 100 tin nhắn gần nhất theo user (gửi hoặc nhận) (DESC)
    @Query("SELECT m FROM Message m WHERE m.senderId = :userId OR m.receiverId = :userId ORDER BY m.createdAt DESC")
    List<Message> findTop100BySenderIdOrReceiverIdOrderByCreatedAtDesc(@Param("userId") String userId);
}