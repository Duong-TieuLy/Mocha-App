class AuthModel {
  final String uid;
  final String email;
  final String displayName;
  final String token;

  AuthModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.token,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      token: json['token'] ?? '',
    );
  }
  @override
  String toString() {
    return 'AuthModel(uid: $uid, email: $email, displayName: $displayName, token: $token)';
  }
}
