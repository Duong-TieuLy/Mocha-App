package com.example.chat.model;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
public class Conversation {

    @Id
    private String id;

    // 🆕 Type: "direct" hoặc "group"
    @Column(nullable = false)
    private String type = "direct"; // Default là direct chat

    // 🆕 Tên group (chỉ dùng cho group chat)
    @Column(length = 255)
    private String name;

    // 🆕 Avatar group (optional)
    @Column(length = 500)
    private String avatar;

    // ⚠️ GIỮ NGUYÊN để tương thích với chat 1-1 cũ
    private String user1;
    private String user2;

    // 🆕 Danh sách thành viên (dùng cho group chat)
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "conversation_members",
            joinColumns = @JoinColumn(name = "conversation_id"))
    @Column(name = "member_id")
    private List<String> memberIds = new ArrayList<>();

    // 🆕 Người tạo group
    private String createdBy;

    private String lastMessage;
    private Instant lastTime;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    // Constructors
    public Conversation() {
        this.createdAt = Instant.now();
        this.lastTime = Instant.now();
    }

    // Constructor cho chat 1-1 (giữ nguyên để tương thích)
    public Conversation(String id, String user1, String user2) {
        this();
        this.id = id;
        this.user1 = user1;
        this.user2 = user2;
        this.type = "direct";
        // Thêm vào memberIds để dễ query
        this.memberIds.add(user1);
        this.memberIds.add(user2);
    }

    // 🆕 Constructor cho group chat
    public Conversation(String id, String name, List<String> memberIds, String createdBy) {
        this();
        this.id = id;
        this.name = name;
        this.type = "group";
        this.memberIds = new ArrayList<>(memberIds);
        this.createdBy = createdBy;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar = avatar;
    }

    public String getUser1() {
        return user1;
    }

    public void setUser1(String user1) {
        this.user1 = user1;
    }

    public String getUser2() {
        return user2;
    }

    public void setUser2(String user2) {
        this.user2 = user2;
    }

    public List<String> getMemberIds() {
        return memberIds;
    }

    public void setMemberIds(List<String> memberIds) {
        this.memberIds = memberIds;
    }

    public String getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }

    public String getLastMessage() {
        return lastMessage;
    }

    public void setLastMessage(String lastMessage) {
        this.lastMessage = lastMessage;
    }

    public Instant getLastTime() {
        return lastTime;
    }

    public void setLastTime(Instant lastTime) {
        this.lastTime = lastTime;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    // 🔧 Helper method: Kiểm tra user có trong conversation không
    public boolean hasMember(String userId) {
        if ("direct".equals(type)) {
            return userId.equals(user1) || userId.equals(user2);
        } else {
            return memberIds.contains(userId);
        }
    }

    // 🔧 Helper method: Thêm member vào group
    public void addMember(String userId) {
        if ("group".equals(type) && !memberIds.contains(userId)) {
            memberIds.add(userId);
        }
    }

    // 🔧 Helper method: Xóa member khỏi group
    public void removeMember(String userId) {
        if ("group".equals(type)) {
            memberIds.remove(userId);
        }
    }
}