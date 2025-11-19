import 'package:flutter/material.dart';
import '../../data/models/auth_model.dart';
import '../../data/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool isLoading = false;
  String? errorMessage;
  AuthModel? currentUser;

  /// 🔹 Login
  Future<void> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _service.login(email, password);
      if (currentUser == null) {
        errorMessage = "Backend returned empty user";
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  /// Signup
  Future<void> signup({
    required String email,
    required String confirmPassword,
    required String password,
    required String displayName,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _service.signup(
        email: email,
        password: password,
        displayName: displayName,
        confirmPassword: confirmPassword,
      );

      if (currentUser == null) {
        errorMessage = "Signup successful but user is null.";
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  /// 🔹 Logout
  Future<void> logout() async {
    await _service.logout();
    currentUser = null;
    notifyListeners();
  }

  /// 🔹 Get token for API requests
  Future<String?> getToken() async {
    try {
      return await _service.getToken();
    } catch (e) {
      print("Get token error: $e");
      return null;
    }
  }
}
