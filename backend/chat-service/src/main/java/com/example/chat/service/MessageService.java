package com.example.chat.service;

import com.example.chat.model.Message;
import com.example.chat.repository.MessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.Nullable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class MessageService {

    private static final Logger logger = LoggerFactory.getLogger(MessageService.class);
    private static final String TOPIC_MESSAGE_CREATED = "message.created";

    private final MessageRepository repo;
    private final @Nullable KafkaTemplate<String, Message> kafkaTemplate;
    private final @Nullable SimpMessagingTemplate messagingTemplate;

    public MessageService(MessageRepository repo,
                          @Nullable KafkaTemplate<String, Message> kafkaTemplate,
                          @Nullable SimpMessagingTemplate messagingTemplate) {
        this.repo = repo;
        this.kafkaTemplate = kafkaTemplate;
        this.messagingTemplate = messagingTemplate;
    }

    // Wrapper để trả về message + tempId
    public static class MessageResponse {
        private final Message message;
        private final String tempId;

        public MessageResponse(Message message, String tempId) {
            this.message = message;
            this.tempId = tempId;
        }

        public Message getMessage() { return message; }
        public String getTempId() { return tempId; }
    }

    public MessageResponse save(Message m, String tempId) {
        if (m.getConversationId() == null || m.getConversationId().isBlank()) {
            throw new IllegalArgumentException("conversationId không được null hoặc trống");
        }
        if (m.getSenderId() == null || m.getSenderId().isBlank()) {
            throw new IllegalArgumentException("senderId không được null hoặc trống");
        }

        Message saved = repo.save(m);

        // WebSocket
        if (messagingTemplate != null) {
            try {
                if (saved.getReceiverId() != null) {
                    messagingTemplate.convertAndSendToUser(
                            saved.getReceiverId(),
                            "/queue/messages",
                            saved
                    );
                } else {
                    messagingTemplate.convertAndSend(
                            "/topic/messages." + saved.getConversationId(),
                            saved
                    );
                }
            } catch (Exception e) {
                logger.error("WebSocket send failed: {}", e.toString(), e);
            }
        }

        // Kafka
        if (kafkaTemplate != null) {
            try {
                CompletableFuture<SendResult<String, Message>> future =
                        kafkaTemplate.send(TOPIC_MESSAGE_CREATED, saved.getConversationId(), saved);
                future.whenComplete((result, ex) -> {
                    if (ex != null) logger.error("Kafka send failed: {}", ex.toString());
                });
            } catch (Exception e) {
                logger.error("Kafka send exception: {}", e.toString(), e);
            }
        }

        return new MessageResponse(saved, tempId != null ? tempId : saved.getId());
    }

    // Lấy tin nhắn theo conversationId (ASC theo thời gian)
    public List<Message> getHistory(String conversationId) {
        return repo.findTop100ByConversationIdOrderByCreatedAtAsc(conversationId);
    }

    // Lấy tất cả tin nhắn của user (gửi hoặc nhận)
    public List<Message> getMessagesForUser(String userId) {
        return repo.findTop100BySenderIdOrReceiverIdOrderByCreatedAtDesc(userId);
    }

    public List<Message> getAllMessages() {
        return repo.findAll();
    }
}
