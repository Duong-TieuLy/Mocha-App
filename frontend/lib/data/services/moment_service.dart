import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/moment_model.dart';
import 'auth_service.dart';

class MomentService {
  final String baseUrl;

  MomentService({required this.baseUrl});

  Future<List<Moment>> getFeed({required int page, required int size}) async {
    final token = await AuthService().getToken();
    final firebaseUid = await AuthService().getUid();

    final uri = Uri.parse("$baseUrl/api/moments/feed")
        .replace(queryParameters: {
      "page": "$page",
      "size": "$size",
    });

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "X-User-Id": firebaseUid!,
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      final List content = body["content"];
      return content.map((e) => Moment.fromJson(e)).toList();
    }

    throw Exception("Failed to load feed");
  }

  Future<Moment> createMoment({
    required String imageUrl,
    String? caption,
    List<String>? allowedUids,
  }) async {
    final token = await AuthService().getToken();
    final firebaseUid = await AuthService().getUid();

    final response = await http.post(
      Uri.parse("$baseUrl/api/moments/create"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "X-User-Id": firebaseUid!,
      },
      body: jsonEncode({
        "imageUrl": imageUrl,
        "caption": caption,
        "allowedUids": allowedUids,
      }),
    );

    if (response.statusCode == 200) {
      return Moment.fromJson(jsonDecode(response.body));
    }

    throw Exception("Failed to create moment");
  }
}
