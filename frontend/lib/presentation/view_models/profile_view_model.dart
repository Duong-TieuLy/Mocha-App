import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/services/post_service.dart';

class PostViewModel extends ChangeNotifier {
  final PostService _service = PostService();

  List<Post> posts = [];
  bool isLoading = false;
  String? errorMessage;

  /// 🔹 Lấy danh sách bài viết
  Future<void> fetchPosts([String? token]) async {
    _setLoading(true);
    try {
      posts = await _service.getAllPosts(token);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load posts: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 Tạo bài viết mới
  Future<void> createPost(Post post, [String? token]) async {
    _setLoading(true);
    try {
      final newPost = await _service.createPost(post, token);
      posts.insert(0, newPost);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to create post: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 Xoá bài viết theo ID
  Future<void> deletePost(int id, [String? token]) async {
    _setLoading(true);
    try {
      await _service.deletePost(id, token);
      posts.removeWhere((p) => p.id == id);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to delete post: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 Làm mới danh sách
  Future<void> refresh([String? token]) async => fetchPosts(token);

  /// 🔹 Helper cập nhật trạng thái loading
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
