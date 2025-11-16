package com.example.chat.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import java.time.Instant;

@Entity
public class Conversation {

    @Id
    private String id;

    private String user1;
    private String user2;

    private String lastMessage;
    private Instant lastTime;

    public Conversation() {}

    public Conversation(String id, String user1, String user2) {
        this.id = id;
        this.user1 = user1;
        this.user2 = user2;
        this.lastTime = Instant.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUser1() { return user1; }
    public void setUser1(String user1) { this.user1 = user1; }

    public String getUser2() { return user2; }
    public void setUser2(String user2) { this.user2 = user2; }

    public String getLastMessage() { return lastMessage; }
    public void setLastMessage(String lastMessage) { this.lastMessage = lastMessage; }

    public Instant getLastTime() { return lastTime; }
    public void setLastTime(Instant lastTime) { this.lastTime = lastTime; }
}
