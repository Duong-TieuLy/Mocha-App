import 'dart:convert';
import 'package:frontend/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});
  Future<Map<String, dynamic>> fetchProfile(String uid) async {
    final token = await AuthService().getToken(); // await là bắt buộc
    print('Token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  Future<String> uploadProfileImage(File file) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse('$baseUrl/api/users/upload-photo');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      return respStr; // backend trả về URL ảnh
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload image: $respStr');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String keyword, String uid) async {
    final token = await AuthService().getToken();
    final uri = Uri.parse('$baseUrl/api/users/search?keyword=$keyword');

    final response = await http.get(
      uri,
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Search failed: ${response.body}');
    }
  }

  Future<bool> updateProfile(String uid, Map<String, dynamic> updatedData) async {
    final token = await AuthService().getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-User-Id': uid,
        'Content-Type': 'application/json', // ⚠️ thêm cái này
      },
      body: json.encode(updatedData),
    );

    print("Update status: ${response.statusCode}");
    print("Update response: ${response.body}");

    return response.statusCode == 200;
  }

  Future<bool> followUser(String uid, int userId) async {
    final token = await AuthService().getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/users/follow/$userId'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> unfollowUser(String uid, int userId) async {
    final token = await AuthService().getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/follow/$userId'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> isFollowing(String uid, int userId) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/follow/check/$userId'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200 && response.body == "true";
  }

  Future<bool> areFriends(String uid, int userId) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/follow/friends/$userId'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200 && response.body == "true";
  }

  Future<List<dynamic>> getFollowers(String uid) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/follow/followers'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    return json.decode(response.body);
  }

  Future<List<dynamic>> getFollowing(String uid) async {
    final token = await AuthService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/follow/following'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    return json.decode(response.body);
  }

}