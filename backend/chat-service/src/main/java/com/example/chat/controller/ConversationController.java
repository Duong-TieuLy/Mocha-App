package com.example.chat.controller;

import com.example.chat.model.Conversation;
import com.example.chat.model.Message;
import com.example.chat.service.ConversationService;
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
    private final ConversationService conversationService;

    public ConversationController(MessageService messageService, ConversationService conversationService) {
        this.messageService = messageService;
        this.conversationService = conversationService;
    }

    /**
     * 🔥 PRIMARY ENDPOINT - Match với Flutter
     * GET /api/conversations/{firebaseUid}
     */
    @GetMapping("/{firebaseUid}")
    public ResponseEntity<?> getUserConversations(@PathVariable String firebaseUid) {
        try {
            System.out.println("🔍 Getting conversations for user: " + firebaseUid);

            // ✅ Lấy TẤT CẢ tin nhắn của user
            List<Message> allMessages = messageService.getMessagesForUser(firebaseUid);

            if (allMessages == null) {
                System.out.println("⚠️ messageService.getMessagesForUser returned null");
                return ResponseEntity.ok(Collections.emptyList());
            }

            if (allMessages.isEmpty()) {
                System.out.println("📭 No messages found for user: " + firebaseUid);
                return ResponseEntity.ok(Collections.emptyList());
            }

            // ✅ Group messages theo conversationId
            Map<String, List<Message>> groupedByConversation = allMessages.stream()
                    .filter(msg -> msg.getConversationId() != null)
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

                // Last message info
                Map<String, Object> lastMsgInfo = new HashMap<>();
                lastMsgInfo.put("id", lastMessage.getId());
                lastMsgInfo.put("senderId", lastMessage.getSenderId());

                // Handle recalled messages
                if (lastMessage.isRecalled()) {
                    lastMsgInfo.put("content", "Tin nhắn đã được thu hồi");
                } else {
                    lastMsgInfo.put("content", lastMessage.getContent() != null ? lastMessage.getContent() : "");
                }

                lastMsgInfo.put("type", lastMessage.getType() != null ? lastMessage.getType() : "text");
                lastMsgInfo.put("createdAt", lastMessage.getCreatedAt().toString());
                lastMsgInfo.put("timestamp", lastMessage.getCreatedAt().toString());
                lastMsgInfo.put("recalled", lastMessage.isRecalled());

                conversation.put("lastMessage", lastMsgInfo);

                // Calculate unread count
                long unreadCount = messages.stream()
                        .filter(msg -> {
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

            // Sort by last message time (newest first)
            conversations.sort((a, b) -> {
                @SuppressWarnings("unchecked")
                Map<String, Object> lastMsgA = (Map<String, Object>) a.get("lastMessage");
                @SuppressWarnings("unchecked")
                Map<String, Object> lastMsgB = (Map<String, Object>) b.get("lastMessage");

                String timeA = lastMsgA.get("createdAt").toString();
                String timeB = lastMsgB.get("createdAt").toString();

                return timeB.compareTo(timeA);
            });

            System.out.println("✅ Found " + conversations.size() + " conversations for user: " + firebaseUid);

            return ResponseEntity.ok(conversations);

        } catch (Exception e) {
            System.err.println("❌ Error fetching conversations for user: " + firebaseUid);
            System.err.println("❌ Error type: " + e.getClass().getName());
            System.err.println("❌ Error message: " + e.getMessage());
            e.printStackTrace();

            // Return empty list instead of error to prevent app crash
            return ResponseEntity.ok(Collections.emptyList());
        }
    }

    /**
     * 🔥 POST /api/conversations/create
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

            List<String> sorted = Arrays.asList(user1, user2);
            Collections.sort(sorted);
            String conversationId = sorted.get(0) + "-" + sorted.get(1) + "-chat";

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

            List<Message> messages = messageService.getHistory(conversationId);
            int markedCount = 0;

            for (Message message : messages) {
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
     * 🔥 GET /api/conversations/check/{conversationId}/exists
     */
    @GetMapping("/check/{conversationId}/exists")
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

    // ============================================
    // 🆕 GROUP CHAT ENDPOINTS
    // ============================================

    /**
     * 🆕 POST /api/conversations/group
     */
    @PostMapping("/group")
    public ResponseEntity<?> createGroup(@RequestBody Map<String, Object> request) {
        try {
            String name = (String) request.get("name");
            @SuppressWarnings("unchecked")
            List<String> memberIds = (List<String>) request.get("memberIds");
            String createdBy = (String) request.get("createdBy");
            String avatar = (String) request.get("avatar");

            if (name == null || name.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "Group name is required"
                ));
            }

            if (memberIds == null || memberIds.size() < 2) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "At least 2 members required for a group"
                ));
            }

            Conversation group = conversationService.createGroup(name, memberIds, createdBy, avatar);

            System.out.println("✅ Created group: " + group.getId() + " with " + memberIds.size() + " members");

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "conversation", group,
                    "conversationId", group.getId()
            ));
        } catch (Exception e) {
            System.err.println("❌ Error creating group: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🆕 GET /api/conversations/groups/{userId}
     */
    @GetMapping("/groups/{userId}")
    public ResponseEntity<?> getUserGroups(@PathVariable String userId) {
        try {
            List<Conversation> groups = conversationService.getGroupsByUserId(userId);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "groups", groups
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🆕 GET /api/conversations/details/{conversationId}
     */
    @GetMapping("/details/{conversationId}")
    public ResponseEntity<?> getConversationDetails(@PathVariable String conversationId) {
        try {
            Conversation conversation = conversationService.getById(conversationId);
            if (conversation == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "error", "Conversation not found"
                ));
            }
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "conversation", conversation
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🆕 POST /api/conversations/{conversationId}/members
     */
    @PostMapping("/{conversationId}/members")
    public ResponseEntity<?> addMembers(
            @PathVariable String conversationId,
            @RequestBody Map<String, Object> request
    ) {
        try {
            @SuppressWarnings("unchecked")
            List<String> memberIds = (List<String>) request.get("memberIds");

            if (memberIds == null || memberIds.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "Member IDs required"
                ));
            }

            Conversation updated = conversationService.addMembers(conversationId, memberIds);

            System.out.println("✅ Added " + memberIds.size() + " members to group: " + conversationId);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "conversation", updated
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🆕 DELETE /api/conversations/{conversationId}/members/{memberId}
     */
    @DeleteMapping("/{conversationId}/members/{memberId}")
    public ResponseEntity<?> removeMember(
            @PathVariable String conversationId,
            @PathVariable String memberId
    ) {
        try {
            Conversation updated = conversationService.removeMember(conversationId, memberId);

            if (updated == null) {
                System.out.println("⚠️ Group deleted (less than 2 members)");
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", "Group deleted (less than 2 members remaining)",
                        "deleted", true
                ));
            }

            System.out.println("✅ Removed member " + memberId + " from group: " + conversationId);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "conversation", updated
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🆕 PUT /api/conversations/{conversationId}/name
     */
    @PutMapping("/{conversationId}/name")
    public ResponseEntity<?> updateGroupName(
            @PathVariable String conversationId,
            @RequestBody Map<String, String> request
    ) {
        try {
            String newName = request.get("name");

            if (newName == null || newName.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "Name is required"
                ));
            }

            Conversation updated = conversationService.updateGroupName(conversationId, newName);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "conversation", updated
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🗑️ DELETE /api/conversations/{conversationId}
     * Xóa conversation (group hoặc direct chat)
     */
    @DeleteMapping("/{conversationId}")
    public ResponseEntity<?> deleteConversation(@PathVariable String conversationId) {
        try {
            System.out.println("🗑️ Deleting conversation: " + conversationId);

            // Xóa group từ ConversationService (nếu là group)
            if (conversationId.startsWith("group_")) {
                boolean deleted = conversationService.delete(conversationId);
                if (deleted) {
                    System.out.println("✅ Deleted group from database: " + conversationId);
                } else {
                    System.out.println("⚠️ Group not found in database: " + conversationId);
                }
            }

            System.out.println("✅ Conversation deleted: " + conversationId);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Conversation deleted successfully",
                    "conversationId", conversationId
            ));
        } catch (Exception e) {
            System.err.println("❌ Error deleting conversation: " + conversationId);
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * 🗑️ DELETE /api/conversations/group/{groupId}
     * Alternative endpoint cho group deletion
     */
    @DeleteMapping("/group/{groupId}")
    public ResponseEntity<?> deleteGroup(@PathVariable String groupId) {
        return deleteConversation(groupId);
    }

    /**
     * Helper: Extract participants từ conversationId
     */
    private List<String> extractParticipants(String conversationId) {
        List<String> participants = new ArrayList<>();
        if (conversationId == null) return participants;

        String[] parts = conversationId.split("-");
        if (parts.length >= 2) {
            participants.add(parts[0]);
            participants.add(parts[1]);
        }
        return participants;
    }
}