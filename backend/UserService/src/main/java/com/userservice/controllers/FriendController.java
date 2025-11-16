//package com.userservice.controllers;
//
//import com.userservice.dtos.ApiResponse;
//import com.userservice.dtos.FriendshipResponseDTO;
//import com.userservice.services.FriendService;
//import lombok.RequiredArgsConstructor;
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.*;
//
//@RestController
//@RequestMapping("/api/friends")
//@RequiredArgsConstructor
//public class FriendController {
//
//    private static final Logger log = LoggerFactory.getLogger(FriendController.class);
//
//    private final FriendService friendService;
//
//    /**
//     * Gửi lời mời kết bạn
//     */
//    @PostMapping("/request/{targetUserId}")
//    public ResponseEntity<?> sendFriendRequest(
//            @RequestHeader("X-User-Id") String firebaseUid,
//            @PathVariable Long targetUserId
//    ) {
//        friendService.sendFriendRequest(firebaseUid, targetUserId);
//        return ResponseEntity.ok(new ApiResponse(true, "Friend request sent"));
//    }
//
//    /**
//     * Chấp nhận lời mời kết bạn
//     */
//    @PostMapping("/accept/{sourceUserId}")
//    public ResponseEntity<?> acceptFriendRequest(
//            @RequestHeader("X-User-Id") String firebaseUid,
//            @PathVariable Long sourceUserId
//    ) {
//        friendService.acceptFriendRequest(firebaseUid, sourceUserId);
//        return ResponseEntity.ok(new ApiResponse(true, "Friend request accepted"));
//    }
//
//    /**
//     * Từ chối lời mời kết bạn
//     */
//    @PostMapping("/reject/{sourceUserId}")
//    public ResponseEntity<?> rejectFriendRequest(
//            @RequestHeader("X-User-Id") String firebaseUid,
//            @PathVariable Long sourceUserId
//    ) {
//        friendService.rejectFriendRequest(firebaseUid, sourceUserId);
//        return ResponseEntity.ok(new ApiResponse(true, "Friend request rejected"));
//    }
//
//    /**
//     * Hủy lời mời đã gửi
//     */
//    @DeleteMapping("/cancel/{targetUserId}")
//    public ResponseEntity<?> cancelFriendRequest(
//            @RequestHeader("X-User-Id") String firebaseUid,
//            @PathVariable Long targetUserId
//    ) {
//        friendService.cancelFriendRequest(firebaseUid, targetUserId);
//        return ResponseEntity.ok(new ApiResponse(true, "Friend request canceled"));
//    }
//
//    /**
//     * Hủy kết bạn (unfriend)
//     */
//    @DeleteMapping("/remove/{friendUserId}")
//    public ResponseEntity<?> removeFriend(
//            @RequestHeader("X-User-Id") String firebaseUid,
//            @PathVariable Long friendUserId
//    ) {
//        friendService.removeFriend(firebaseUid, friendUserId);
//        return ResponseEntity.ok(new ApiResponse(true, "Friend removed"));
//    }
//
//    /**
//     * Lấy danh sách bạn bè
//     */
//    @GetMapping
//    public ResponseEntity<?> getFriendList(
//            @RequestHeader("X-User-Id") String firebaseUid
//    ) {
//        return ResponseEntity.ok(friendService.getFriendList(firebaseUid));
//    }
//
//    /**
//     * Lấy danh sách lời mời mình gửi đi
//     */
//    @GetMapping("/requests/sent")
//    public ResponseEntity<?> getSentRequests(
//            @RequestHeader("X-User-Id") String firebaseUid
//    ) {
//        return ResponseEntity.ok(friendService.getSentRequests(firebaseUid));
//    }
//
//    /**
//     * Lấy danh sách lời mời mình nhận
//     */
//    @GetMapping("/requests/received")
//    public ResponseEntity<?> getReceivedRequests(
//            @RequestHeader("X-User-Id") String firebaseUid
//    ) {
//        return ResponseEntity.ok(friendService.getReceivedRequests(firebaseUid));
//    }
//
//    /**
//     * Lấy số lượng bạn bè
//     */
//    @GetMapping("/count")
//    public ResponseEntity<?> getFriendCount(
//            @RequestHeader("X-User-Id") String firebaseUid
//    ) {
//        long count = friendService.getFriendCount(firebaseUid);
//        return ResponseEntity.ok(new FriendshipResponseDTO(count));
//    }
//
//    /**
//     * Check có phải bạn bè chưa
//     */
//    @GetMapping("/check/{targetUserId}")
//    public ResponseEntity<?> checkFriendship(
//            @RequestHeader("X-User-Id") String firebaseUid,
//            @PathVariable Long targetUserId
//    ) {
//        boolean isFriend = friendService.isFriend(firebaseUid, targetUserId);
//        return ResponseEntity.ok(new ApiResponse(true, isFriend ? "Friends" : "Not friends"));
//    }
//}
