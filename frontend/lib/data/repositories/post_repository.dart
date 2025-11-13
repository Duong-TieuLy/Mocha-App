
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostRepository {
  final PostService service;

  PostRepository({required this.service});

  Future<List<Post>> getPosts(String uid) async {
    return await service.fetchPosts(uid);
  }

  Future<Post> addPost(Post post) async {
    return await service.createPost(post);
  }
}
