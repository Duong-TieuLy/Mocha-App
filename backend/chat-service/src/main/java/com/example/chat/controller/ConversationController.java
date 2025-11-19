package com.example.chat.controller;

import com.example.chat.model.Message;
import com.example.chat.service.MessageService;
import org.springframework.http.HttpStatus;
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

    /**
     * 🔥 GET /api/conversations/user/{firebaseUid}
     * Lấy danh sách conversations của user (match với Flutter)
     */
    @GetMapping("/user/{firebaseUid}")
    public ResponseEntity<?> getUserConversations(@PathVariable String firebaseUid) {
        try {
            System.out.println("🔍 Getting conversations for user: " + firebaseUid);

            // ✅ Lấy TẤT CẢ tin nhắn mà user này tham gia (gửi HOẶC nhận)
            List<Message> allMessages = messageService.getMessagesForUser(firebaseUid);

            if (allMessages.isEmpty()) {
                System.out.println("📭 No messages found for user: " + firebaseUid);
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
                List<String> participants = extractParticipants(conversationId);

                // ✅ Build conversation object
                Map<String, Object> conversation = new HashMap<>();
                conversation.put("conversationId", conversationId);
                conversation.put("participants", participants);

                // Last message info (format phù hợp với Flutter)
                Map<String, Object> lastMsgInfo = new HashMap<>();
                lastMsgInfo.put("id", lastMessage.getId());
                lastMsgInfo.put("senderId", lastMessage.getSenderId());

                // ✅ Handle recalled messages
                if (lastMessage.isRecalled()) {
                    lastMsgInfo.put("content", "Tin nhắn đã được thu hồi");
                } else {
                    lastMsgInfo.put("content", lastMessage.getContent());
                }

                lastMsgInfo.put("type", lastMessage.getType() != null ? lastMessage.getType() : "text");
                lastMsgInfo.put("createdAt", lastMessage.getCreatedAt().toString());
                lastMsgInfo.put("timestamp", lastMessage.getCreatedAt().toString()); // Flutter dùng cả 2
                lastMsgInfo.put("recalled", lastMessage.isRecalled());

                conversation.put("lastMessage", lastMsgInfo);

                // ✅ Calculate unread count
                long unreadCount = messages.stream()
                        .filter(msg -> {
                            // Message mà user là receiver và chưa đọc
                            if (firebaseUid.equals(msg.getReceiverId())) {
                                String status = msg.getStatus();
                                return status == null || !status.equals("read");
                            }
                            return false;
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

            System.out.println("✅ Found " + conversations.size() + " conversations for user: " + firebaseUid);

            return ResponseEntity.ok(conversations);

        } catch (Exception e) {
            System.err.println("❌ Error fetching conversations for user: " + firebaseUid);
            e.printStackTrace();
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    /**
     * 🔥 POST /api/conversations/create
     * Tạo conversationId từ 2 firebaseUid
     */
    @PostMapping("/create")
    public ResponseEntity<?> createConversation(@RequestBody Map<String, String> request) {
        try {
            String user1 = request.get("user1");
            String user2 = request.get("user2");

            if (user1 == null || user2 == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "Both user1 and user2 are required"
                ));
            }

            // Create conversationId (sorted để đảm bảo unique)
            List<String> sorted = Arrays.asList(user1, user2);
            Collections.sort(sorted);
            String conversationId = sorted.get(0) + "-" + sorted.get(1) + "-chat";

            // Check if conversation exists (has messages)
            List<Message> existingMessages = messageService.getHistory(conversationId);
            boolean exists = !existingMessages.isEmpty();

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "conversationId", conversationId,
                    "exists", exists
            ));
        } catch (Exception e) {
            System.err.println("❌ Error creating conversation");
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🔥 PUT /api/conversations/{conversationId}/read
     * Đánh dấu tất cả messages trong conversation là đã đọc
     */
    @PutMapping("/{conversationId}/read")
    public ResponseEntity<?> markAsRead(
            @PathVariable String conversationId,
            @RequestBody Map<String, String> request
    ) {
        try {
            String userId = request.get("userId");

            if (userId == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "userId is required"
                ));
            }

            // Get all messages in conversation
            List<Message> messages = messageService.getHistory(conversationId);
            int markedCount = 0;

            for (Message message : messages) {
                // Chỉ update messages mà user là receiver và chưa đọc
                if (userId.equals(message.getReceiverId()) && !"read".equals(message.getStatus())) {
                    message.setStatus("read");
                    messageService.save(message, null);
                    markedCount++;
                }
            }

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "markedCount", markedCount,
                    "message", markedCount + " messages marked as read"
            ));
        } catch (Exception e) {
            System.err.println("❌ Error marking conversation as read: " + conversationId);
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🔥 GET /api/conversations/unread-count/{firebaseUid}
     * Lấy tổng số messages chưa đọc của user
     */
    @GetMapping("/unread-count/{firebaseUid}")
    public ResponseEntity<?> getUnreadCount(@PathVariable String firebaseUid) {
        try {
            List<Message> userMessages = messageService.getMessagesForUser(firebaseUid);

            long unreadCount = userMessages.stream()
                    .filter(m -> firebaseUid.equals(m.getReceiverId()))
                    .filter(m -> !"read".equals(m.getStatus()))
                    .count();

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "unreadCount", unreadCount
            ));
        } catch (Exception e) {
            System.err.println("❌ Error getting unread count for user: " + firebaseUid);
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🔥 GET /api/conversations/{conversationId}/exists
     * Kiểm tra conversation có tồn tại không
     */
    @GetMapping("/{conversationId}/exists")
    public ResponseEntity<?> checkConversationExists(@PathVariable String conversationId) {
        try {
            List<Message> messages = messageService.getHistory(conversationId);
            boolean exists = !messages.isEmpty();

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "exists", exists,
                    "conversationId", conversationId
            ));
        } catch (Exception e) {
            System.err.println("❌ Error checking conversation: " + conversationId);
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * Extract participants from conversationId
     * Format: "user1-user2-chat"
     */
    private List<String> extractParticipants(String conversationId) {
        List<String> participants = new ArrayList<>();

        String[] parts = conversationId.split("-");

        if (parts.length >= 2) {
            participants.add(parts[0]);
            participants.add(parts[1]);
        }

        return participants;
    }

    /**
     * 🔥 Backward compatibility: Support old endpoint
     * GET /api/conversations/{userId} → redirect to /api/conversations/user/{userId}
     */
    @GetMapping("/{userId}")
    public ResponseEntity<?> getUserConversationsLegacy(@PathVariable String userId) {
        return getUserConversations(userId);
    }
}