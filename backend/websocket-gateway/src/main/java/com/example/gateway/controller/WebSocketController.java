package com.example.gateway.controller;

import com.example.chat.model.Message;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
public class WebsocketController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    // client sends to /app/chat.send
    @MessageMapping("/chat.send")
    public void sendMessage(@Payload Message message, @Header("simpSessionId") String sessionId) {
        // In real: persist via Chat service (call REST endpoint) then broadcast
        // For demo: broadcast directly
        messagingTemplate.convertAndSend("/topic/conversation." + message.getConversationId(), message);
    }
}