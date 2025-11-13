package com.userservice.models;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "users")
@Data
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String firebaseUid;

    @Column(nullable = false, unique = true)
    private String email; // ✅ thêm email

    private String fullName;

    @Column(unique = true)
    private String username;

    @Column(length = 500)
    private String bio;

    private String interests;
    private String photoUrl;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    private boolean banned = false;

    private String banReason;

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private UserStatus status;

    // 🔹 Người này đang theo dõi ai
    @ManyToMany
    @JoinTable(
            name = "user_following",
            joinColumns = @JoinColumn(name = "follower_id"),
            inverseJoinColumns = @JoinColumn(name = "following_id")
    )
    private Set<User> following = new HashSet<>();

    // 🔹 Ai đang theo dõi người này
    @ManyToMany(mappedBy = "following")
    private Set<User> followers = new HashSet<>();

    // Quan hệ với Friendship - Lời mời đã gửi
    @OneToMany(mappedBy = "user1", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference("user-sent-requests")
    private List<Friend> sentFriendRequests = new ArrayList<>();

    // Quan hệ với Friendship - Lời mời đã nhận
    @OneToMany(mappedBy = "user2", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference("user-received-requests")
    private List<Friend> receivedFriendRequests = new ArrayList<>();
}
