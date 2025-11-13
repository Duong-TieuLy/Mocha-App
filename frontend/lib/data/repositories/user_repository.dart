import 'package:frontend/data/services/user_service.dart';

import '../models/user_profile.dart';

class UserRepository {
  final UserService userService;

  UserRepository({required this.userService});
  Future<UserProfile?> getProfile(String uid) async {
    print('Calling fetchProfile for UID: $uid');
    final data = await userService.fetchProfile(uid);
    print('Profile JSON: $data');
    if (data != null) return UserProfile.fromJson(data);
    return null;
  }
}