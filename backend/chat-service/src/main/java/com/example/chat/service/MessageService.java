package com.example.chat.service;

import com.example.chat.model.Conversation;
import com.example.chat.model.Message;
import com.example.chat.repository.MessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.lang.Nullable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
public class MessageService {

    private static final Logger logger = LoggerFactory.getLogger(MessageService.class);
    private static final String TOPIC_MESSAGE_CREATED = "message.created";

    private final MessageRepository repo;

    @Autowired(required = false)
    private ConversationService conversationService;

    @Nullable
    private final KafkaTemplate<String, Message> kafkaTemplate;

    @Nullable
    private final SimpMessagingTemplate messagingTemplate;

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

        // WebSocket logic (giữ nguyên)
        if (messagingTemplate != null) {
            try {
                if (conversationService != null) {
                    Conversation conversation = conversationService.getById(saved.getConversationId());
                    if (conversation != null && "group".equals(conversation.getType())) {
                        logger.info("📢 Broadcasting message to {} members in group {}",
                                conversation.getMemberIds().size(), conversation.getId());

                        for (String memberId : conversation.getMemberIds()) {
                            try {
                                messagingTemplate.convertAndSendToUser(
                                        memberId,
                                        "/queue/messages",
                                        saved
                                );
                            } catch (Exception e) {
                                logger.error("Failed to send to member {}: {}", memberId, e.getMessage());
                            }
                        }

                        String displayMessage = "image".equals(saved.getType()) ? "📷 Ảnh" : saved.getContent();
                        conversationService.updateLastMessage(conversation.getId(), displayMessage);

                    } else {
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
                    }
                } else {
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
                }
            } catch (Exception e) {
                logger.error("WebSocket send failed: {}", e.toString(), e);
            }
        }

        // Kafka logic (giữ nguyên)
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

    public List<Message> getHistory(String conversationId) {
        return repo.findTop100ByConversationIdOrderByCreatedAtAsc(conversationId);
    }

    public List<Message> getMessagesForUser(String userId) {
        return repo.findTop100BySenderIdOrReceiverIdOrderByCreatedAtDesc(userId);
    }

    public List<Message> getAllMessages() {
        return repo.findAll();
    }

    public boolean recall(String messageId) {
        return repo.findById(messageId).map(msg -> {
            msg.setRecalled(true);
            msg.setRecalledAt(Instant.now());
            repo.save(msg);

            if (messagingTemplate != null) {
                try {
                    messagingTemplate.convertAndSend("/topic/message.recalled", msg);
                } catch (Exception e) {
                    logger.error("WebSocket recall notify failed: {}", e.toString(), e);
                }
            }
            return true;
        }).orElse(false);
    }

    public boolean delete(String messageId) {
        if (!repo.existsById(messageId)) return false;
        try {
            repo.deleteById(messageId);

            if (messagingTemplate != null) {
                try {
                    messagingTemplate.convertAndSend("/topic/message.deleted", messageId);
                } catch (Exception e) {
                    logger.error("WebSocket delete notify failed: {}", e.toString());
                }
            }
            return true;
        } catch (Exception e) {
            logger.error("Delete failed: {}", e.toString());
            return false;
        }
    }

    // ✅ Fix: dùng 'repo' thay vì 'messageRepository'

    @Transactional
    public boolean deleteMessage(String messageId) {
        try {
            repo.deleteById(messageId);
            return true;
        } catch (Exception e) {
            System.err.println("❌ Error deleting message: " + messageId);
            e.printStackTrace();
            return false;
        }
    }

    @Transactional
    public int deleteMessagesByConversationId(String conversationId) {
        try {
            List<Message> messages = getHistory(conversationId);
            int count = messages.size();
            for (Message message : messages) {
                repo.deleteById(message.getId());
            }
            System.out.println("✅ Deleted " + count + " messages from conversation: " + conversationId);
            return count;
        } catch (Exception e) {
            System.err.println("❌ Error deleting messages for conversation: " + conversationId);
            e.printStackTrace();
            return 0;
        }
    }

    public boolean deleteAllByConversationId(String conversationId) {
        List<Message> messages = repo.findByConversationId(conversationId);
        if (messages.isEmpty()) return false;
        repo.deleteAll(messages);

        if (messagingTemplate != null) {
            try {
                messagingTemplate.convertAndSend("/topic/messages.deleted." + conversationId, messages);
            } catch (Exception e) {
                logger.error("WebSocket deleteAll notify failed: {}", e.toString());
            }
        }
        return true;
    }
}
