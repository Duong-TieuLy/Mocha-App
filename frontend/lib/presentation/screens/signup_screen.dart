import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -60, left: -40, child: _circle(200)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text("Create Account",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text("Connect with your friends today"),
                const SizedBox(height: 40),

                _inputField("Username", controller: _usernameCtrl),
                const SizedBox(height: 15),
                _inputField("Email", controller: _emailCtrl),
                const SizedBox(height: 15),
                _inputField("Password", controller: _passwordCtrl, isPassword: true),
                const SizedBox(height: 15),
                _inputField("Confirm Password", controller: _confirmPasswordCtrl, isPassword: true),
                const SizedBox(height: 25),

                // 🔵 Nút đăng ký
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.horizontal,
                          child: child,
                        ),
                      );
                    },
                    child: vm.isLoading
                        ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.blue,
                      ),
                    )
                        : ElevatedButton(
                      key: const ValueKey('signup_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // Thêm loading state nếu VM chưa tự set
                        if (!vm.isLoading) {
                          await vm.signup(
                            email: _emailCtrl.text.trim(),
                            password: _passwordCtrl.text.trim(),
                            confirmPassword: _confirmPasswordCtrl.text.trim(),
                            displayName: _usernameCtrl.text.trim(),
                          );

                          // Nếu mounted thì mới thao tác UI
                          if (!mounted) return;

                          if (vm.errorMessage == null) {
                            Navigator.pushReplacementNamed(
                                context, '/congratulations');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vm.errorMessage!),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label,
      {required TextEditingController controller, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _circle(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
    ),
  );
}
