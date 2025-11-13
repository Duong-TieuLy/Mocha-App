import 'package:flutter/material.dart';
import 'dart:io';  // Vẫn cần nếu dùng File ở đâu đó
import 'post_dialog.dart';  // Import file mới

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // Danh sách posts với dữ liệu ảo ban đầu (dùng Map thay vì class Post)
  List<Map<String, dynamic>> _posts = [
    {
      'name': "Dipprokash Sardar",
      'username': "@Kolkata",
      'image': "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
      'caption': "Một ngày đẹp trời ở Kolkata!",
      'likes': 7500,
      'comments': 425,
    },
    {
      'name': "Dipprokash Sardar",
      'username': "@Kolkata",
      'image': "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
      'caption': "Biển xanh ngát, thư giãn tuyệt vời.",
      'likes': 6500,
      'comments': 320,
    },
  ];

  // ScrollController để theo dõi vị trí cuộn
  final ScrollController _scrollController = ScrollController();

  // Biến để kiểm soát opacity của FAB (1.0 = hiện, 0.0 = ẩn)
  double _fabOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự kiện cuộn
    _scrollController.addListener(() {
      setState(() {
        // Nếu cuộn xuống (offset > 0), ẩn FAB; ngược lại hiện
        _fabOpacity = _scrollController.offset > 0 ? 0.0 : 1.0;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();  // Giải phóng controller khi không dùng
    super.dispose();
  }

  // Hàm để thêm post mới (được gọi từ PostDialog)
  void _addNewPost(Map<String, dynamic> newPost) {
    setState(() {
      _posts.insert(0, newPost);  // Thêm vào đầu danh sách
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = ["You", "Bella", "Emma", "Aron", "Milan"];
    final images = [
      "https://cdn3d.iconscout.com/3d/premium/thumb/young-man-5689575-4758544.png",
      "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d",
      "https://images.unsplash.com/photo-1501004318641-b39e6451bec6",
      "https://images.unsplash.com/photo-1560807707-8cc77767d783",
      "https://images.unsplash.com/photo-1527980965255-d3b416303d12",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Explore",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
              onPressed: () {
                // Mở dialog bằng widget riêng
                showDialog(
                  context: context,
                  builder: (context) => PostDialog(onPostCreated: _addNewPost),
                );
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,  // Gán ScrollController vào ListView
        children: [
          // Stories Section (giữ nguyên)
          SizedBox(
            height: 105,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, right: 8),
              itemCount: names.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.lightBlueAccent],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(images[index]),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        names[index],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Posts Section (dùng ListView.builder cho danh sách động)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              shrinkWrap: true, // Để ListView con không chiếm toàn bộ chiều cao
              physics: const NeverScrollableScrollPhysics(), // Vô hiệu hóa cuộn riêng
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return _buildPostCard(
                  name: post['name'],
                  username: post['username'],
                  image: post['image'],
                  caption: post['caption'],
                  likes: post['likes'],
                  comments: post['comments'],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _fabOpacity,  // Điều khiển độ mờ dựa trên scroll
        duration: const Duration(milliseconds: 300),  // Thời gian fade
        child: FloatingActionButton(
          onPressed: () {
            // Mở dialog bằng widget riêng
            showDialog(
              context: context,
              builder: (context) => PostDialog(onPostCreated: _addNewPost),
            );
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // Custom PostCard (thêm tham số caption)
  Widget _buildPostCard({
    required String name,
    required String username,
    required String image,
    required String caption, // Thêm caption động
    required int likes,
    required int comments,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD8E8FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                    "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde"),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),

          // Caption (động từ dữ liệu)
          Text(
            caption,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 10),

          // Image (hỗ trợ cả local file và network)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: image.startsWith('http')
                ? Image.network(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Image.file(
              File(image),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),

          // Like / Comment / Share Row
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 22),
              const SizedBox(width: 6),
              Text(
                likes >= 1000 ? "${(likes / 1000).toStringAsFixed(1)}K" : likes.toString(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 22),
              const SizedBox(width: 6),
              Text(
                comments.toString(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              const Icon(Icons.send_outlined, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }
}