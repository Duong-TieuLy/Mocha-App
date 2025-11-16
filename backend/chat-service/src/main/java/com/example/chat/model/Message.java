package com.example.chat.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@JsonInclude(JsonInclude.Include.NON_NULL)
@Entity
@Table(name = "messages", indexes = {
        @Index(columnList = "conversation_id, created_at")
})
public class Message {

    @Id
    private String id;

    @Column(name = "conversation_id", nullable = false)
    private String conversationId;

    @Column(name = "sender_id", nullable = false)
    private String senderId;

    @Column(name = "receiver_id")
    private String receiverId;

    @Column(columnDefinition = "text")
    private String content;

    @Column(name = "type")
    private String type;

    @Column(name = "attachment_url")
    private String attachmentUrl;

    @Column(name = "status")
    private String status;

    // getter
    public String getStatus() { return status; }

    // setter
    public void setStatus(String status) { this.status = status; }

    @Column(name = "created_at")
    private Instant createdAt;

    // ✅ ĐỔI SANG Boolean (wrapper class)
    @Column(name = "recalled")
    private Boolean recalled;

    @Column(name = "recalled_at")
    private Instant recalledAt;

    public Message() {}

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        // ✅ Set default cho recalled nếu null
        if (recalled == null) recalled = false;
    }

    // GETTER/SETTER
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }

    public String getSenderId() { return senderId; }
    public void setSenderId(String senderId) { this.senderId = senderId; }

    public String getReceiverId() { return receiverId; }
    public void setReceiverId(String receiverId) { this.receiverId = receiverId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getAttachmentUrl() { return attachmentUrl; }
    public void setAttachmentUrl(String attachmentUrl) { this.attachmentUrl = attachmentUrl; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    // ✅ Getter trả về Boolean
    public Boolean getRecalled() {
        return recalled;
    }

    public void setRecalled(Boolean recalled) {
        this.recalled = recalled;
    }

    // ✅ Helper method để check (tránh NullPointerException)
    public boolean isRecalled() {
        return Boolean.TRUE.equals(recalled);
    }

    public Instant getRecalledAt() {
        return recalledAt;
    }

    public void setRecalledAt(Instant recalledAt) {
        this.recalledAt = recalledAt;
    }
}