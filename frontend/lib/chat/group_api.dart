import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GroupApi {
  static const String baseUrl = 'http://10.0.2.2:8081'; // Android emulator
  // static const String baseUrl = 'http://localhost:8080'; // iOS simulator

  /// Tạo group chat mới
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<String> memberIds,
    required String createdBy,
    String? avatar,
  }) async {
    try {
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 🆕 CREATING GROUP CHAT                ║');
      debugPrint('╠═══════════════════════════════════════╣');
      debugPrint('║ Name: $name');
      debugPrint('║ Members: ${memberIds.length}');
      debugPrint('║ Created by: $createdBy');

      final response = await http.post(
        Uri.parse('$baseUrl/api/conversations/group'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'memberIds': memberIds,
          'createdBy': createdBy,
          'avatar': avatar,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('║ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final conversation = data['conversation'];
          debugPrint('║ ✅ Group created successfully!');
          debugPrint('║ Group ID: ${conversation['id']}');
          debugPrint('╚═══════════════════════════════════════╝');

          return {
            'success': true,
            'conversationId': conversation['id'],
            'conversation': conversation,
          };
        } else {
          throw Exception(data['error'] ?? 'Failed to create group');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('❌ Timeout creating group');
      throw Exception('Connection timeout');
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      rethrow;
    }
  }

  /// Lấy danh sách groups của user
  static Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    try {
      debugPrint('🔍 Getting groups for user: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/conversations/groups/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final groups = List<Map<String, dynamic>>.from(data['groups'] ?? []);
          debugPrint('✅ Found ${groups.length} groups');
          return groups;
        }
      }

      return [];
    } on TimeoutException {
      debugPrint('❌ Timeout getting groups');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting groups: $e');
      return [];
    }
  }

  /// Lấy chi tiết conversation (group hoặc direct)
  static Future<Map<String, dynamic>?> getConversationDetails(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/conversations/$conversationId/details'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data['conversation'];
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting conversation details: $e');
      return null;
    }
  }

  /// Thêm thành viên vào group
  static Future<bool> addMembers({
    required String conversationId,
    required List<String> memberIds,
  }) async {
    try {
      debugPrint('➕ Adding ${memberIds.length} members to group: $conversationId');

      final response = await http.post(
        Uri.parse('$baseUrl/api/conversations/$conversationId/members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'memberIds': memberIds}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error adding members: $e');
      return false;
    }
  }

  /// Xóa thành viên khỏi group
  static Future<bool> removeMember({
    required String conversationId,
    required String memberId,
  }) async {
    try {
      debugPrint('➖ Removing member $memberId from group: $conversationId');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/conversations/$conversationId/members/$memberId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      return false;
    }
  }

  /// Cập nhật tên group
  static Future<bool> updateGroupName({
    required String conversationId,
    required String newName,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/conversations/$conversationId/name'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': newName}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error updating group name: $e');
      return false;
    }
  }

  /// ✅ XÓA GROUP - THÊM METHOD NÀY
  static Future<bool> deleteGroup(String conversationId) async {
    try {
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ 🗑️  DELETING GROUP                    ║');
      debugPrint('║ Group ID: $conversationId');
      debugPrint('╚═══════════════════════════════════════╝');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/conversations/$conversationId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('📩 Delete group response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Group deleted successfully from backend');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ Group not found (already deleted?)');
        return true; // Coi như thành công vì group đã không còn
      } else {
        debugPrint('⚠️ Failed to delete group: ${response.body}');
        return false;
      }
    } on TimeoutException {
      debugPrint('❌ Timeout deleting group');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      return false;
    }
  }
}