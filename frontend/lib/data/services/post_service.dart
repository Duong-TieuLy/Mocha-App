import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import 'auth_service.dart';
import 'package:path/path.dart';

class PostService {
  final String baseUrl;

  PostService({required this.baseUrl});

  Future<List<Post>> fetchAllPosts() async {
    final token = await AuthService().getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      List<Post> posts = data.map((json) => Post.fromJson(json)).toList();

      // Sort giảm dần theo createdAt
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return posts;
    } else {
      throw Exception('Failed to fetch posts');
    }
  }

  Future<Post> createPost(String caption, File? image) async {
    final uri = Uri.parse('$baseUrl/api/posts'); // fix URL

    var request = http.MultipartRequest('POST', uri);

    request.fields['caption'] = caption.isNotEmpty ? caption : "Không có caption";

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: basename(image.path),
      ));
    }

    final token = await AuthService().getToken();
    final currentUserId = await AuthService().getUid(); // hoặc FirebaseAuth.instance.currentUser!.uid

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['X-User-Id'] = currentUserId;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Post.fromJson(data);
    } else {
      throw Exception('Failed to create post: ${response.body}');
    }
  }
}
