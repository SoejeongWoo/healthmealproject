import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class DetailProfilePage extends StatefulWidget {
  final User user;
  const DetailProfilePage({super.key, required this.user});

  @override
  State<DetailProfilePage> createState() => _DetailProfilePageState();
}

class _DetailProfilePageState extends State<DetailProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<UserProvider>();
    provider.loadUser(widget.user.uid).then((_) {
      _nameController.text = provider.name;
      _statusController.text = provider.statusMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final profileImage =
        widget.user.photoURL ?? "https://i.ibb.co/fY5w3YNR/mainprofile.png";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Details"),
      ),
      body: provider.uid.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      profileImage,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "이름",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _statusController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "상태 메세지",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      provider.updateName(_nameController.text.trim());
                      provider.updateStatus(_statusController.text.trim());
                      await provider.saveAll();
                      Navigator.pop(context);
                    },
                    child: const Text("저장"),
                  ),
                ],
              ),
            ),
    );
  }
}
