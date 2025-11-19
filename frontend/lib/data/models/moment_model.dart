class Moment {
  final int id;
  final String firebaseUid;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  Moment({
    required this.id,
    required this.firebaseUid,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      imageUrl: json['imageUrl'],
      caption: json['caption'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}