class AuthModel {
  final String uid;
  final String email;
  final String displayName;

  AuthModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
    );
  }
}
