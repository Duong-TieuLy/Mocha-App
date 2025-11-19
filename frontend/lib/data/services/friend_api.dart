import 'dart:convert';
import 'package:http/http.dart' as http;

class FriendApi {
  static const String baseUrl = "http://10.0.2.2:8080/api/users/follow";

  // ✅ 1. Lấy danh sách bạn bè - ENHANCED DEBUG VERSION
  static Future<List<Map<String, dynamic>>> getFriends(String firebaseUid) async {
    try {
      final url = Uri.parse("$baseUrl/friends");

      print("╔═══════════════════════════════════════╗");
      print("║ 📡 API: GET Friends                   ║");
      print("╠═══════════════════════════════════════╣");
      print("║ URL: $url");
      print("║ User ID: $firebaseUid");
      print("║ User ID Length: ${firebaseUid.length}");

      final headers = {
        "X-User-Id": firebaseUid,
        "Content-Type": "application/json",
      };

      print("║ Headers: $headers");

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("⏱️ Request timeout after 10 seconds");
        },
      );

      print("║ Status: ${response.statusCode}");
      print("║ Response Headers: ${response.headers}");
      print("║ Response Body Length: ${response.body.length}");
      print("║ Raw Response Body:");
      print("║ ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Try to decode
        dynamic decoded;
        try {
          decoded = json.decode(responseBody);
          print("║ Decoded Type: ${decoded.runtimeType}");
        } catch (e) {
          print("║ ❌ JSON Decode Error: $e");
          print("╚═══════════════════════════════════════╝");
          return [];
        }

        // Handle different response formats
        List data;
        if (decoded is List) {
          print("║ ✅ Response is a List");
          data = decoded;
        } else if (decoded is Map) {
          print("║ ⚠️  Response is a Map, keys: ${decoded.keys}");
          if (decoded['data'] is List) {
            print("║ ✅ Found 'data' key with List");
            data = decoded['data'];
          } else if (decoded['friends'] is List) {
            print("║ ✅ Found 'friends' key with List");
            data = decoded['friends'];
          } else if (decoded['result'] is List) {
            print("║ ✅ Found 'result' key with List");
            data = decoded['result'];
          } else {
            print("║ ❌ Unknown Map structure!");
            print("╚═══════════════════════════════════════╝");
            return [];
          }
        } else {
          print("║ ❌ Unknown response type!");
          print("╚═══════════════════════════════════════╝");
          return [];
        }

        print("║ ✅ Loaded ${data.length} friends");

        // Log each friend
        for (var i = 0; i < data.length; i++) {
          final friend = data[i];
          print("║ Friend $i:");
          print("║   - firebaseUid: ${friend['firebaseUid']}");
          print("║   - fullName: ${friend['fullName']}");
          print("║   - email: ${friend['email']}");
          print("║   - photoUrl: ${friend['photoUrl']}");
        }

        print("╚═══════════════════════════════════════╝");

        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 404) {
        print("║ ℹ️  No friends found (404)");
        print("╚═══════════════════════════════════════╝");
        return [];
      } else {
        print("║ ❌ Error Status: ${response.statusCode}");
        print("║ Error Body: ${response.body}");
        print("╚═══════════════════════════════════════╝");
        return [];
      }
    } catch (e, stackTrace) {
      print("╔═══════════════════════════════════════╗");
      print("║ ❌ Exception in getFriends            ║");
      print("╠═══════════════════════════════════════╣");
      print("║ Error: $e");
      print("║ Stack Trace:");
      print(stackTrace.toString().split('\n').take(5).map((line) => '║ $line').join('\n'));
      print("╚═══════════════════════════════════════╝");
      return [];
    }
  }

  // ✅ 2. Tìm kiếm users
  static Future<List<Map<String, dynamic>>> searchUsers(
    String firebaseUid,
    String query,
  ) async {
    try {
      final url = Uri.parse("http://10.0.2.2:8080/api/users/search?query=$query");

      print("╔═══════════════════════════════════════╗");
      print("║ 🔍 API: Search Users                  ║");
      print("╠═══════════════════════════════════════╣");
      print("║ Query: $query");

      final response = await http.get(
        url,
        headers: {
          "X-User-Id": firebaseUid,
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      print("║ Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        print("║ ✅ Found ${data.length} users");
        print("╚═══════════════════════════════════════╝");
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      print("╚═══════════════════════════════════════╝");
      return [];
    } catch (e) {
      print("❌ Error searching users: $e");
      return [];
    }
  }

  // ✅ 3. Gửi lời mời kết bạn
  static Future<bool> sendFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/request");

      print("╔═══════════════════════════════════════╗");
      print("║ 📤 API: Send Friend Request           ║");
      print("╠═══════════════════════════════════════╣");
      print("║ From: $currentUserId");
      print("║ To: $targetUserId");

      final response = await http.post(
        url,
        headers: {
          "X-User-Id": currentUserId,
          "Content-Type": "application/json",
        },
        body: json.encode({
          "targetUserId": targetUserId,
        }),
      ).timeout(const Duration(seconds: 10));

      print("║ Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("║ ✅ Friend request sent successfully");
        print("╚═══════════════════════════════════════╝");
        return true;
      } else {
        print("║ ❌ Failed: ${response.body}");
        print("╚═══════════════════════════════════════╝");
        return false;
      }
    } catch (e) {
      print("❌ Error sending friend request: $e");
      return false;
    }
  }

  // ✅ 4. Lấy danh sách lời mời kết bạn đang chờ
  static Future<List<Map<String, dynamic>>> getPendingRequests(
    String firebaseUid,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/requests/pending");

      print("╔═══════════════════════════════════════╗");
      print("║ 📬 API: Get Pending Requests          ║");
      print("╚═══════════════════════════════════════╝");

      final response = await http.get(
        url,
        headers: {
          "X-User-Id": firebaseUid,
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        print("✅ Found ${data.length} pending requests");
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      print("❌ Error getting pending requests: $e");
      return [];
    }
  }

  // ✅ 5. Chấp nhận lời mời kết bạn
  static Future<bool> acceptFriendRequest(
    String currentUserId,
    String requestId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/accept");

      print("╔═══════════════════════════════════════╗");
      print("║ ✅ API: Accept Friend Request         ║");
      print("╠═══════════════════════════════════════╣");
      print("║ Request ID: $requestId");

      final response = await http.post(
        url,
        headers: {
          "X-User-Id": currentUserId,
          "Content-Type": "application/json",
        },
        body: json.encode({
          "requestId": requestId,
        }),
      ).timeout(const Duration(seconds: 10));

      print("║ Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("║ ✅ Friend request accepted");
        print("╚═══════════════════════════════════════╝");
        return true;
      } else {
        print("║ ❌ Failed: ${response.body}");
        print("╚═══════════════════════════════════════╝");
        return false;
      }
    } catch (e) {
      print("❌ Error accepting friend request: $e");
      return false;
    }
  }

  // ✅ 6. Từ chối lời mời kết bạn
  static Future<bool> rejectFriendRequest(
    String currentUserId,
    String requestId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/reject");

      print("╔═══════════════════════════════════════╗");
      print("║ ❌ API: Reject Friend Request         ║");
      print("╠═══════════════════════════════════════╣");
      print("║ Request ID: $requestId");

      final response = await http.post(
        url,
        headers: {
          "X-User-Id": currentUserId,
          "Content-Type": "application/json",
        },
        body: json.encode({
          "requestId": requestId,
        }),
      ).timeout(const Duration(seconds: 10));

      print("║ Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("║ ✅ Friend request rejected");
        print("╚═══════════════════════════════════════╝");
        return true;
      } else {
        print("║ ❌ Failed: ${response.body}");
        print("╚═══════════════════════════════════════╝");
        return false;
      }
    } catch (e) {
      print("❌ Error rejecting friend request: $e");
      return false;
    }
  }

  // ✅ 7. Hủy kết bạn (Unfriend)
  static Future<bool> unfriend(
    String currentUserId,
    String friendUserId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/unfriend");

      print("╔═══════════════════════════════════════╗");
      print("║ 💔 API: Unfriend                      ║");
      print("╠═══════════════════════════════════════╣");
      print("║ Unfriend: $friendUserId");

      final response = await http.post(
        url,
        headers: {
          "X-User-Id": currentUserId,
          "Content-Type": "application/json",
        },
        body: json.encode({
          "friendUserId": friendUserId,
        }),
      ).timeout(const Duration(seconds: 10));

      print("║ Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("║ ✅ Unfriended successfully");
        print("╚═══════════════════════════════════════╝");
        return true;
      } else {
        print("║ ❌ Failed: ${response.body}");
        print("╚═══════════════════════════════════════╝");
        return false;
      }
    } catch (e) {
      print("❌ Error unfriending: $e");
      return false;
    }
  }
}