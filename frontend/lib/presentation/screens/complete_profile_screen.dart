import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/presentation/view_models/user_view_model.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/user_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final interestController = TextEditingController();

  User? _user;

  @override
  void initState() {
    super.initState();

    // Chạy sau frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _user = currentUser; // cập nhật user
        });

        // Load profile sau khi đã có user
        final vm = Provider.of<UserViewModel>(context, listen: false);
        await vm.loadProfile(currentUser.uid);
        print('Profile loaded: ${vm.profile}');
      } else {
        print('User is null');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = _user!.uid;

    return Scaffold(
      body: Stack(
        children: [
          // Ví dụ các CircleAvatar như UI cũ
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Complete Profile",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Let's get to know you better!",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 40),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    decoration: InputDecoration(
                      hintText: 'Write a short bio...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: interestController,
                    decoration: InputDecoration(
                      hintText: 'Interests',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      final updateData = <String, dynamic>{
                        'fullName': nameController.text.trim(),
                        'bio': bioController.text.trim(),
                        'interests': interestController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                      };

                      try {
                        await UserViewModel(
                          repository: UserRepository(
                            userService: UserService(baseUrl: 'http://10.0.2.2:8000'),
                          ),
                        ).updateProfile(uid, updateData);

                        Navigator.pushNamed(context, '/upload-photo');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating profile: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
                    ),
                    child: const Text("Next", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    child: const Text(
                      "Skip for now",
                      style: TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget build(BuildContext context) {
//   final nameController = TextEditingController();
//   final bioController = TextEditingController();
//   final interestController = TextEditingController();
//
//   return Scaffold(
//     body: Stack(
//       children: [
//         const Positioned(
//           top: -60,
//           right: -60,
//           child: CircleAvatar(radius: 100, backgroundColor: Color(0xFF2196F3)),
//         ),
//         const Positioned(
//           bottom: -60,
//           right: -40,
//           child: CircleAvatar(radius: 80, backgroundColor: Color(0xFF2196F3)),
//         ),
//         const Positioned(
//           left: -40,
//           bottom: 150,
//           child: CircleAvatar(radius: 60, backgroundColor: Color(0xFF2196F3)),
//         ),
//         SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const Text(
//                   "Complete Profile",
//                   style: TextStyle(
//                       fontSize: 26, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text("Let's get to know you better!",
//                     style: TextStyle(fontSize: 16)),
//                 const SizedBox(height: 40),
//                 TextField(
//                   controller: nameController,
//                   decoration: InputDecoration(
//                     hintText: 'Full Name',
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8)),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: bioController,
//                   decoration: InputDecoration(
//                     hintText: 'Write a short bio...',
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8)),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: interestController,
//                   decoration: InputDecoration(
//                     hintText: 'Interests',
//                     border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8)),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final uid = FirebaseAuth.instance.currentUser?.uid;
//                     if (uid == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('User not logged in')),
//                       );
//                       return;
//                     }
//
//                     final updateData = <String, dynamic>{
//                       'fullName': nameController.text.trim(),
//                       'bio': bioController.text.trim(),
//                       'interests': interestController.text
//                           .split(',')
//                           .map((e) => e.trim())
//                           .where((e) => e.isNotEmpty)
//                           .toList(),
//                     };
//
//                     try {
//                       // Using UserViewModel to update profile
//                       await UserViewModel(repository: UserRepository(
//                           userService:
//                           UserService(baseUrl: 'http://10.0.2.2:8000'))).updateProfile(uid, updateData);
//                       // Navigate to next screen, e.g., upload photo
//                       Navigator.pushNamed(context, '/upload-photo');
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Error updating profile: $e')),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF2196F3),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 14),
//                   ),
//                   child: const Text("Next", style: TextStyle(fontSize: 16)),
//                 ),
//
//                 const SizedBox(height: 12),
//                 TextButton(onPressed: ()=> Navigator.pushNamed(context, '/home'),
//                   child: const Text("Skip for now",
//                     style: TextStyle(
//                         color: Colors.black54,
//                         fontStyle: FontStyle.italic
//                     )
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }