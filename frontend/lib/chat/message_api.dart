import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MessageApi {
  static const String baseUrl = 'http://localhost:8081/api';

  // ═══════════════════════════════════════════════════════════════
  // 📤 SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════
  /// Send a message. Returns normalized map:
  /// { 'success': bool, 'tempId': String?, 'message': Map<String,dynamic>?, 'error': String? }
  static Future<Map<String, dynamic>> sendMessage(
      Map<String, dynamic> data, {
        String? tempId,
        Map<String, String>? extraHeaders,
      }) async {
    final url = Uri.parse('$baseUrl/messages');

    final requestBody = {
      'conversationId': data['conversationId'],
      'senderId': data['sender'] ?? data['senderId'],
      'content': data['message'] ?? data['content'],
      'type': data['type'] ?? 'text',
    };

    try {
      debugPrint("📤 Sending message to: $url");
      debugPrint("📦 Request body: ${jsonEncode(requestBody)}");

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (tempId != null) 'x-temp-id': tempId,
      };
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout'),
      );

      debugPrint("📩 Response status: ${response.statusCode}");
      debugPrint("📨 Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);

        Map<String, dynamic>? savedMessage;
        String? returnedTempId;

        if (body is Map && body.containsKey('message')) {
          savedMessage = Map<String, dynamic>.from(body['message'] as Map);
          returnedTempId = body['tempId']?.toString();
        } else if (body is Map && body.containsKey('id')) {
          // server returned message directly
          savedMessage = Map<String, dynamic>.from(body);
          returnedTempId = tempId;
        } else {
          // unexpected shape
          debugPrint('⚠️ Unexpected send response format: $body');
        }

        return {
          'success': true,
          'tempId': returnedTempId ?? tempId,
          'message': savedMessage,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e, st) {
      debugPrint("❌ Error sending message: $e\n$st");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📥 GET MESSAGES
  // ═══════════════════════════════════════════════════════════════
  /// Get full message history for a conversation (path param).
  /// Accepts optional headers so you can forward Authorization tokens from the app.
  static Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    Map<String, String>? extraHeaders,
  }) async {
    final url = Uri.parse('$baseUrl/messages/history/$conversationId');
    try {
      debugPrint("📥 Fetching messages from: $url");

      final headers = {'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint("📩 Response status: ${response.statusCode}");
      debugPrint("📨 Response body: ${response.body}");

      // ⭐ Handle 404 as empty conversation (not an error)
      if (response.statusCode == 404) {
        debugPrint("ℹ️  No messages found for conversation (404) - returning empty list");
        return [];
      }

      if (response.statusCode != 200) {
        debugPrint(
            "❌ Error fetching messages: ${response.statusCode}: ${response.body}");
        return [];
      }

      final decoded = jsonDecode(response.body);

      // If API returns a list of messages directly.
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      // If API returns a map/wrapper, detect common wrapper keys.
      if (decoded is Map) {
        // Common wrapper keys that hold arrays
        final List candidates = [];
        if (decoded['data'] is List) {
          candidates.addAll(decoded['data'] as List);
        } else if (decoded['messages'] is List) {
          candidates.addAll(decoded['messages'] as List);
        } else if (decoded['result'] is List) {
          candidates.addAll(decoded['result'] as List);
        } else if (decoded['rows'] is List) {
          candidates.addAll(decoded['rows'] as List);
        } else if (decoded['message'] is List) {
          candidates.addAll(decoded['message'] as List);
        }

        if (candidates.isNotEmpty) {
          return candidates
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        // If the API returned a single message object in 'message' or directly
        if (decoded['message'] is Map) {
          return [Map<String, dynamic>.from(decoded['message'] as Map)];
        }

        // If map looks like a single message
        if (decoded.containsKey('id') &&
            (decoded.containsKey('content') ||
                decoded.containsKey('text') ||
                decoded.containsKey('body') ||
                decoded.containsKey('message'))) {
          return [Map<String, dynamic>.from(decoded)];
        }

        // Unknown wrapper - log keys for debugging and return empty list
        debugPrint('⚠️ getMessages: unknown response shape, keys: ${decoded.keys}');
        return [];
      }

      debugPrint('⚠️ getMessages: unexpected decoded type: ${decoded.runtimeType}');
      return [];
    } catch (e, st) {
      debugPrint("❌ Error fetching messages: $e\n$st");
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ⌨️ TYPING STATUS
  // ═══════════════════════════════════════════════════════════════
  static Future<void> sendTypingStatus(
      String conversationId,
      String userId,
      bool isTyping,
      ) async {
    try {
      await http
          .post(
        Uri.parse('$baseUrl/conversations/$conversationId/typing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'isTyping': isTyping}),
      )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⚠️ Error sending typing status: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🆕 GET USER CONVERSATIONS - ⭐ FIXED: Handle 404 as empty list
  // ═══════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getUserConversations(
      String userId, {
        Map<String, String>? extraHeaders,
      }) async {
    final url = Uri.parse('$baseUrl/conversations/$userId');
    try {
      debugPrint('🔍 Fetching conversations for user: $userId from $url');

      final headers = {'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');

      // ⭐ Handle 404 as "no conversations yet" (not an error)
      if (response.statusCode == 404) {
        debugPrint('ℹ️  No conversations found for user (404) - returning empty list');
        return [];
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Error fetching conversations: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body);

      // Handle different response formats
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      if (decoded is Map) {
        // Check for common wrapper keys
        if (decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        if (decoded['conversations'] is List) {
          return (decoded['conversations'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        debugPrint(
            '⚠️ getUserConversations: unknown response shape, keys: ${decoded.keys}');
        return [];
      }

      debugPrint(
          '⚠️ getUserConversations: unexpected type: ${decoded.runtimeType}');
      return [];
    } catch (e, st) {
      debugPrint('❌ Error fetching conversations: $e\n$st');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗑️ DELETE CONVERSATION - ⭐ NEW
  // ═══════════════════════════════════════════════════════════════
  /// Delete a conversation and all its messages
  static Future<bool> deleteConversation(
      String conversationId, {
        Map<String, String>? extraHeaders,
      }) async {
    final url = Uri.parse('$baseUrl/conversations/$conversationId');
    try {
      debugPrint('🗑️ Deleting conversation: $conversationId');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');

      // Success status codes for DELETE
      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        debugPrint('✅ Conversation deleted successfully: $conversationId');
        return true;
      }

      // 404 means already deleted or never existed
      if (response.statusCode == 404) {
        debugPrint('⚠️ Conversation not found (404) - treating as success');
        return true;
      }

      debugPrint('❌ Failed to delete conversation: ${response.statusCode}');
      return false;
    } catch (e, st) {
      debugPrint('❌ Error deleting conversation: $e\n$st');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗑️ DELETE ALL MESSAGES IN CONVERSATION - ⭐ ALTERNATIVE
  // ═══════════════════════════════════════════════════════════════
  /// Delete all messages in a conversation (if backend doesn't support conversation delete)
  static Future<bool> deleteAllMessages(
      String conversationId, {
        Map<String, String>? extraHeaders,
      }) async {
    final url = Uri.parse('$baseUrl/messages/conversation/$conversationId');
    try {
      debugPrint('🗑️ Deleting all messages in conversation: $conversationId');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202 ||
          response.statusCode == 404) {
        debugPrint('✅ Messages deleted successfully');
        return true;
      }

      debugPrint('❌ Failed to delete messages: ${response.statusCode}');
      return false;
    } catch (e, st) {
      debugPrint('❌ Error deleting messages: $e\n$st');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🆕 CREATE CONVERSATION
  // ═══════════════════════════════════════════════════════════════
  static Future<String?> createConversation({
    required String userId1,
    required String userId2,
    Map<String, String>? extraHeaders,
  }) async {
    final url = Uri.parse('$baseUrl/conversations');
    try {
      debugPrint('🆕 Creating conversation between $userId1 and $userId2');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode({
          'participants': [userId1, userId2],
        }),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Handle different response formats
        if (data is Map) {
          final conversationId =
              data['conversationId'] ?? data['id'] ?? data['conversation_id'];
          if (conversationId != null) {
            debugPrint('✅ Conversation created: $conversationId');
            return conversationId.toString();
          }
        }

        debugPrint('⚠️ createConversation: conversationId not found in response');
        return null;
      }

      debugPrint('❌ Failed to create conversation: ${response.statusCode}');
      return null;
    } catch (e, st) {
      debugPrint('❌ Error creating conversation: $e\n$st');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🆕 GET ALL USERS
  // ═══════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getAllUsers({
    String? searchQuery,
    Map<String, String>? extraHeaders,
  }) async {
    var url = Uri.parse('$baseUrl/users');
    if (searchQuery != null && searchQuery.isNotEmpty) {
      url = Uri.parse('$baseUrl/users?search=$searchQuery');
    }

    try {
      debugPrint('🔍 Fetching users from: $url');

      final headers = {'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ Error fetching users: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      if (decoded is Map) {
        if (decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        if (decoded['users'] is List) {
          return (decoded['users'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }

        debugPrint('⚠️ getAllUsers: unknown response shape, keys: ${decoded.keys}');
        return [];
      }

      debugPrint('⚠️ getAllUsers: unexpected type: ${decoded.runtimeType}');
      return [];
    } catch (e, st) {
      debugPrint('❌ Error fetching users: $e\n$st');
      return [];
    }
  }
}