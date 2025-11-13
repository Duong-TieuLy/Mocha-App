import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class PostService {
  final String baseUrl = 'http://10.0.2.2:8080/api/posts';

  Map<String, String> _headers([String? token]) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<List<Post>> getAllPosts([String? token]) async {
    final response = await http.get(Uri.parse(baseUrl), headers: _headers(token));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Post.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load posts: ${response.body}');
    }
  }

  Future<Post> getPost(int id, [String? token]) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'), headers: _headers(token));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Post.fromJson(data['post'] ?? data);
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Post> createPost(Post post, [String? token]) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: _headers(token),
      body: jsonEncode(post.toJson()),
    );
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create post');
    }
  }

  Future<void> deletePost(int id, [String? token]) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: _headers(token));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete post');
    }
  }
}
