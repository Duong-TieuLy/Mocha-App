package com.userservice.services;

import com.userservice.dtos.FriendshipResponseDTO;
import com.userservice.dtos.UserDTO;
import com.userservice.models.Friend;
import com.userservice.models.User;
import com.userservice.repositories.FriendRepository;
import com.userservice.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class FriendService {

    private final FriendRepository friendRepository;
    private final UserRepository userRepository;

    /**
     * Tạo friendship tự động khi 2 người follow lẫn nhau
     * Được gọi từ FollowService sau khi follow thành công
     */
    @Transactional
    public void createFriendshipIfMutualFollow(Long userId1, Long userId2) {
        log.info("==> Checking friendship creation: {} <-> {}", userId1, userId2);
        
        try {
            // Kiểm tra xem đã là bạn bè chưa
            if (friendRepository.existsByUserIds(userId1, userId2)) {
                log.info("Friendship already exists between {} and {}", userId1, userId2);
                return;
            }

            // ✅ FIX: Kiểm tra mutual follow bằng query trực tiếp thay vì lazy loading
            boolean user1FollowsUser2 = userRepository.isFollowing(userId1, userId2);
            boolean user2FollowsUser1 = userRepository.isFollowing(userId2, userId1);

            log.info("Mutual follow check: {} -> {} = {}, {} -> {} = {}", 
                    userId1, userId2, user1FollowsUser2,
                    userId2, userId1, user2FollowsUser1);

            if (user1FollowsUser2 && user2FollowsUser1) {
                // Tạo friendship (luôn đặt ID nhỏ hơn trước)
                Friend friendship = new Friend();
                Long smallerId = Math.min(userId1, userId2);
                Long largerId = Math.max(userId1, userId2);

                User user1 = userRepository.findById(smallerId)
                        .orElseThrow(() -> new RuntimeException("User not found: " + smallerId));
                User user2 = userRepository.findById(largerId)
                        .orElseThrow(() -> new RuntimeException("User not found: " + largerId));

                friendship.setUser1(user1);
                friendship.setUser2(user2);

                friendRepository.save(friendship);
                log.info("✅ Created friendship between {} and {}", smallerId, largerId);
            } else {
                log.info("Not mutual follow yet between {} and {}", userId1, userId2);
            }
        } catch (Exception e) {
            log.error("❌ Error in createFriendshipIfMutualFollow: {}", e.getMessage(), e);
            throw e;
        }
    }

    /**
     * Xóa friendship khi unfollow
     * Được gọi từ FollowService sau khi unfollow thành công
     */
    @Transactional
    public void deleteFriendshipIfExists(Long userId1, Long userId2) {
        if (friendRepository.existsByUserIds(userId1, userId2)) {
            friendRepository.deleteByUserIds(userId1, userId2);
            log.info("Deleted friendship between {} and {}", userId1, userId2);
        }
    }

    /**
     * Kiểm tra 2 user có phải bạn bè không
     */
    public boolean areFriends(Long userId1, Long userId2) {
        return friendRepository.existsByUserIds(userId1, userId2);
    }

    /**
     * Lấy danh sách bạn bè của user
     */
    @Transactional(readOnly = true)
    public List<FriendshipResponseDTO> getFriends(Long userId) {
        List<Friend> friendships = friendRepository.findAllByUserId(userId);

        return friendships.stream()
                .map(friendship -> {
                    User otherUser = friendship.getOtherUser(userId);
                    return new FriendshipResponseDTO(
                            friendship.getId(),
                            convertToUserDTO(friendship.getUser1()),
                            convertToUserDTO(friendship.getUser2()),
                            friendship.getCreatedAt(),
                            null  // Không còn updatedAt
                    );
                })
                .collect(Collectors.toList());
    }

    /**
     * Lấy danh sách ID của tất cả bạn bè (dùng cho queries khác)
     */
    public List<Long> getFriendIds(Long userId) {
        return friendRepository.findAllFriendIdsByUserId(userId);
    }

    /**
     * Đếm số lượng bạn bè
     */
    public long countFriends(Long userId) {
        return friendRepository.countByUserId(userId);
    }

    private UserDTO convertToUserDTO(User user) {
        if (user == null) return null;

        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setFullName(user.getFullName());
        dto.setBio(user.getBio());
        dto.setPhotoUrl(user.getPhotoUrl());
        return dto;
    }
}