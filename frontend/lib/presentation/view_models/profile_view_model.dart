import 'package:flutter/material.dart';

import '../../data/models/post_model.dart';
import '../../data/services/post_service.dart';

class PostViewModel extends ChangeNotifier {
  final PostService _service = PostService();

  List<Post> posts = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchPosts() async {
    isLoading = true;
    notifyListeners();

    try {
      posts = await _service.getAllPosts();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost(Post post) async {
    try {
      final newPost = await _service.createPost(post);
      posts.insert(0, newPost);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePost(int id) async {
    try {
      await _service.deletePost(id);
      posts.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
