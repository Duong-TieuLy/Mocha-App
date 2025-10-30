import 'package:flutter/material.dart';

class MomentsPage extends StatelessWidget {
  const MomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,

      // Thanh trên cùng
      appBar: AppBar(
        automaticallyImplyLeading: false, // Ẩn nút quay lại tự động
        backgroundColor: Colors.white,
        actions: const [
          Icon(Icons.search, color: Colors.black, size: 40),
          SizedBox(width: 16),
          Icon(Icons.notifications_none, color: Colors.black, size: 40),
          SizedBox(width: 16),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Moments",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 60),
            Container(
              width: double.infinity,
              height: screenHeight * 0.4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color.fromRGBO(121, 171, 222, 1), width: 3),
              ),
              child: const Center(
                child: Text("No moments yet",
                    style: TextStyle(color: Colors.black54)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: screenHeight * 0.15, // 🔹 tăng chiều cao
        shape: const CircularNotchedRectangle(),
        notchMargin: 4,
        color: Colors.white,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.flash_on_outlined, size: 50), onPressed: () {}),
            const SizedBox(width: 50),
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 50), onPressed: () {}),
          ],
        ),
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 60),
        child: SizedBox(
          width: 90,
          height: 90,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.blue,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.camera,
              size: 70, // 🔹 tăng kích thước icon bên trong
              color: Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
