import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/auth_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8000/api/auth';

  Future<AuthModel> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user == null) throw Exception("Firebase user null");

    final idToken = await user.getIdToken();
    if (idToken!.isEmpty) throw Exception("ID token empty");

    final authUser = await _verifyToken(idToken);

    await _saveAuth(idToken, user.uid);

    return authUser;
  }

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

  Future<void> _saveAuth(String token, String uid) async {
    await _storage.write(key: 'idToken', value: token);
    await _storage.write(key: 'uid', value: uid);
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
