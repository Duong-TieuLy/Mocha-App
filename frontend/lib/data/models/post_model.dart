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
    final postData = json['post'] ?? json;

    return Post(
      id: postData['id'] ?? 0,
      firebaseUid: postData['firebaseUid'] ?? '',
      content: postData['content'] ?? '',
      images: postData['images'],
      likeCount: postData['likeCount'] ?? 0,
      createdAt: DateTime.tryParse(postData['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firebaseUid': firebaseUid,
    'image': images,
    'caption': content,
    'likes': likeCount
  };
}
