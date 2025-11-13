import 'package:flutter/material.dart';

import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class PostViewModel extends ChangeNotifier {
  final PostRepository repository;

  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PostViewModel({required this.repository});

  Future<void> loadPosts(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await repository.getPosts(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost(Post post) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPost = await repository.addPost(post);
      _posts.insert(0, newPost);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
