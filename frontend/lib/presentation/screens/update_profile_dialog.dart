import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/user_profile.dart';
import '../view_models/user_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateProfileDialog {
  static void show(BuildContext context, UserViewModel vm, UserProfile profile) {
    final fullNameController = TextEditingController(text: profile.fullName);
    final bioController = TextEditingController(text: profile.bio);
    final interestsController = TextEditingController(text: profile.interests.join(', '));
    final photoUrlController = TextEditingController(text: profile.photoUrl);
    final locationController = TextEditingController(text: profile.location ?? '');
    final phoneController = TextEditingController(text: profile.phoneNumber ?? '');

    Gender? selectedGender = profile.gender;
    DateTime? selectedDate = profile.dateOfBirth;

    XFile? selectedImageFile;

    Future<void> pickImage(Function() refreshUI) async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked != null) {
          selectedImageFile = picked;

          // Upload ngay khi chọn ảnh
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final url = await vm.repository.uploadProfileImage(File(selectedImageFile!.path));
            photoUrlController.text = url;
          }
          refreshUI(); // refresh avatar
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await pickImage(() => setState(() {}));
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: (photoUrlController.text.isNotEmpty)
                            ? NetworkImage(photoUrlController.text) as ImageProvider
                            : const AssetImage('assets/images/man.png'),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: interestsController,
                      decoration: const InputDecoration(
                        labelText: 'Interests',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Gender>(
                      value: selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Select gender'),
                        ),
                        ...Gender.values.map((gender) {
                          String label;
                          switch (gender) {
                            case Gender.male:
                              label = 'Male';
                              break;
                            case Gender.female:
                              label = 'Female';
                              break;
                            case Gender.other:
                              label = 'Other';
                              break;
                          }
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(label),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select date',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not logged in')),
                      );
                      return;
                    }

                    final updatedData = <String, dynamic>{
                      'fullName': fullNameController.text.trim(),
                      'bio': bioController.text.trim(),
                      'interests': interestsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      'photoUrl': photoUrlController.text.trim(),
                      'location': locationController.text.trim().isEmpty
                          ? null
                          : locationController.text.trim(),
                      'phoneNumber': phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      'gender': selectedGender?.toJson(),
                      'dateOfBirth': selectedDate?.toIso8601String(),
                    };

                    final success = await vm.updateProfile(uid, updatedData);

                    if (context.mounted) {
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully updated!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${vm.error ?? "Unknown error"}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
