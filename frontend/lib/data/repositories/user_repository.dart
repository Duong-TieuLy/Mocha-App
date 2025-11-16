import 'package:frontend/data/services/user_service.dart';
import 'dart:io';

import '../models/user_profile.dart';

class UserRepository {
  final UserService userService;

  UserRepository({required this.userService});
  Future<UserProfile?> getProfile(String uid) async {
    print('Calling fetchProfile for UID: $uid');
    final data = await userService.fetchProfile(uid);
    print('Profile JSON: $data');
    if (data != null) return UserProfile.fromJson(data);
    return null;
  }

  Future<bool> updateProfile(String uid, Map<String, dynamic> updatedData) {
    return userService.updateProfile(uid, updatedData);
  }

  Future<List<UserProfile>> searchUsers(String keyword, String uid) async {
    final data = await userService.searchUsers(keyword, uid);
    return data.map((e) => UserProfile.fromJson(e)).toList();
  }

  Future<String> uploadProfileImage(File file) {
    return userService.uploadProfileImage(file);
  }

  Future<bool> followUser(String uid, int userId) =>
      userService.followUser(uid, userId);

  Future<bool> unfollowUser(String uid, int userId) =>
      userService.unfollowUser(uid, userId);

  Future<bool> isFollowing(String uid, int userId) =>
      userService.isFollowing(uid, userId);

  Future<bool> areFriends(String uid, int userId) =>
      userService.areFriends(uid, userId);

  Future<List<dynamic>> getFollowers(String uid) =>
      userService.getFollowers(uid);

  Future<List<dynamic>> getFollowing(String uid) =>
      userService.getFollowing(uid);


}