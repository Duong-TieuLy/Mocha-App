import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'post_dialog.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // Giả lập dữ liệu server
  List<Map<String, dynamic>> _allPosts = [
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
    // Bạn có thể thêm nhiều post khác
  ];

  List<Map<String, dynamic>> _posts = []; // Danh sách posts đang hiển thị
  final ScrollController _scrollController = ScrollController();
  double _fabOpacity = 1.0;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;

  final int _pageSize = 2; // số bài load mỗi lần
  int _currentPage = 0;

  final List<String> names = ["You", "Bella", "Emma", "Aron", "Milan"];
  final List<String> images = [
    "https://cdn3d.iconscout.com/3d/premium/thumb/young-man-5689575-4758544.png",
    "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d",
    "https://images.unsplash.com/photo-1501004318641-b39e6451bec6",
    "https://images.unsplash.com/photo-1560807707-8cc77767d783",
    "https://images.unsplash.com/photo-1527980965255-d3b416303d12",
  ];

  @override
  void initState() {
    super.initState();
    _loadMorePosts(); // load trang đầu tiên

    _scrollController.addListener(() {
      // Ẩn/hiện FAB
      setState(() {
        _fabOpacity = _scrollController.offset > 0 ? 0.0 : 1.0;
      });

      // Pull-to-refresh
      if (_scrollController.offset <= 0 && !_isRefreshing) {
        _refreshPage();
      }

      // Infinite scroll khi scroll gần cuối
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore) {
        _loadMorePosts();
      }
    });
  }

  // Load thêm post theo trang
  void _loadMorePosts() async {
    if (_currentPage * _pageSize >= _allPosts.length) return;
    _isLoadingMore = true;

    await Future.delayed(const Duration(milliseconds: 500));

    int start = _currentPage * _pageSize;
    int end = start + _pageSize;
    if (end > _allPosts.length) end = _allPosts.length;

    setState(() {
      _posts.addAll(_allPosts.sublist(start, end));
      _currentPage++;
    });

    _isLoadingMore = false;
  }

  // Pull-to-refresh
  Future<void> _refreshPage() async {
    _isRefreshing = true;
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _posts.clear();
      _currentPage = 0;
    });
    _loadMorePosts();
    _isRefreshing = false;
  }

  // Thêm post mới từ dialog
  void _addNewPost(Map<String, dynamic> newPost) {
    setState(() {
      _posts.insert(0, newPost);
      _allPosts.insert(0, newPost);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + 2, // +1 cho Stories, +1 cho loading
        itemBuilder: (context, index) {
          if (index == 0) {
            // Stories Section
            return SizedBox(
              height: 105,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: names.length,
                itemBuilder: (context, i) {
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
                            backgroundImage: NetworkImage(images[i]),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          names[i],
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
            );
          }

          if (index <= _posts.length) {
            // Post Card
            final post = _posts[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildPostCard(
                key: ValueKey(post['image']),
                name: post['name'],
                username: post['username'],
                image: post['image'],
                caption: post['caption'],
                likes: post['likes'],
                comments: post['comments'],
              ),
            );
          }

          // Loading indicator cuối ListView
          return _isLoadingMore
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
              : const SizedBox.shrink();
        },
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _fabOpacity,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton(
          onPressed: () {
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

  Widget _buildPostCard({
    required Key key,
    required String name,
    required String username,
    required String image,
    required String caption,
    required int likes,
    required int comments,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12, top: 12),
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
          // Caption
          Text(
            caption,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 10),
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: image.startsWith('http')
                ? CachedNetworkImage(
              imageUrl: image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
              const Center(child: Icon(Icons.error, color: Colors.red)),
            )
                : Image.file(
              File(image),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          // Like / Comment / Share
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 22),
              const SizedBox(width: 6),
              Text(
                likes >= 1000
                    ? "${(likes / 1000).toStringAsFixed(1)}K"
                    : likes.toString(),
                style:
                const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 22),
              const SizedBox(width: 6),
              Text(
                comments.toString(),
                style:
                const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
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