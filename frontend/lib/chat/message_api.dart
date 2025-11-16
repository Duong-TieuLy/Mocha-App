import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser; // ✅ ADD THIS
import 'package:flutter/foundation.dart';

class MessageApi {
  static const String baseUrl = 'http://localhost:8081/api';

  // ═══════════════════════════════════════════════════════════════
  // 📤 SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════
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
          savedMessage = Map<String, dynamic>.from(body);
          returnedTempId = tempId;
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
  // 🛠️ HELPER: Detect image MIME type from filename
  // ═══════════════════════════════════════════════════════════════
  static http_parser.MediaType _getImageContentType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return http_parser.MediaType('image', 'jpeg');
      case 'png':
        return http_parser.MediaType('image', 'png');
      case 'gif':
        return http_parser.MediaType('image', 'gif');
      case 'webp':
        return http_parser.MediaType('image', 'webp');
      case 'bmp':
        return http_parser.MediaType('image', 'bmp');
      default:
        return http_parser.MediaType('image', 'jpeg'); // Default to JPEG
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📷 SEND IMAGE MESSAGE - ⭐ FIXED: Changed 'image' to 'file'
  // ═══════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> sendImageMessage({
    required String conversationId,
    required String senderId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    String? tempId,
    Map<String, String>? extraHeaders,
  }) async {
    final url = Uri.parse('$baseUrl/messages/image');

    try {
      debugPrint("📤 Uploading image to: $url");
      debugPrint("🌐 Platform: ${kIsWeb ? 'Web' : 'Mobile'}");

      final request = http.MultipartRequest('POST', url);

      // Add headers
      final headers = {
        'Accept': 'application/json',
        if (tempId != null) 'x-temp-id': tempId,
      };
      if (extraHeaders != null) headers.addAll(extraHeaders);
      request.headers.addAll(headers);

      // Add fields
      request.fields['conversationId'] = conversationId;
      request.fields['senderId'] = senderId;

      // ⭐ Add file - DIFFERENT FOR WEB AND MOBILE
      http.MultipartFile multipartFile;

      if (kIsWeb) {
        // ✅ FLUTTER WEB - Use bytes
        if (imageBytes == null) {
          throw Exception('imageBytes is required for web platform');
        }

        final name = fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';

        multipartFile = http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: name,
          contentType: _getImageContentType(name), // ✅ Auto-detect content type
        );

        debugPrint("📦 Uploading from bytes: $name (${imageBytes.length} bytes)");
      } else {
        // ✅ MOBILE - Use File
        if (imageFile == null) {
          throw Exception('imageFile is required for mobile platform');
        }

        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();

        multipartFile = http.MultipartFile(
          'file',  // ✅ FIXED: Changed from 'image' to 'file'
          fileStream,
          fileLength,
          filename: imageFile.path.split('/').last,
        );

        debugPrint("📦 Uploading file: ${multipartFile.filename} ($fileLength bytes)");
      }

      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Upload timeout'),
      );

      final response = await http.Response.fromStream(streamedResponse);

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
          savedMessage = Map<String, dynamic>.from(body);
          returnedTempId = tempId;
        }

        return {
          'success': true,
          'tempId': returnedTempId ?? tempId,
          'message': savedMessage,
          'imageUrl': body['imageUrl'],  // ✅ Include imageUrl from response
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e, st) {
      debugPrint("❌ Error uploading image: $e\n$st");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📥 GET MESSAGES
  // ═══════════════════════════════════════════════════════════════
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

      if (response.statusCode == 404) {
        debugPrint("ℹ️  No messages found for conversation (404) - returning empty list");
        return [];
      }

      if (response.statusCode != 200) {
        debugPrint("❌ Error fetching messages: ${response.statusCode}: ${response.body}");
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      if (decoded is Map) {
        final List candidates = [];
        if (decoded['data'] is List) {
          candidates.addAll(decoded['data'] as List);
        } else if (decoded['messages'] is List) {
          candidates.addAll(decoded['messages'] as List);
        } else if (decoded['result'] is List) {
          candidates.addAll(decoded['result'] as List);
        }

        if (candidates.isNotEmpty) {
          return candidates.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        if (decoded['message'] is Map) {
          return [Map<String, dynamic>.from(decoded['message'] as Map)];
        }

        if (decoded.containsKey('id') && (decoded.containsKey('content') || decoded.containsKey('text'))) {
          return [Map<String, dynamic>.from(decoded)];
        }

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
  // 🗑️ DELETE MESSAGE
  // ═══════════════════════════════════════════════════════════════
  static Future<bool> deleteMessage(String messageId, {Map<String, String>? extraHeaders}) async {
    final url = Uri.parse('$baseUrl/messages/$messageId');

    try {
      debugPrint('🗑️ Deleting message locally: $messageId');

      final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202 || response.statusCode == 404) {
        debugPrint('✅ Message deleted successfully: $messageId');
        return true;
      }

      debugPrint('❌ Failed to delete message: ${response.statusCode}');
      return false;
    } catch (e, st) {
      debugPrint('❌ Error deleting message: $e\n$st');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📵 RECALL MESSAGE
  // ═══════════════════════════════════════════════════════════════
  static Future<bool> recallMessage(String messageId, {Map<String, String>? extraHeaders}) async {
    final url = Uri.parse('$baseUrl/messages/$messageId/recall');

    try {
      debugPrint('📵 Recalling message: $messageId');

      final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Message recalled successfully: $messageId');
        return true;
      }

      debugPrint('❌ Failed to recall message: ${response.statusCode}');
      return false;
    } catch (e, st) {
      debugPrint('❌ Error recalling message: $e\n$st');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ⌨️ TYPING STATUS
  // ═══════════════════════════════════════════════════════════════
  static Future<void> sendTypingStatus(String conversationId, String userId, bool isTyping) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/typing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'isTyping': isTyping}),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⚠️ Error sending typing status: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🆕 GET USER CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getUserConversations(String userId, {Map<String, String>? extraHeaders}) async {
    final url = Uri.parse('$baseUrl/conversations/$userId');
    try {
      debugPrint('🔍 Fetching conversations for user: $userId from $url');

      final headers = {'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        debugPrint('ℹ️  No conversations found for user (404) - returning empty list');
        return [];
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Error fetching conversations: ${response.statusCode}');
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      if (decoded is Map) {
        if (decoded['data'] is List) {
          return (decoded['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        if (decoded['conversations'] is List) {
          return (decoded['conversations'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        debugPrint('⚠️ getUserConversations: unknown response shape, keys: ${decoded.keys}');
        return [];
      }

      debugPrint('⚠️ getUserConversations: unexpected type: ${decoded.runtimeType}');
      return [];
    } catch (e, st) {
      debugPrint('❌ Error fetching conversations: $e\n$st');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗑️ DELETE ALL MESSAGES
  // ═══════════════════════════════════════════════════════════════
  static Future<bool> deleteAllMessages(String conversationId, {Map<String, String>? extraHeaders}) async {
    final url = Uri.parse('$baseUrl/messages/conversation/$conversationId');
    try {
      debugPrint('🗑️ Deleting all messages in conversation: $conversationId');

      final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202 || response.statusCode == 404) {
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
  // 🚫 BLOCK USER
  // ═══════════════════════════════════════════════════════════════
  static Future<bool> blockUser(String userId, String blockedUserId, {Map<String, String>? extraHeaders}) async {
    final url = Uri.parse('$baseUrl/users/$userId/block?blockedUserId=$blockedUserId');

    try {
      debugPrint('🚫 Blocking user $blockedUserId for user $userId');

      final headers = {'Accept': 'application/json'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 10));

      debugPrint('📩 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ User blocked successfully');
        return true;
      }

      debugPrint('❌ Failed to block user: ${response.statusCode}');
      return false;
    } catch (e, st) {
      debugPrint('❌ Error blocking user: $e\n$st');
      return false;
    }
  }
}