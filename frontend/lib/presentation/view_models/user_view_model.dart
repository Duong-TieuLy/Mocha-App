import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';


class UserViewModel extends ChangeNotifier {
  final UserRepository repository;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserViewModel({required this.repository});

  Future<void> loadProfile(String uid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await repository.getProfile(uid);
      if (result != null) {
        _profile = result;
      } else {
        _error = 'User not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
