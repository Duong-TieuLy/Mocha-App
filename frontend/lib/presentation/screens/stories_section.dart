import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StoriesSection extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> followingUsers;

  const StoriesSection({
    super.key,
    required this.isLoading,
    required this.followingUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 105,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: followingUsers.length,
        itemBuilder: (context, i) {
          final user = followingUsers[i];
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
                    backgroundImage: CachedNetworkImageProvider(
                      user['photoUrl'] ?? 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                    ),
                    onBackgroundImageError: (_, __) {
                      print('Load image error, fallback to default');
                    },
                  )
                ),
                const SizedBox(height: 6),
                Text(
                  user['fullName'] ?? 'No Name',
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
}
