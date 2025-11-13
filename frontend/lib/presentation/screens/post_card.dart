import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final UserProfile userProfile;

  const PostCard({
    super.key,
    required this.post,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 22,
                child: Icon(Icons.person, color: Colors.black),
              ),
              title: Text(userProfile.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              subtitle: Text(userProfile.firebaseUid, style: const TextStyle(color: Colors.black54)),
            ),
            // Image
            ClipRRect(
              // borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              borderRadius: BorderRadius.circular(20),
              child: Image.network(post.images!, fit: BoxFit.cover, height: 300, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text("$post.likeCount"),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text("$post.commentCount"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}