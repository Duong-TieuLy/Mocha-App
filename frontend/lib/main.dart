import 'package:flutter/material.dart';
import 'package:frontend/presentation/view_models/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/repositories/user_repository.dart';
import 'data/services/user_service.dart';
import 'firebase_options.dart';

// 🟢 Import các view model
import 'presentation/view_models/auth_view_model.dart';

// 🟢 Import các màn
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/signup_screen.dart';
import 'presentation/screens/congratulations_screen.dart';
import 'presentation/screens/complete_profile_screen.dart';
import 'presentation/screens/upload_photo_screen.dart';
import 'presentation/screens/explore_screen.dart';
import 'presentation/screens/moments_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'chat/chat_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        // Add các ViewModel khác nếu cần
        ChangeNotifierProvider(create: (_) => UserViewModel(repository: UserRepository(userService: UserService(baseUrl: 'http://10.0.2.2:8000')))),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mocha App',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: Colors.white,
          colorSchemeSeed: Colors.blue,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/congratulations': (context) => const CongratulationsScreen(),
          '/complete-profile': (context) => const CompleteProfileScreen(),
          '/upload-photo': (context) => const UploadPhotoScreen(),
          '/home': (context) => const MainPage(),
          '/chat': (context) => const ChatListScreen(),
          '/moment': (context) => const MomentsPage(),
          '/profile': (context) => const ProfilePage(),
          '/explore': (context) => const ExplorePage(),
        },
      ),
    );
  }
}

// 🟡 Thanh điều hướng chính
class MainPage extends StatefulWidget {
  final String? currentUserId; // ⭐ Thêm currentUserId

  const MainPage({
    super.key,
    this.currentUserId,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ⭐ Truyền currentUserId vào ChatListScreen
    final List<Widget> pages = [
      const MomentsPage(),
      ChatListScreen(currentUserId: widget.currentUserId),
      const ExplorePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
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
      onPressed: () => setState(() => _currentIndex = index),
    );
  }
}