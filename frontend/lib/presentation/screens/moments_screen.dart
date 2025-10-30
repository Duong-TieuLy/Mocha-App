import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/post_card.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final PageController _pageController = PageController();
  final List<PostCard> friendMoments = [
    const PostCard(
      name: "Windchill",
      username: "@windchill",
      image: "https://picsum.photos/400",
      comments: 5,
      likes: 12,
    ),
    const PostCard(
      name: "Hana",
      username: "@hana",
      image: "https://picsum.photos/401",
      comments: 3,
      likes: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar cố định
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Moments",
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: const [
          Icon(Icons.search, color: Colors.black, size: 36),
          SizedBox(width: 16),
          Icon(Icons.notifications_none, color: Colors.black, size: 36),
          SizedBox(width: 16),
        ],
      ),

      // Nội dung có thể vuốt lên/xuống
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          // Trang 1 — Camera view
          _buildCameraView(screenHeight),

          // Trang 2 trở đi — Moments bạn bè
          for (var post in friendMoments) _buildMoment(post, screenHeight),
        ],
      ),
    );
  }

  /// CAMERA VIEW
  Widget _buildCameraView(double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: screenHeight * 0.45,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(40),
            border:
            Border.all(color: const Color.fromRGBO(121, 171, 222, 1), width: 3),
          ),
          child: const Center(
            child: Text(
              "No moments yet",
              style: TextStyle(color: Colors.black54, fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 40),
        _bottomBar(screenHeight),
      ],
    );
  }

  /// MỘT TRANG MOMENT CỦA BẠN BÈ
  Widget _buildMoment(PostCard post, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: screenHeight * 0.45,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(40),
            border:
            Border.all(color: const Color.fromRGBO(121, 171, 222, 1), width: 3),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(),
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 3),
                image: DecorationImage(
                  image: NetworkImage(post.image),
                  fit: BoxFit.cover,
                ),
              ),
            )
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// Thanh điều khiển bên dưới (chung cho cả camera & moments)
  Widget _bottomBar(double screenHeight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: Colors.white,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.flash_on_outlined, size: 45),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 45),
                onPressed: () {},
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, 20),
            child: SizedBox(
              width: 115,
              height: 115,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Colors.blue,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.camera, size: 70, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
