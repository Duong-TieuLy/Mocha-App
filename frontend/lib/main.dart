import 'package:flutter/material.dart';
import 'presentation/screens/congratulations_screen.dart';
import 'presentation/screens/complete_profile_screen.dart';
import 'presentation/screens/upload_photo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ẩn dòng “debug” góc phải
      title: 'Onboarding Flow',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 👉 Đặt màn hình đầu tiên khi mở app
      initialRoute: '/',
      routes: {
        '/': (context) => const CongratulationsScreen(),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/upload-photo': (context) => const UploadPhotoScreen(),
      },
    );
  }
}
