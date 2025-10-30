import 'package:flutter/material.dart';

// 🟢 Import 3 màn mới
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/signup_screen.dart';

// 🟣 Import các màn khác
import 'presentation/screens/congratulations_screen.dart';
import 'presentation/screens/complete_profile_screen.dart';
import 'presentation/screens/upload_photo_screen.dart';
import 'package:frontend/presentation/screens/explore_screen.dart';
import 'package:frontend/presentation/screens/moments_screen.dart';
import 'package:frontend/presentation/screens/profile_screen.dart';
import 'chat/chat_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mocha App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorSchemeSeed: Colors.blue,
      ),

      // 🔹 Đặt màn hình khởi đầu
      initialRoute: '/splash',

      // 🔹 Đăng ký tất cả route của app
      routes: {
        // 👉 3 màn mới
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),

        // 👉 Các màn có sẵn
        '/congratulations': (context) => const CongratulationsScreen(),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/upload-photo': (context) => const UploadPhotoScreen(),
        '/home': (context) => const MainPage(),
        '/chat': (context) => const ChatListScreen(),
        '/moment': (context) => const MomentsPage(),
        '/profile': (context) => const ProfilePage(),
        '/explore': (context) => const ExplorePage(),
      },
    );
  }
}

// 🟡 Thanh điều hướng chính
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MomentsPage(),
    ChatListScreen(),
    ExplorePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 70,
        color: Colors.white,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomIcon(Icons.home_outlined, 0),
            _buildBottomIcon(Icons.chat_bubble_outline_outlined, 1),
            _buildBottomIcon(Icons.grid_view_outlined, 2),
            _buildBottomIcon(Icons.person_2_outlined, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, int index) {
    final bool isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        size: 32,
        color: isSelected ? Colors.blue : Colors.grey[500],
      ),
      onPressed: () {
        setState(() => _currentIndex = index);
      },
    );
  }
}
