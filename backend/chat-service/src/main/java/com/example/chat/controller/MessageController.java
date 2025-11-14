package com.example.chat.controller;

import com.example.chat.model.Message;
import com.example.chat.service.MessageService;
import com.example.chat.service.MessageService.MessageResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
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
    public ResponseEntity<List<Message>> history(@PathVariable String conversationId) {
        return ResponseEntity.ok(messageService.getHistory(conversationId));
    }

    @GetMapping("/{userId}")
    public ResponseEntity<List<Message>> messagesByUser(@PathVariable String userId) {
        return ResponseEntity.ok(messageService.getMessagesForUser(userId));
    }

    @GetMapping
    public ResponseEntity<List<Message>> getAllMessages() {
        return ResponseEntity.ok(messageService.getAllMessages());
    }
}