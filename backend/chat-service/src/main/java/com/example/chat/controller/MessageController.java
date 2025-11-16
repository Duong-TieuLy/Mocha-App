package com.example.chat.controller;

import com.example.chat.model.Message;
import com.example.chat.service.MessageService;
import com.example.chat.service.MessageService.MessageResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    private final MessageService messageService;

    // Đường dẫn lưu ảnh (có thể config trong application.properties)
    private static final String UPLOAD_DIR = "uploads/images/";

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
        // Tạo thư mục uploads nếu chưa tồn tại
        try {
            Files.createDirectories(Paths.get(UPLOAD_DIR));
        } catch (IOException e) {
            System.err.println("Could not create upload directory: " + e.getMessage());
        }
    }

    // ✨ THÊM ENDPOINT NÀY ĐỂ XỬ LÝ UPLOAD IMAGE
    @PostMapping("/image")
    public ResponseEntity<?> uploadImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam("conversationId") String conversationId,
            @RequestParam("senderId") String senderId,
            @RequestHeader(value = "x-temp-id", required = false) String tempId
    ) {
        try {
            // Validate file
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "File is empty"
                ));
            }

            // Kiểm tra loại file
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "error", "File must be an image"
                ));
            }

            // Tạo tên file unique
            String originalFilename = file.getOriginalFilename();
            String extension = originalFilename != null && originalFilename.contains(".")
                    ? originalFilename.substring(originalFilename.lastIndexOf("."))
                    : ".jpg";
            String filename = UUID.randomUUID().toString() + extension;

            // Lưu file
            Path filePath = Paths.get(UPLOAD_DIR + filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Tạo URL để truy cập ảnh
            String imageUrl = "/uploads/images/" + filename;

            // Tạo message với type "image"
            Message message = new Message();
            message.setConversationId(conversationId);
            message.setSenderId(senderId);
            message.setContent(imageUrl); // URL của ảnh
            message.setType("image");

            // Lưu message vào database
            MessageResponse saved = messageService.save(message, tempId);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", saved.getMessage(),
                    "tempId", saved.getTempId(),
                    "imageUrl", imageUrl
            ));

        } catch (IOException e) {
            System.err.println("Error uploading image: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", "Failed to upload image: " + e.getMessage()
            ));
        } catch (Exception e) {
            System.err.println("Unexpected error: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    @PostMapping("/{messageId}/recall")
    public ResponseEntity<?> recallMessage(@PathVariable String messageId) {
        try {
            boolean recalled = messageService.recall(messageId);
            if (recalled) {
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", "Message recalled successfully"
                ));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "error", "Message not found"
                ));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    @PostMapping
    public ResponseEntity<?> sendMessage(
            @RequestBody Message incoming,
            @RequestHeader(value = "x-temp-id", required = false) String tempId
    ) {
        try {
            MessageResponse saved = messageService.save(incoming, tempId);
            return ResponseEntity.ok(Map.of(
                    "message", saved.getMessage(),
                    "tempId", saved.getTempId(),
                    "success", true
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("success", false, "error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    @GetMapping("/history/{conversationId}")
    public ResponseEntity<?> history(@PathVariable String conversationId) {
        try {
            List<Message> messages = messageService.getHistory(conversationId)
                    .stream()
                    .peek(msg -> {
                        if (msg.isRecalled()) {
                            msg.setContent("Tin nhắn đã được thu hồi");
                        }
                    })
                    .toList();

            return ResponseEntity.ok(messages);
        } catch (Exception e) {
            System.err.println("Error fetching history for: " + conversationId);
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "conversationId", conversationId
            ));
        }
    }

    @GetMapping("/{userId}")
    public ResponseEntity<?> messagesByUser(@PathVariable String userId) {
        try {
            List<Message> messages = messageService.getMessagesForUser(userId);
            return ResponseEntity.ok(messages);
        } catch (Exception e) {
            System.err.println("Error fetching messages for user: " + userId);
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    @GetMapping
    public ResponseEntity<List<Message>> getAllMessages() {
        return ResponseEntity.ok(messageService.getAllMessages());
    }

    @DeleteMapping("/{messageId}")
    public ResponseEntity<?> deleteMessage(@PathVariable String messageId) {
        try {
            boolean deleted = messageService.delete(messageId);
            if (deleted) {
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", "Message deleted successfully"
                ));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "error", "Message not found"
                ));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }
    // 🗑️ DELETE ALL MESSAGES IN A CONVERSATION
    @DeleteMapping("/conversation/{conversationId}")
    public ResponseEntity<?> deleteAllMessages(@PathVariable String conversationId) {
        try {
            boolean deleted = messageService.deleteAllByConversationId(conversationId);
            if (deleted) {
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", "All messages deleted successfully"
                ));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                        "success", false,
                        "error", "No messages found for this conversation"
                ));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }
}