
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostRepository {
  final PostService postService;

  PostRepository({required this.postService});

  Future<List<Post>> getPosts(String uid) async {
    return await postService.fetchPosts(uid);
  }

  Future<Post> addPost(Post post) async {
    return await postService.createPost(post);
  }
}
