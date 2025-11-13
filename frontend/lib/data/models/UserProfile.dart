class UserProfile {
  final int id;
  final String firebaseUid;
  final String fullName;
  final String bio;
  final String interests;
  final String photoUrl;
  final int followersCount;
  final int followingCount;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.fullName,
    required this.bio,
    required this.interests,
    required this.photoUrl,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      fullName: json['fullName'],
      bio: json['bio'] ?? '',
      interests: json['interests'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
