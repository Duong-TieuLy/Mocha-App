import 'package:flutter/material.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository repository;

  UserViewModel({required this.repository});

  /// Profile của chính người dùng
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// FOLLOW STATE CHO USER ĐANG XEM
  /// Map<userId, bool>
  final Map<int, bool> _followingCache = {};
  final Map<int, bool> _friendCache = {};

  bool isFollowing(int userId) => _followingCache[userId] ?? false;
  bool areFriends(int userId) => _friendCache[userId] ?? false;

  /// ==========================
  /// LOAD PROFILE CỦA CHÍNH MÌNH
  /// ==========================
  Future<void> loadProfile(String uid) async {
    _setLoading(true);
    try {
      final result = await repository.getProfile(uid);
      if (result != null) {
        _profile = result;
        _error = null;
      } else {
        _error = 'User not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// ==========================
  /// UPDATE PROFILE
  /// ==========================
  Future<bool> updateProfile(String uid, Map<String, dynamic> updatedData) async {
    _setLoading(true);
    try {
      final success = await repository.updateProfile(uid, updatedData);
      if (!success) {
        _error = "Update failed";
        return false;
      }

      /// Update lại local nếu thành công
      if (_profile != null) {
        _profile = _profile!.copyWith(
          fullName: updatedData['fullName'] ?? _profile!.fullName,
          bio: updatedData['bio'] ?? _profile!.bio,
          interests: updatedData['interests'] ?? _profile!.interests,
          photoUrl: updatedData['photoUrl'] ?? _profile!.photoUrl,
          location: updatedData['location'] ?? _profile!.location,
          phoneNumber: updatedData['phoneNumber'] ?? _profile!.phoneNumber,
          gender: updatedData['gender'] != null
              ? Gender.fromString(updatedData['gender'])
              : _profile!.gender,
          dateOfBirth: updatedData['dateOfBirth'] != null
              ? DateTime.tryParse(updatedData['dateOfBirth'])
              : _profile!.dateOfBirth,
        );
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ==========================
  /// SEARCH USERS
  /// ==========================
  List<UserProfile> _searchResults = [];
  List<UserProfile> get searchResults => _searchResults;

  Future<void> performSearch(String uid, String keyword) async {
    _setLoading(true);
    try {
      _searchResults = await repository.searchUsers(keyword, uid);
    } catch (e) {
      _searchResults = [];
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// ==========================
  /// FOLLOW / UNFOLLOW
  /// ==========================

  Future<void> checkFollowStatus(String uid, int targetUserId) async {
    _followingCache[targetUserId] =
    await repository.isFollowing(uid, targetUserId);

    _friendCache[targetUserId] =
    await repository.areFriends(uid, targetUserId);

    notifyListeners();
  }

  Future<void> follow(String uid, int targetUserId) async {
    final success = await repository.followUser(uid, targetUserId);

    if (success) {
      _followingCache[targetUserId] = true;
      notifyListeners();
    }
  }

  Future<void> unfollow(String uid, int targetUserId) async {
    final success = await repository.unfollowUser(uid, targetUserId);

    if (success) {
      _followingCache[targetUserId] = false;
      notifyListeners();
    }
  }

  /// ==========================
  /// UTILS
  /// ==========================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
