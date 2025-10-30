import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/post_card.dart';

class ScrollableTab extends StatelessWidget {
  final List<PostCard> items;
  const ScrollableTab({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          "Empty Folder",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
      );
    }

    // Nếu có dữ liệu -> ListView
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          items[index],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}