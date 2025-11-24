package com.example.chat.service;

import com.example.chat.model.Conversation;
import com.example.chat.repository.ConversationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepository;

    @Autowired
    public ConversationService(ConversationRepository conversationRepository) {
        this.conversationRepository = conversationRepository;
    }

    // ✅ GIỮ NGUYÊN - Method cũ cho direct chat (backward compatible)
    @Transactional
    public Conversation getOrCreateDirectConversation(String user1, String user2) {
        return conversationRepository.findDirectConversation(user1, user2)
                .orElseGet(() -> {
                    String convId = "conv_" + UUID.randomUUID().toString();
                    Conversation newConv = new Conversation(convId, user1, user2);
                    return conversationRepository.save(newConv);
                });
    }

    // 🆕 TẠO GROUP CHAT
    @Transactional
    public Conversation createGroup(String name, List<String> memberIds, String createdBy, String avatar) {
        if (memberIds == null || memberIds.size() < 2) {
            throw new IllegalArgumentException("Group must have at least 2 members");
        }

        String groupId = "group_" + UUID.randomUUID().toString();

        Conversation group = new Conversation(groupId, name, memberIds, createdBy);
        group.setAvatar(avatar);
        group.setType("group");

        return conversationRepository.save(group);
    }

    // 🆕 LẤY TẤT CẢ CONVERSATIONS CỦA USER (cả direct và group)
    public List<Conversation> getAllConversationsByUserId(String userId) {
        return conversationRepository.findAllByUserId(userId);
    }

    // 📋 LẤY DANH SÁCH GROUP CỦA USER
    public List<Conversation> getGroupsByUserId(String userId) {
        return conversationRepository.findGroupsByUserId(userId);
    }

    // 📋 LẤY DANH SÁCH DIRECT CHAT CỦA USER (compatibility)
    public List<Conversation> getDirectConversationsByUserId(String userId) {
        return conversationRepository.findByUser1OrUser2OrderByLastTimeDesc(userId, userId);
    }

    // 🔍 LẤY 1 CONVERSATION THEO ID
    public Conversation getById(String conversationId) {
        return conversationRepository.findById(conversationId).orElse(null);
    }

    // ➕ THÊM THÀNH VIÊN VÀO GROUP
    @Transactional
    public Conversation addMembers(String conversationId, List<String> memberIds) {
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));

        if (!"group".equals(conversation.getType())) {
            throw new IllegalArgumentException("Can only add members to group conversations");
        }

        for (String memberId : memberIds) {
            conversation.addMember(memberId);
        }

        conversation.setLastTime(Instant.now());
        return conversationRepository.save(conversation);
    }

    // ➖ XÓA THÀNH VIÊN KHỎI GROUP
    @Transactional
    public Conversation removeMember(String conversationId, String memberId) {
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));

        if (!"group".equals(conversation.getType())) {
            throw new IllegalArgumentException("Can only remove members from group conversations");
        }

        conversation.removeMember(memberId);
        conversation.setLastTime(Instant.now());

        // Nếu group chỉ còn 1 người hoặc không có ai, xóa luôn
        if (conversation.getMemberIds().size() <= 1) {
            conversationRepository.delete(conversation);
            return null;
        }

        return conversationRepository.save(conversation);
    }

    // 🔄 CẬP NHẬT LAST MESSAGE
    @Transactional
    public void updateLastMessage(String conversationId, String lastMessage) {
        conversationRepository.findById(conversationId).ifPresent(conversation -> {
            conversation.setLastMessage(lastMessage);
            conversation.setLastTime(Instant.now());
            conversationRepository.save(conversation);
        });
    }

    // 🗑️ XÓA CONVERSATION
    @Transactional
    public boolean delete(String conversationId) {
        if (conversationRepository.existsById(conversationId)) {
            conversationRepository.deleteById(conversationId);
            return true;
        }
        return false;
    }

    // ✏️ CẬP NHẬT TÊN GROUP
    @Transactional
    public Conversation updateGroupName(String conversationId, String newName) {
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));

        if (!"group".equals(conversation.getType())) {
            throw new IllegalArgumentException("Can only update name for group conversations");
        }

        conversation.setName(newName);
        conversation.setLastTime(Instant.now());
        return conversationRepository.save(conversation);
    }

    // 🖼️ CẬP NHẬT AVATAR GROUP
    @Transactional
    public Conversation updateGroupAvatar(String conversationId, String avatarUrl) {
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new IllegalArgumentException("Conversation not found"));

        if (!"group".equals(conversation.getType())) {
            throw new IllegalArgumentException("Can only update avatar for group conversations");
        }

        conversation.setAvatar(avatarUrl);
        conversation.setLastTime(Instant.now());
        return conversationRepository.save(conversation);
    }
}