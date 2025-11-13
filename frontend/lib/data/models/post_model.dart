class Post {
  final int id;
  final String firebaseUid;
  final String content;
  final String? images;
  final int likeCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.firebaseUid,
    required this.content,
    this.images,
    required this.likeCount,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      firebaseUid: json['firebaseUid'] ?? '',
      content: json['content'] ?? '',
      images: json['images'],
      likeCount: json['likeCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    "firebaseUid": firebaseUid,
    "content": content,
    "images": images,
  };
}
