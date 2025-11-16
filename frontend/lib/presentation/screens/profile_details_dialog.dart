import 'package:flutter/material.dart';
import '../../data/models/user_profile.dart';
import '../view_models/user_view_model.dart';
import 'update_profile_dialog.dart';

class ProfileDetailsDialog {
  static void show(
      BuildContext context,
      UserProfile profile,
      UserViewModel vm, {
        required bool isCurrentUser, // 👉 Thêm biến kiểm tra
      }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Personal Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatarRow(profile.photoUrl),
                _infoRow("Full Name", profile.fullName),
                _infoRow("Bio", profile.bio),
                _infoRow("Interests", profile.interests.join(", ")),
                _infoRow("Location", profile.location ?? ""),
                _infoRow("Phone Number", profile.phoneNumber ?? ""),
                _infoRow("Gender", profile.gender?.name ?? ""),
                _infoRow(
                    "Date of Birth",
                    profile.dateOfBirth != null
                        ? "${profile.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}"
                        : ""),
              ],
            ),
          ),

          // 👉 Nếu không phải user đang đăng nhập → không hiện nút
          actions: isCurrentUser
              ? [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                UpdateProfileDialog.show(context, vm, profile);
              },
              child: const Text("Update Profile"),
            ),
          ]
              : null,
        );
      },
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  static Widget _avatarRow(String? photoUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/images/man.png') as ImageProvider,
            onBackgroundImageError: (exception, stackTrace) {
              print("Error loading avatar image: $exception");
            },
          ),
        ],
      ),
    );
  }
}
