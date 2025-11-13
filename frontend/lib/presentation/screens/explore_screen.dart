import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/post_card.dart';
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
          ],
        ),
      )
    );
  }
}
