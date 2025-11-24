import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontend/presentation/view_models/user_view_model.dart';

import '../../data/models/post_model.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/post_repository.dart';

class PostViewModel extends ChangeNotifier {
  final PostRepository repository;
  final UserViewModel userVM;

  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  // Cache: firebaseUid -> UserProfile
  final Map<String, UserProfile> _userProfiles = {};

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, UserProfile> get userProfiles => _userProfiles;

  PostViewModel({required this.repository, required this.userVM});

  Future<void> loadAllPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await repository.getAllPosts();

      // Lấy profile từng user theo firebaseUid
      for (var post in _posts) {
        final uid = post.firebaseUid;
        if (!_userProfiles.containsKey(uid)) {
          final profile = await userVM.repository.getProfile(uid);
          if (profile != null) _userProfiles[uid] = profile;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost(String caption, File? image) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPost = await repository.addPost(caption, image);
      _posts.insert(0, newPost);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
