import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fcm_token.dart';

class NotificationService {
  final String baseUrl;

  NotificationService({required this.baseUrl});

  /// Lưu FCM token lên backend
  Future<bool> saveToken(FcmToken token) async {
    final url = Uri.parse('$baseUrl/api/notification/save-token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(token.toJson()),
    );

    return response.statusCode == 200;
  }

  /// Gửi notification (chỉ backend mới dùng)
  Future<bool> sendNotification({
    required String firebaseUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final url = Uri.parse('$baseUrl/api/notification/send');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebaseUid': firebaseUid,
        'title': title,
        'body': body,
        'data': data,
      }),
    );

    return response.statusCode == 200;
  }
}
