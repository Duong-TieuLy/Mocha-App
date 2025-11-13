import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/auth_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8000/api/auth';

  /// 🔹 Login Firebase + verify backend
  Future<AuthModel> login(String email, String password) async {
    // 1️⃣ Firebase login
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) throw Exception("Firebase user null");

    // 2️⃣ Get ID token
    final idToken = await user.getIdToken();
    if (idToken!.isEmpty) throw Exception("ID token empty");
    print(idToken);

    // 3️⃣ Verify token backend
    final authUser = await _verifyToken(idToken);

    // 4️⃣ Save token
    await _saveToken(idToken);

    return authUser;
  }

  /// 🔹 Verify token via backend
  Future<AuthModel> _verifyToken(String idToken) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verifyToken"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) throw Exception("Backend returned null");
      return AuthModel.fromJson(data);
    } else {
      throw Exception('AuthService error: ${response.body}');
    }
  }

  /// 🔹 Save token securely
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'idToken', value: token);
  }

  /// 🔹 Get token for API
  Future<String> getToken() async {
    final token = await _storage.read(key: 'idToken');
    if (token == null || token.isEmpty) throw Exception("Token not found");
    return token;
  }

  /// 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _storage.delete(key: 'idToken');
  }
}
