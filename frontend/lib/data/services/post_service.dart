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

  // Lấy post từ backend với paging
  Future<List<Post>> getPosts(String uid, {int page = 0, int size = 10}) async {
    final token = await AuthService().getToken();

    final queryParameters = {
      if (uid.isNotEmpty) 'firebaseUid': uid,
      'page': page.toString(),
      'size': size.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/posts').replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch posts: ${response.body}');
    }
  }

  // Tạo post mới
  Future<Post> addPost(Post post) async {
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(post.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('post')) {
        return Post.fromJson(data['post']);
      }
      return Post.fromJson(data);
    } else {
      throw Exception('Failed to create post: ${response.body}');
    }
  }
}
