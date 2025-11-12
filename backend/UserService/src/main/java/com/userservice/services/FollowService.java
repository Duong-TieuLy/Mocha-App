package com.userservice.services;

import com.userservice.models.User;
import com.userservice.repositories.UserRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class FollowService {
    private final UserRepository userRepo;

    public FollowService(UserRepository userRepo) {
        this.userRepo = userRepo;
    }

    public boolean followUser(String followerUid, String targetUid) {
        Optional<User> followerOpt = userRepo.findByFirebaseUid(followerUid);
        Optional<User> targetOpt = userRepo.findByFirebaseUid(targetUid);

        if (followerOpt.isPresent() && targetOpt.isPresent()) {
            User follower = followerOpt.get();
            User target = targetOpt.get();

            follower.getFollowing().add(target);
            target.getFollowers().add(follower);

            userRepo.save(follower);
            userRepo.save(target);
            return true;
        }
        return false;
    }

    public boolean unfollowUser(String followerUid, String targetUid) {
        Optional<User> followerOpt = userRepo.findByFirebaseUid(followerUid);
        Optional<User> targetOpt = userRepo.findByFirebaseUid(targetUid);

        if (followerOpt.isPresent() && targetOpt.isPresent()) {
            User follower = followerOpt.get();
            User target = targetOpt.get();

            follower.getFollowing().remove(target);
            target.getFollowers().remove(follower);

            userRepo.save(follower);
            userRepo.save(target);
            return true;
        }
        return false;
    }
}
