import 'package:flutter/material.dart';

class UploadPhotoScreen extends StatelessWidget {
  const UploadPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: -60,
            right: -60,
            child: CircleAvatar(radius: 100, backgroundColor: Color(0xFF2196F3)),
          ),
          const Positioned(
            bottom: -60,
            right: -40,
            child: CircleAvatar(radius: 80, backgroundColor: Color(0xFF2196F3)),
          ),
          const Positioned(
            left: -40,
            bottom: 150,
            child: CircleAvatar(radius: 60, backgroundColor: Color(0xFF2196F3)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Complete Profile",
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Let's get to know you better!",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 40),
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text("Upload Photo",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: ()=> Navigator.pushNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 14),
                    ),
                    child: const Text("Complete", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: ()=> Navigator.pushNamed(context, '/home'),
                    child: const Text("Skip for now",
                        style: TextStyle(
                            color: Colors.black54,
                            fontStyle: FontStyle.italic
                        )
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
