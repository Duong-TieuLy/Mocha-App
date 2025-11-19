import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/auth_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8000/api/auth';
  final String notificationBaseUrl = 'http://10.0.2.2:8085/api/notification';
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<AuthModel> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user == null) throw Exception("Firebase user null");

    final idToken = await user.getIdToken();
    if (idToken!.isEmpty) throw Exception("ID token empty");

    // Verify token với backend
    final authUser = await _verifyToken(idToken);

    // Lưu auth token + uid
    await _saveAuth(idToken, user.uid);

    // Lấy FCM token của thiết bị
    final fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      // Gửi FCM token lên backend
      await _saveFcmToken(user.uid, fcmToken);
    }

    return authUser;
  }
  // ================= SIGNUP =================
  Future<AuthModel> signup({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'displayName': displayName.isNotEmpty ? displayName : null,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Signup failed: ${response.body}');
      }

      final data = jsonDecode(response.body);

      // Backend phải trả về:
      // {
      //   "uid": "...",
      //   "email": "...",
      //   "displayName": "...",
      //   "token": "JWT/Firebase Custom Token"
      // }

      final authUser = AuthModel.fromJson(data);
      print(authUser);
      // 🔹 Lưu token & UID từ backend
      await _saveAuth(data["token"], data["uid"]);

      // 🔹 Lấy FCM token và gửi về backend
      final fcmToken = await _messaging.getToken();
      print("FCM token: $fcmToken");
      if (fcmToken != null) {
        await _saveFcmToken(data["uid"], fcmToken);
      }
      return authUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthModel> _verifyToken(String idToken) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verifyToken"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AuthModel.fromJson(data);
    } else {
      throw Exception('AuthService error: ${response.body}');
    }
  }

  Future<void> _saveAuth(String token, String uid) async {
    await _storage.write(key: 'idToken', value: token);
    await _storage.write(key: 'uid', value: uid);
  }

  Future<void> _saveFcmToken(String uid, String fcmToken) async {
    print('Saving FCM token for uid=$uid, token=$fcmToken');
    try {
      final response = await http.post(
        Uri.parse('$notificationBaseUrl/save-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebaseUid': uid, 'fcmToken': fcmToken}),
      );
      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode != 200) {
        print('FCM token not saved: ${response.body}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<String?> getToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No Firebase user logged in");

    if (forceRefresh) {
      final idToken = await user.getIdToken(true);
      await _storage.write(key: 'idToken', value: idToken);
      return idToken;
    }

    final token = await _storage.read(key: 'idToken');
    if (token == null || token.isEmpty) throw Exception("Token not found");
    return token;
  }

  Future<String> getUid() async {
    final uid = await _storage.read(key: 'uid');
    if (uid == null || uid.isEmpty) throw Exception("UID not found");
    return uid;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _storage.delete(key: 'idToken');
    await _storage.delete(key: 'uid');
  }
}
