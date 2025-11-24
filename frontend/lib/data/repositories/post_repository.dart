import '../models/post_model.dart';
import '../services/post_service.dart';
import 'dart:io';

class PostRepository {
  final PostService postService;

  PostRepository({required this.postService});

  Future<List<Post>> getAllPosts() async {
    return await postService.fetchAllPosts();
  }

  Future<Post> addPost(String caption, File? image) async {
    return await postService.createPost(caption, image);
  }
}
