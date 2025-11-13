
package com.userservice.models;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "friendships", 
       uniqueConstraints = {
           @UniqueConstraint(columnNames = {"user_id_1", "user_id_2"})
       },
       indexes = {
           @Index(name = "idx_user1", columnList = "user_id_1"),
           @Index(name = "idx_user2", columnList = "user_id_2")
       })
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Friend {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Luôn lưu user có ID nhỏ hơn vào user1
     * để tránh duplicate (A-B và B-A)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id_1", nullable = false, 
                foreignKey = @ForeignKey(name = "fk_friendship_user1"))
    @JsonBackReference
    private User user1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id_2", nullable = false,
                foreignKey = @ForeignKey(name = "fk_friendship_user2"))
    @JsonBackReference
    private User user2;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Helper methods
    public boolean involves(Long userId) {
        return (user1 != null && user1.getId().equals(userId)) ||
               (user2 != null && user2.getId().equals(userId));
    }

    public User getOtherUser(Long userId) {
        if (user1 != null && user1.getId().equals(userId)) {
            return user2;
        }
        if (user2 != null && user2.getId().equals(userId)) {
            return user1;
        }
        return null;
    }
}