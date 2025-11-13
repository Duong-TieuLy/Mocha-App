import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';  // Thêm import này

class PostCard extends StatelessWidget {
  final String name;
  final String username;
  final String image;
  final int comments;
  final int likes;

  const PostCard({
    super.key,
    required this.name,
    required this.username,
    required this.image,
    required this.comments,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
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
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              subtitle: Text(username, style: const TextStyle(color: Colors.black54)),
            ),
            // Image với CachedNetworkImage để mượt hơn
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                height: 300,
                width: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),  // Loading spinner
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.red),  // Fallback nếu lỗi
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text("$likes"),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text("$comments"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
