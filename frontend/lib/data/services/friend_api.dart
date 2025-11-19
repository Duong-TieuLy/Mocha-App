import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FriendApi {
  static const String baseUrl = "http://10.0.2.2:8080/api/users/follow";

  // Get friends list
  static Future<List<Map<String, dynamic>>> getFriends(String firebaseUid) async {
    try {
      final url = Uri.parse("$baseUrl/friends");
      debugPrint("API: Getting friends for user: $firebaseUid");

      final headers = {
        "X-User-Id": firebaseUid,
        "Content-Type": "application/json",
      };

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Request timeout after 10 seconds");
        },
      );

      debugPrint("Get friends response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseBody = response.body;

        dynamic decoded;
        try {
          decoded = json.decode(responseBody);
        } catch (e) {
          debugPrint("JSON decode error: $e");
          return [];
        }

        // Handle different response formats
        List data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['friends'] is List) {
            data = decoded['friends'];
          } else if (decoded['result'] is List) {
            data = decoded['result'];
          } else {
            debugPrint("Unknown Map structure in response");
            return [];
          }
        } else {
          debugPrint("Unknown response type");
          return [];
        }

        debugPrint("Successfully loaded ${data.length} friends");
        return data.map((e) => e as Map<String, dynamic>).toList();

      } else if (response.statusCode == 404) {
        debugPrint("No friends found (404)");
        return [];
      } else {
        debugPrint("Error getting friends: ${response.statusCode}");
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint("Exception in getFriends: $e");
      debugPrint("Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}");
      return [];
    }
  }

  // Search users
  static Future<List<Map<String, dynamic>>> searchUsers(
    String firebaseUid,
    String query,
  ) async {
    try {
      final url = Uri.parse("http://10.0.2.2:8080/api/users/search?query=$query");
      debugPrint("API: Searching users with query: $query");

      final response = await http.get(
        url,
        headers: {
          "X-User-Id": firebaseUid,
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        debugPrint("Found ${data.length} users");
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      debugPrint("Error searching users: $e");
      return [];
    }
  }

  // Send friend request
  static Future<bool> sendFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/request");
      debugPrint("API: Sending friend request from $currentUserId to $targetUserId");

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Friend request sent successfully");
        return true;
      } else {
        debugPrint("Failed to send friend request: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error sending friend request: $e");
      return false;
    }
  }

  // Get pending friend requests
  static Future<List<Map<String, dynamic>>> getPendingRequests(
    String firebaseUid,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/requests/pending");
      debugPrint("API: Getting pending requests");

      final response = await http.get(
        url,
        headers: {
          "X-User-Id": firebaseUid,
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        debugPrint("Found ${data.length} pending requests");
        return data.map((e) => e as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      debugPrint("Error getting pending requests: $e");
      return [];
    }
  }

  // Accept friend request
  static Future<bool> acceptFriendRequest(
    String currentUserId,
    String requestId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/accept");
      debugPrint("API: Accepting friend request: $requestId");

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Friend request accepted");
        return true;
      } else {
        debugPrint("Failed to accept friend request: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error accepting friend request: $e");
      return false;
    }
  }

  // Reject friend request
  static Future<bool> rejectFriendRequest(
    String currentUserId,
    String requestId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/reject");
      debugPrint("API: Rejecting friend request: $requestId");

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Friend request rejected");
        return true;
      } else {
        debugPrint("Failed to reject friend request: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error rejecting friend request: $e");
      return false;
    }
  }

  // Unfriend
  static Future<bool> unfriend(
    String currentUserId,
    String friendUserId,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/unfriend");
      debugPrint("API: Unfriending user: $friendUserId");

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Unfriended successfully");
        return true;
      } else {
        debugPrint("Failed to unfriend: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error unfriending: $e");
      return false;
    }
  }
}