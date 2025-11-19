
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostRepository {
  final PostService postService;

  PostRepository({required this.postService});

  // Thêm page và size
  Future<List<Post>> getPosts(String uid, {int page = 0, int size = 10}) async {
    return await postService.getPosts(uid, page: page, size: size);
  }

  Future<Post> addPost(Post post) async {
    return await postService.addPost(post);
  }
}
