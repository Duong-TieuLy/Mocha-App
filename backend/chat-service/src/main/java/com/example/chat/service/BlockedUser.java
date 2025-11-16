package com.example.chat.model;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "blocked_users",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "blocked_user_id"}))
public class BlockedUser {

    @Id
    private String id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "blocked_user_id", nullable = false)
    private String blockedUserId;

    @Column(name = "blocked_at")
    private Instant blockedAt;

    public BlockedUser() {}

    public BlockedUser(String userId, String blockedUserId, Instant blockedAt) {
        this.userId = userId;
        this.blockedUserId = blockedUserId;
        this.blockedAt = blockedAt;
    }

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (blockedAt == null) blockedAt = Instant.now();
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getBlockedUserId() {
        return blockedUserId;
    }

    public void setBlockedUserId(String blockedUserId) {
        this.blockedUserId = blockedUserId;
    }

    public Instant getBlockedAt() {
        return blockedAt;
    }

    public void setBlockedAt(Instant blockedAt) {
        this.blockedAt = blockedAt;
    }
}