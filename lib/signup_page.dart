import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  static const defaultMsg = "맛있고 건강한 음식을 공유해봐요~";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              TextField(
                controller: _confirm,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_password.text != _confirm.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Passwords do not match")),
                        );
                        return;
                      }

                      try {
                        final cred = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: _email.text.trim(),
                          password: _password.text.trim(),
                        );

                        await FirebaseFirestore.instance
                            .collection('user')
                            .doc(cred.user!.uid)
                            .set({
                          "name": _name.text.trim(),
                          "email": _email.text.trim(),
                          "uid": cred.user!.uid,
                          "status_message": defaultMsg,
                        });

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Signup failed: $e")),
                        );
                      }
                    },
                    child: const Text("Create Account"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
