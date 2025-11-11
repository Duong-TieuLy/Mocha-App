package com.userservice.models;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.userservice.enums.FriendshipStatus;
import com.userservice.models.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "friendships", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"sender_id", "receiver_id"}),
       indexes = {
           @Index(name = "idx_sender", columnList = "sender_id"),
           @Index(name = "idx_receiver", columnList = "receiver_id"),
           @Index(name = "idx_status", columnList = "status")
       })
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Friend {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Relationship với User entity
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false, foreignKey = @ForeignKey(name = "fk_friendship_sender"))
    @JsonBackReference("user-sent-requests")
    private User sender;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id", nullable = false, foreignKey = @ForeignKey(name = "fk_friendship_receiver"))
    @JsonBackReference("user-received-requests")
    private User receiver;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FriendshipStatus status;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // Helper methods
    public Long getSenderId() {
        return sender != null ? sender.getId() : null;
    }
    
    public Long getReceiverId() {
        return receiver != null ? receiver.getId() : null;
    }
}