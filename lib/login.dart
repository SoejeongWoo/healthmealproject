import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shrine/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Shrine 로그인", style: TextStyle(fontSize: 28)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final user = await _authService.signInWithGoogle();
                if (user != null) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: const Text("Sign in with Google"),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: _email.text.trim(),
                    password: _password.text.trim(),
                  );
                  Navigator.pushReplacementNamed(context, '/home');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Login failed: $e")));
                }
              },
              child: const Text("Sign in with Email"),
            ),
          ],
        ),
      ),
    );
  }
}
