import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../data/models/post_model.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/post_view_model.dart';
import 'post_dialog.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late PostViewModel postVm;
  late String currentUid;

  final ScrollController _scrollController = ScrollController();
  double _fabOpacity = 1.0;

  // Stories giả lập
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
    postVm = Provider.of<PostViewModel>(context, listen: false);
    currentUid = Provider.of<AuthViewModel>(context, listen: false).currentUser!.uid;

    // Load page đầu tiên
    postVm.loadPosts(currentUid);

    // Listener scroll
    _scrollController.addListener(() {
      setState(() {
        _fabOpacity = _scrollController.offset > 0 ? 0.0 : 1.0;
      });

      // Lazy load khi scroll gần cuối
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !postVm.isLoading &&
          postVm.hasMore) {
        postVm.loadPosts(currentUid);
      }
    });
  }

  // Pull-to-refresh
  Future<void> _refreshPage() async {
    await postVm.loadPosts(currentUid, refresh: true);
  }

  // Thêm post mới từ dialog
  void _addNewPost(Map<String, dynamic> newPostJson) {
    final newPost = Post.fromJson(newPostJson);
    setState(() {
      postVm.posts.insert(0, newPost);
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
        title: const Text(
          "Explore",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
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
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: Consumer<PostViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.error != null && vm.posts.isEmpty) {
              return Center(child: Text("Error: ${vm.error}"));
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: vm.posts.length + 2, // +1 stories, +1 loading indicator
              itemBuilder: (context, index) {
                if (index == 0) return _buildStoriesSection();

                if (index <= vm.posts.length) {
                  final post = vm.posts[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildPostCard(post),
                  );
                }

                // Loading indicator cuối
                return vm.isLoading
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
                    : const SizedBox.shrink();
              },
            );
          },
        ),
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

  Widget _buildStoriesSection() {
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      key: ValueKey(post.id),
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
                  "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde",
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.userName ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black),
                  ),
                  Text(
                    "@${post.userName ?? "user"}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
            post.content ?? "",
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 10),
          // Image
          if (post.images != null && post.images!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: post.images!.startsWith('http')
                  ? CachedNetworkImage(
                imageUrl: post.images!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error, color: Colors.red)),
              )
                  : Image.file(
                File(post.images!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
