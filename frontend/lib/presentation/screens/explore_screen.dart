import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final names = ["You", "Bella", "Emma", "Aron", "Milan", "Lucas", "Nina", "Tom", "Anna"];

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
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.black, size: 28),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none, color: Colors.black, size: 28),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: ListView(
          children: [
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 8),
                itemCount: names.length,
                itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, size: 30, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      names[index],
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              );
             },
            ),
            ),
            // 🔹 Example Post Card
            postCard("Damian", "@Damian12",
                "https://images.unsplash.com/photo-1501785888041-af3ef285b470", 10, 252),

            postCard("Katherine", "@Kiyyu23",
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e", 0, 0),
            postCard("Damian", "@Damian12",
                "https://images.unsplash.com/photo-1501785888041-af3ef285b470", 10, 252),

            postCard("Katherine", "@Kiyyu23",
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e", 0, 0),
            postCard("Damian", "@Damian12",
                "https://images.unsplash.com/photo-1501785888041-af3ef285b470", 10, 252),

            postCard("Katherine", "@Kiyyu23",
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e", 0, 0),
          ],
        ),
      )
    );
  }

  Widget postCard(String name, String username, String image, int comments, int likes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Image.network(image, fit: BoxFit.cover, height: 200, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text("$comments"),
                  const SizedBox(width: 16),
                  const Icon(Icons.favorite_border, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text("$likes"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
