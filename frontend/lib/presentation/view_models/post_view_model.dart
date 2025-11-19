import 'package:flutter/material.dart';

import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class PostViewModel extends ChangeNotifier {
  final PostRepository repository;

  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true; // kiểm tra còn page tiếp hay không
  int _page = 0;        // page hiện tại
  final int _pageSize = 10;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  PostViewModel({required this.repository});

  // Load posts với paging, refresh để pull-to-refresh
  Future<void> loadPosts(String uid, {bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _page = 0;
      _hasMore = true;
      _posts.clear();
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPosts = await repository.getPosts(uid, page: _page, size: _pageSize);
      if (newPosts.length < _pageSize) _hasMore = false;

      _posts.addAll(newPosts);
      _page++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Post?> createPost(Post post) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPost = await repository.addPost(post);
      _posts.insert(0, newPost);
      return newPost;              // ✅ return về UI
    } catch (e) {
      _error = e.toString();
      return null;                 // ⚠️ tránh throw lên UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
