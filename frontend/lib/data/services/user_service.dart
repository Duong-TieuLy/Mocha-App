import 'dart:convert';
import 'package:frontend/data/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart'; // ✅ ADD THIS

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  Future<Map<String, dynamic>> fetchProfile(String uid) async {
    final token = await AuthService().getToken();
    debugPrint('Token: $token'); // ✅ CHANGED

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
      return respStr;
    } else {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload image: $respStr');
    }
  }

  Future<List<Map<String, dynamic>>> getFriends(String uid) async {
    try {
      debugPrint("╔═══════════════════════════════════════╗");
      debugPrint("║ 📡 UserService: getFriends            ║");
      debugPrint("╠═══════════════════════════════════════╣");
      debugPrint("║ UID: $uid");
      debugPrint("║ Base URL: $baseUrl");

      final token = await AuthService().getToken();
      debugPrint("║ Token: ${token?.substring(0, 20)}...");

      final url = Uri.parse('$baseUrl/api/users/follow/friends');
      debugPrint("║ Full URL: $url");

      final response = await http.get(
        url,
        headers: {
          'X-User-Id': uid,
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('⏱️ Request timeout after 15 seconds');
        },
      );

      debugPrint("║ Status: ${response.statusCode}");
      debugPrint("║ Response Body Length: ${response.body.length}");
      debugPrint("║ Response Body: ${response.body}"); // ⬅️ THIS IS KEY!

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        debugPrint("║ Decoded type: ${decoded.runtimeType}"); // ⬅️ ADD THIS

        if (decoded is List) {
          debugPrint("║ ✅ Response is List with ${decoded.length} items");

          // ⬅️ LOG EACH ITEM
          for (var i = 0; i < decoded.length; i++) {
            final item = decoded[i];
            debugPrint("║ Item $i: $item");
            debugPrint("║   - firebaseUid: ${item['firebaseUid']}");
            debugPrint("║   - fullName: ${item['fullName']}");
            debugPrint("║   - photoUrl: ${item['photoUrl']}");
          }

          final List<Map<String, dynamic>> result = decoded.cast<Map<String, dynamic>>();
          debugPrint("║ ✅ Returning ${result.length} friends");
          debugPrint("╚═══════════════════════════════════════╝");
          return result;
        }

        // If it's a Map with nested data
        if (decoded is Map) {
          debugPrint("║ Response is Map with keys: ${decoded.keys}");

          if (decoded['data'] is List) {
            final List data = decoded['data'];
            debugPrint("║ ✅ Found 'data' key with ${data.length} items");
            debugPrint("╚═══════════════════════════════════════╝");
            return data.cast<Map<String, dynamic>>();
          }
        }

        debugPrint("║ ⚠️  Unknown response structure!");
        debugPrint("╚═══════════════════════════════════════╝");
        return [];

      } else if (response.statusCode == 404) {
        debugPrint("║ ℹ️  404 - No friends yet");
        debugPrint("╚═══════════════════════════════════════╝");
        return [];
      } else {
        debugPrint("║ ❌ Error: ${response.statusCode}");
        debugPrint("║ Error Body: ${response.body}");
        debugPrint("╚═══════════════════════════════════════╝");
        throw Exception('Failed to get friends: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint("╔═══════════════════════════════════════╗");
      debugPrint("║ ❌ EXCEPTION in getFriends            ║");
      debugPrint("╠═══════════════════════════════════════╣");
      debugPrint("║ Error: $e");
      debugPrint("║ Stack trace:");
      debugPrint(stackTrace.toString().split('\n').take(5).map((line) => '║ $line').join('\n'));
      debugPrint("╚═══════════════════════════════════════╝");
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
        'Content-Type': 'application/json', // ✅ ADD THIS
      },
      body: json.encode(updatedData),
    );

    debugPrint("Update status: ${response.statusCode}");
    debugPrint("Update response: ${response.body}");

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