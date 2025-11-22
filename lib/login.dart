import 'package:flutter/material.dart';
import 'package:shrine/services/auth_service.dart';

class LoginPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  LoginPage({super.key});

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
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                final user = await _authService.signInAnonymously();
                if (user != null) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: const Text("Continue as Guest"),
            ),
          ],
        ),
      ),
    );
  }
}
