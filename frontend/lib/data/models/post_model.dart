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
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      content: json['content'],
      images: json['images'],
      likeCount: json['likeCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    "firebaseUid": firebaseUid,
    "content": content,
    "images": images,
  };
}
