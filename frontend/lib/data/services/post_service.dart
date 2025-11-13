import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import 'auth_service.dart';

class PostService {
  final String baseUrl;

  PostService({required this.baseUrl});

  Future<List<Post>> fetchPosts(String firebaseUid) async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch posts');
    }
  }

  Future<Post> createPost(Post post) async {
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(post.toJson()),
    );

    if (response.statusCode == 201) {
      return Post.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create post');
    }
  }
}
