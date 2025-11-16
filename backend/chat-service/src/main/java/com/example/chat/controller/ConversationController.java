package com.example.chat.controller;

import com.example.chat.model.Message;
import com.example.chat.service.MessageService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/conversations")
public class ConversationController {

    private final MessageService messageService;

    public ConversationController(MessageService messageService) {
        this.messageService = messageService;
    }

    @GetMapping("/{userId}")
    public ResponseEntity<?> getUserConversations(@PathVariable String userId) {
        try {
            // ✅ Lấy TẤT CẢ tin nhắn mà user này tham gia (gửi HOẶC nhận)
            List<Message> allMessages = messageService.getMessagesForUser(userId);

            if (allMessages.isEmpty()) {
                // ✅ Trả về empty array thay vì 404
                return ResponseEntity.ok(Collections.emptyList());
            }

            // ✅ Group messages theo conversationId
            Map<String, List<Message>> groupedByConversation = allMessages.stream()
                    .collect(Collectors.groupingBy(Message::getConversationId));

            // ✅ Build conversation list
            List<Map<String, Object>> conversations = new ArrayList<>();

            for (Map.Entry<String, List<Message>> entry : groupedByConversation.entrySet()) {
                String conversationId = entry.getKey();
                List<Message> messages = entry.getValue();

                // Get last message (newest)
                Message lastMessage = messages.stream()
                        .max(Comparator.comparing(Message::getCreatedAt))
                        .orElse(null);

                if (lastMessage == null) continue;

                // ✅ Extract participants từ conversationId
                // Format: "user1-user2-chat" hoặc "bella-tommy-chat"
                List<String> participants = extractParticipants(conversationId, userId);

                // ✅ Build conversation object
                Map<String, Object> conversation = new HashMap<>();
                conversation.put("conversationId", conversationId);
                conversation.put("participants", participants);

                // Last message info
                Map<String, Object> lastMsgInfo = new HashMap<>();
                lastMsgInfo.put("id", lastMessage.getId());
                lastMsgInfo.put("senderId", lastMessage.getSenderId());
                lastMsgInfo.put("content", lastMessage.isRecalled()
                        ? "Tin nhắn đã được thu hồi"
                        : lastMessage.getContent());
                lastMsgInfo.put("type", lastMessage.getType());
                lastMsgInfo.put("createdAt", lastMessage.getCreatedAt());
                lastMsgInfo.put("recalled", lastMessage.isRecalled());

                conversation.put("lastMessage", lastMsgInfo);

                // ✅ Calculate unread count (messages where receiverId = userId and status != read)
                long unreadCount = messages.stream()
                        .filter(msg -> {
                            // Nếu message có receiverId và = userId và chưa đọc
                            String receiverId = msg.getReceiverId();
                            if (receiverId != null && receiverId.equals(userId)) {
                                String status = msg.getStatus();
                                return status == null || !status.equals("read");
                            }
                            // Nếu không có receiverId riêng, check senderId
                            // Message không phải của mình = chưa đọc
                            return !msg.getSenderId().equals(userId);
                        })
                        .count();

                conversation.put("unreadCount", (int) unreadCount);

                conversations.add(conversation);
            }

            // ✅ Sort by last message time (newest first)
            conversations.sort((a, b) -> {
                @SuppressWarnings("unchecked")
                Map<String, Object> lastMsgA = (Map<String, Object>) a.get("lastMessage");
                @SuppressWarnings("unchecked")
                Map<String, Object> lastMsgB = (Map<String, Object>) b.get("lastMessage");

                String timeA = lastMsgA.get("createdAt").toString();
                String timeB = lastMsgB.get("createdAt").toString();

                return timeB.compareTo(timeA); // Descending
            });

            System.out.println("✅ Found " + conversations.size() + " conversations for user: " + userId);

            return ResponseEntity.ok(conversations);

        } catch (Exception e) {
            System.err.println("❌ Error fetching conversations for user: " + userId);
            e.printStackTrace();
            // ✅ Return empty array on error instead of 500
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    /**
     * Extract participants from conversationId
     * Format: "user1-user2-chat" or "bella-tommy-chat"
     */
    private List<String> extractParticipants(String conversationId, String currentUserId) {
        List<String> participants = new ArrayList<>();

        // Add current user first
        participants.add(currentUserId);

        // Parse conversationId to find other participant
        String[] parts = conversationId.split("-");

        if (parts.length >= 2) {
            String user1 = parts[0];
            String user2 = parts[1];

            // Add the other user (not current user)
            if (!user1.equals(currentUserId)) {
                participants.add(user1);
            } else if (!user2.equals(currentUserId)) {
                participants.add(user2);
            }
        }

        return participants;
    }
}