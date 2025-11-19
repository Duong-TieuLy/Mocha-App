class FcmToken {
  final String firebaseUid;
  final String token;

  FcmToken({required this.firebaseUid, required this.token});

  Map<String, dynamic> toJson() => {
    'firebaseUid': firebaseUid,
    'fcmToken': token,
  };
}
