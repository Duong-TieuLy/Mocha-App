import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/auth_view_model.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background circles
          Positioned(top: -60, right: -60, child: _circle(200)),
          Positioned(bottom: -80, left: -80, child: _circle(220)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Consumer<AuthViewModel>(
                builder: (context, auth, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),
                      const Center(
                        child: Text(
                          "Login here",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Email
                      _inputField("Email", controller: emailController),

                      const SizedBox(height: 20),

                      // Password
                      _inputField("Password",
                          controller: passwordController, isPassword: true),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Login button
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 100, vertical: 14)),
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                            await auth.login(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );

                            if (auth.currentUser != null) {
                              Navigator.pushReplacementNamed(
                                  context, '/home');
                            }
                          },
                          child: auth.isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                              : const Text(
                            "Login",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Signup
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don’t have an account? ",
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/signup'),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (auth.errorMessage != null)
                        Center(
                          child: Text(
                            auth.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label,
      {bool isPassword = false, TextEditingController? controller}) =>
      TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      );

  Widget _circle(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
            color: Colors.black26, blurRadius: 15, offset: Offset(0, 6))
      ],
    ),
  );
}
