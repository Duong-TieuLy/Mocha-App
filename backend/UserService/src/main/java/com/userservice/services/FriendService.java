package com.userservice.services;

import com.userservice.dtos.FriendshipResponseDTO;
import com.userservice.dtos.UserDTO;
import com.userservice.enums.FriendshipStatus;
import com.userservice.models.Friend;
import com.userservice.models.User;
import com.userservice.repositories.FriendRepository;
import com.userservice.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FriendService {

    private final FriendRepository friendshipRepository;
    private final UserRepository userRepository;

    @Transactional
    public FriendshipResponseDTO sendFriendRequest(Long senderId, Long receiverId) {
        // Kiểm tra không gửi lời mời cho chính mình
        if (senderId.equals(receiverId)) {
            throw new IllegalArgumentException("Không thể kết bạn với chính mình");
        }

        // Lấy thông tin user
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người gửi"));
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người nhận"));

        // Kiểm tra đã có quan hệ nào giữa 2 user chưa
        if (friendshipRepository.existsBetweenUsers(senderId, receiverId)) {
            throw new IllegalArgumentException("Đã có lời mời kết bạn giữa 2 người này");
        }

        // Tạo friendship mới
        Friend friendship = new Friend();
        friendship.setSender(sender);
        friendship.setReceiver(receiver);
        friendship.setStatus(FriendshipStatus.PENDING);

        friendship = friendshipRepository.save(friendship);

        return mapToResponseDTO(friendship);
    }

    @Transactional
    public FriendshipResponseDTO acceptFriendRequest(Long userId, Long requestId) {
        Friend friendship = friendshipRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lời mời kết bạn"));

        // Kiểm tra quyền chấp nhận
        if (!friendship.getReceiver().getId().equals(userId)) {
            throw new IllegalArgumentException("Bạn không có quyền chấp nhận lời mời này");
        }

        if (friendship.getStatus() != FriendshipStatus.PENDING) {
            throw new IllegalArgumentException("Lời mời đã được xử lý");
        }

        friendship.setStatus(FriendshipStatus.ACCEPTED);
        friendship = friendshipRepository.save(friendship);

        return mapToResponseDTO(friendship);
    }

    @Transactional
    public FriendshipResponseDTO rejectFriendRequest(Long userId, Long requestId) {
        Friend friendship = friendshipRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lời mời kết bạn"));

        // Kiểm tra quyền từ chối
        if (!friendship.getReceiver().getId().equals(userId)) {
            throw new IllegalArgumentException("Bạn không có quyền từ chối lời mời này");
        }

        if (friendship.getStatus() != FriendshipStatus.PENDING) {
            throw new IllegalArgumentException("Lời mời đã được xử lý");
        }

        friendship.setStatus(FriendshipStatus.REJECTED);
        friendship = friendshipRepository.save(friendship);

        return mapToResponseDTO(friendship);
    }

    @Transactional(readOnly = true)
    public List<FriendshipResponseDTO> getPendingRequests(Long userId) {
        List<Friend> friendships = friendshipRepository.findPendingRequestsByReceiverId(userId);
        return friendships.stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<UserDTO> getFriends(Long userId) {
        List<Friend> friendships = friendshipRepository.findFriendsByUserId(userId);

        return friendships.stream()
                .map(friendship -> {
                    User friend = friendship.getSender().getId().equals(userId)
                            ? friendship.getReceiver()
                            : friendship.getSender();
                    return mapToUserDTO(friend);
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public boolean areFriends(Long userId1, Long userId2) {
        return friendshipRepository.areFriends(userId1, userId2);
    }

    @Transactional
    public void unfriend(Long userId, Long friendId) {
        // Sửa lại để dùng @Query thay vì findBySenderIdAndReceiverId
        var friendship = friendshipRepository.findBySenderIdAndReceiverId(userId, friendId)
                .or(() -> friendshipRepository.findBySenderIdAndReceiverId(friendId, userId));

        friendship.ifPresent(friendshipRepository::delete);
    }

    private FriendshipResponseDTO mapToResponseDTO(Friend friendship) {
        FriendshipResponseDTO dto = new FriendshipResponseDTO();
        dto.setId(friendship.getId());
        dto.setSender(mapToUserDTO(friendship.getSender()));
        dto.setReceiver(mapToUserDTO(friendship.getReceiver()));
        dto.setStatus(friendship.getStatus());
        dto.setCreatedAt(friendship.getCreatedAt());
        dto.setUpdatedAt(friendship.getUpdatedAt());
        return dto;
    }

    private UserDTO mapToUserDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setFullName(user.getFullName());
        dto.setPhotoUrl(user.getPhotoUrl());
        dto.setBio(user.getBio());

        // Include online status if available
        if (user.getStatus() != null) {
            dto.setOnline(user.getStatus().isOnline());
            dto.setLastSeen(user.getStatus().getLastSeen());
        }

        return dto;
    }
}