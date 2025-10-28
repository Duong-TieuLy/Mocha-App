import 'package:flutter/material.dart';

class CongratulationsScreen extends StatelessWidget {
  const CongratulationsScreen({super.key});

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
            left: -40,
            child: CircleAvatar(radius: 80, backgroundColor: Color(0xFF2196F3)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/congrats.png',
                      height: 180, fit: BoxFit.contain),
                  const SizedBox(height: 24),
                  const Text(
                    "Congratulations!",
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Your account has been created.",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/complete-profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80, vertical: 14),
                    ),
                    child: const Text("Next", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
