// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';  // Thêm import này
// import '../../data/models/user_profile.dart';
// import '../../data/models/post_model.dart';
//
// class PostCard extends StatelessWidget {
//   final Post post;
//   final UserProfile userProfile;
//
//   const PostCard({
//     super.key,
//     required this.post,
//     required this.userProfile,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.blue.shade100,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             ListTile(
//               leading: const CircleAvatar(
//                 backgroundColor: Colors.white,
//                 radius: 22,
//                 child: Icon(Icons.person, color: Colors.black),
//               ),
//               title: Text(userProfile.fullName,
//                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
//               subtitle: Text(userProfile.firebaseUid, style: const TextStyle(color: Colors.black54)),
//             ),
//             // Image với CachedNetworkImage để mượt hơn
//             ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: Image.network(post.images!, fit: BoxFit.cover, height: 300, width: double.infinity),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   const Icon(Icons.favorite_border, color: Colors.black54),
//                   const SizedBox(width: 4),
//                   Text("$post.likeCount"),
//                   const SizedBox(width: 16),
//                   const Icon(Icons.comment_outlined, color: Colors.black54),
//                   const SizedBox(width: 4),
//                   Text("$post.commentCount"),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final String name;
  final String username;
  final String? image;
  final String caption;
  final int likes;

  const PostCard({
    super.key,
    required this.name,
    required this.username,
    this.image,
    required this.caption,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
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
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: image!.startsWith('http')
                  ? CachedNetworkImage(
                imageUrl: image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error, color: Colors.red)),
              )
                  : Image.file(
                File(image!),
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
