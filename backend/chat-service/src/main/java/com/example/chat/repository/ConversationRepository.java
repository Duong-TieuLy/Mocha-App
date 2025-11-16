package com.example.chat.repository;

import com.example.chat.model.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, String> {

    List<Conversation> findByUser1OrUser2OrderByLastTimeDesc(String user1, String user2);

}
