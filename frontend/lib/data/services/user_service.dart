import 'dart:convert';
import 'package:frontend/data/services/auth_service.dart';
import 'package:http/http.dart' as http;

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
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }
}