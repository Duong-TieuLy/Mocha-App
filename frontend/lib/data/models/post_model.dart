class Post {
  final int? id;
  final String firebaseUid;
  final String content;
  final String? images;
  final int likeCount;
  final DateTime createdAt;

  // Thêm info người dùng
  final String? userName;
  final String? userPhotoUrl;

  Post({
    this.id,
    required this.firebaseUid,
    required this.content,
    this.images,
    required this.likeCount,
    required this.createdAt,
    this.userName,
    this.userPhotoUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'], // backend sẽ trả về id
      firebaseUid: json['firebaseUid'] ?? '',
      content: json['content'] ?? '',
      images: json['images'],
      likeCount: json['likeCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      userName: json['userName'],         // từ backend
      userPhotoUrl: json['userPhotoUrl'], // từ backend
    );
  }

  Map<String, dynamic> toJson() => {
    "firebaseUid": firebaseUid,
    "content": content,
    "images": images,
  };
}
