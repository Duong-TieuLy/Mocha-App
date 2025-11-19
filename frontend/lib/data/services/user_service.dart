import 'dart:convert';
import 'package:frontend/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  Future<Map<String, dynamic>> fetchProfile(String uid) async {
    final token = await AuthService().getToken();
    debugPrint('Fetching profile for UID: $uid');

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/profile'),
      headers: {
        'X-User-Id': uid,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
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
      return respStr;
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload image: $respStr');
    }
  }

  Future<List<Map<String, dynamic>>> getFriends(String uid) async {
    try {
      debugPrint("UserService: Getting friends for UID: $uid");

      final token = await AuthService().getToken();
      final url = Uri.parse('$baseUrl/api/users/follow/friends');

      final response = await http.get(
        url,
        headers: {
          'X-User-Id': uid,
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds');
        },
      );

      debugPrint("Get friends response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is List) {
          debugPrint("Successfully loaded ${decoded.length} friends");
          return decoded.cast<Map<String, dynamic>>();
        }

        if (decoded is Map && decoded['data'] is List) {
          final List data = decoded['data'];
          debugPrint("Successfully loaded ${data.length} friends from 'data' key");
          return data.cast<Map<String, dynamic>>();
        }

        debugPrint("Warning: Unknown response structure");
        return [];

      } else if (response.statusCode == 404) {
        debugPrint("No friends found (404)");
        return [];
      } else {
        throw Exception('Failed to get friends: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint("Error in getFriends: $e");
      debugPrint("Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}");
      rethrow;
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
        'Content-Type': 'application/json',
      },
      body: json.encode(updatedData),
    );

    debugPrint("Update profile status: ${response.statusCode}");

    if (response.statusCode != 200) {
      debugPrint("Update profile error: ${response.body}");
    }

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