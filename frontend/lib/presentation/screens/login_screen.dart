import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _output;

  Future<void> _login() async {
    setState(() => _loading = true);
    _output = null;

    try {
      // 🔹 1. Firebase login
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 🔹 2. Get Firebase ID token
      String? idToken = await userCredential.user!.getIdToken();

      // 🔹 3. Verify token via your AuthService
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/api/auth/verifyToken"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final _data = jsonDecode(response.body);
        setState(() => _output = "✅ Login success!");
        Navigator.pushReplacementNamed(context, '/moment');
      } else {
        setState(() => _output = "❌ AuthService error: ${response.body}");
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _output = "Firebase error: ${e.message}");
    } catch (e) {
      setState(() => _output = "Unexpected error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🔵 Background circles
          Positioned(top: -60, right: -60, child: _circle(200)),
          Positioned(bottom: -80, left: -80, child: _circle(220)),

          // 🧱 Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  const Center(
                    child: Text(
                      "Login here",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // 📨 Email field
                  _inputField("Email", controller: _emailController),

                  const SizedBox(height: 20),

                  // 🔒 Password field
                  _inputField("Password",
                      controller: _passwordController, isPassword: true),

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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔘 Login button
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 14),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
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

                  // 🧾 Signup text
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

                  if (_output != null)
                    Center(
                      child: Text(
                        _output!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
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
