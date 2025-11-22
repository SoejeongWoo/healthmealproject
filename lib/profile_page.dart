import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'main.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final provider = context.read<UserProvider>();

    provider.loadUser(widget.user.uid).then((_) {
      _statusController.text = provider.statusMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final bool isAnonymous = widget.user.isAnonymous;

    final profileImage = isAnonymous
        ? "http://handong.edu/site/handong/res/img/logo.png"
        : (widget.user.photoURL ??
            "http://handong.edu/site/handong/res/img/logo.png");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => AuthHome()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: provider.uid.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        profileImage,
                        width: 180,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("UID: ${provider.uid}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      "Name: ${isAnonymous ? "Anonymous" : provider.name}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Email: ${isAnonymous ? "Anonymous" : provider.email}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(
                      "— ${isAnonymous ? "Guest" : provider.name} —",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    provider.isEditing
                        ? Column(
                            children: [
                              TextField(
                                controller: _statusController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  provider.updateStatus(
                                      _statusController.text.trim());
                                  provider.saveStatus();
                                },
                                child: const Text("Save"),
                              )
                            ],
                          )
                        : Column(
                            children: [
                              Text(
                                provider.statusMessage,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  provider.startEditing();
                                },
                                child: const Text(
                                  "Edit",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 40),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
