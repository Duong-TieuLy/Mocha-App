import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/presentation/screens/post_card.dart';
import 'package:frontend/presentation/screens/stories_section.dart';
import 'package:provider/provider.dart';
import '../view_models/profile_view_model.dart';
import '../view_models/user_view_model.dart';
import 'post_dialog.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Map<String, dynamic>> _followingUsers = [];
  bool _isLoadingStories = true;
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
    _loadMorePosts(); // load trang đầu tiê
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollowing();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final postVM = Provider.of<PostViewModel>(context, listen: false);
      print("Start loading posts...");
      await postVM.loadAllPosts(); // Bắt buộc await để chắc chắn thực thi
      print("Posts loaded: ${postVM.posts.length}");
    });

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
  Future<void> _loadFollowing() async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final followingList = await userViewModel.loadFollowing(currentUser.uid);

      setState(() {
        _followingUsers = followingList;
        _isLoadingStories = false;
      });
    } catch (e) {
      print('Error loading following users: $e');
      setState(() => _isLoadingStories = false);
    }
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
      body: Consumer<PostViewModel>(
        builder: (context, postVM, child) {
          if (postVM.isLoading) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            controller: _scrollController,
            itemCount: postVM.posts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return StoriesSection(
                isLoading: _isLoadingStories,
                followingUsers: _followingUsers,
              );

              final post = postVM.posts[index - 1];
              final profile = postVM.userProfiles[post.firebaseUid];

              return PostCard(
                name: profile?.fullName ?? 'Unknown',
                username: profile?.firebaseUid ?? '',
                image: post.images,
                caption: post.content,
                likes: post.likeCount,
              );
            },
          );
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
}
