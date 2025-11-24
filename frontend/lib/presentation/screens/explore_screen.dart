import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/profile_view_model.dart';
import '../view_models/user_view_model.dart';
import 'post_dialog.dart';
import 'post_card.dart';
import 'stories_section.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Map<String, dynamic>> _followingUsers = [];
  bool _isLoadingStories = true;

  final ScrollController _scrollController = ScrollController();
  double _fabOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollowing();
      Provider.of<PostViewModel>(context, listen: false).loadAllPosts();
    });

    _scrollController.addListener(() {
      setState(() {
        _fabOpacity = _scrollController.offset > 0 ? 0.0 : 1.0;
      });
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openPostDialog() {
    showDialog(
      context: context,
      builder: (context) => const PostDialog(), // dialog chỉ UI + submit
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "Explore",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.black),
              onPressed: _openPostDialog,
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

          return RefreshIndicator(
            onRefresh: () => postVM.loadAllPosts(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: postVM.posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return StoriesSection(
                    isLoading: _isLoadingStories,
                    followingUsers: _followingUsers,
                  );
                }

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
            ),
          );
        },
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _fabOpacity,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton(
          onPressed: _openPostDialog,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
