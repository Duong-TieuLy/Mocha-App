enum Gender {
  male,
  female,
  other;

  static Gender? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'MALE':
        return Gender.male;
      case 'FEMALE':
        return Gender.female;
      case 'OTHER':
        return Gender.other;
      default:
        return null;
    }
  }

  String toJson() {
    return name.toUpperCase();
  }
}

class UserProfile {
  final int id; // thay long -> int
  final String firebaseUid;
  final String fullName;
  final String email;
  final String bio;
  final List<String> interests;
  final String photoUrl;
  final DateTime? dateOfBirth;
  final String? location;
  final Gender? gender;
  final String? phoneNumber;
  final int followersCount;
  final int followingCount;
  final String createdAt;

  UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.fullName,
    required this.bio,
    required this.interests,
    required this.email,
    required this.photoUrl,
    required this.dateOfBirth,
    required this.location,
    required this.gender,
    required this.phoneNumber,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
  });

  // factory UserProfile.fromJson(Map<String, dynamic> json) {
  //   return UserProfile(
  //     id: json['id'] as int,
  //     firebaseUid: json['firebaseUid'] as String,
  //     fullName: json['fullName'] as String? ?? '',
  //     email: json['email'] as String? ?? '',
  //     bio: json['bio'] as String? ?? '',
  //     interests: (json['interests'] as List<dynamic>?)
  //         ?.map((e) => e.toString())
  //         .toList() ?? [],
  //     photoUrl: json['photoUrl'] as String? ?? '',
  //     dateOfBirth: json['dateOfBirth'] != null
  //         ? DateTime.tryParse(json['dateOfBirth'].toString())
  //         : null,
  //     location: json['location'] as String?,
  //     gender: Gender.fromString(json['gender'] as String?),
  //     phoneNumber: json['phoneNumber'] as String?,
  //     followersCount: json['followersCount'] as int? ?? 0,
  //     followingCount: json['followingCount'] as int? ?? 0,
  //     createdAt: json['createdAt'] as String? ?? '',
  //   );
  // }
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      firebaseUid: json['firebaseUid'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photoUrl: json['photoUrl'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'].toString()) : null,
      location: json['location'] as String?,
      gender: Gender.fromString(json['gender'] as String?),
      phoneNumber: json['phoneNumber'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'interests': interests,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
      'gender': gender?.toJson(),
      'phoneNumber': phoneNumber,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    int? id, // thay long -> int
    String? firebaseUid,
    String? fullName,
    String? email,
    String? bio,
    List<String>? interests,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? location,
    Gender? gender,
    String? phoneNumber,
    int? followersCount,
    int? followingCount,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
