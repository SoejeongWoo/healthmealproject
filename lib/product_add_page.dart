import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductAddPage extends StatefulWidget {
  const ProductAddPage({super.key});

  @override
  State<ProductAddPage> createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final List<String> mainIngredients = [];
  final List<String> subIngredients = [];
  final List<String> otherIngredients = [];

  File? _selectedImage;
  final String defaultImage =
      'http://handong.edu/site/handong/res/img/logo.png';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _addIngredient(List<String> list) async {
    String? result = await showDialog(
      context: context,
      builder: (_) {
        final TextEditingController c = TextEditingController();
        return AlertDialog(
          title: const Text("재료 추가"),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: "재료명"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, c.text),
              child: const Text("추가"),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() => list.add(result.trim()));
    }
  }

  Future<void> _saveProduct() async {
    String imageUrl = defaultImage;
    final docRef = FirebaseFirestore.instance.collection('products').doc();

    if (_selectedImage != null) {
      final ref =
          FirebaseStorage.instance.ref().child('products/${docRef.id}.jpg');
      await ref.putFile(_selectedImage!);
      imageUrl = await ref.getDownloadURL();
    }

    await docRef.set({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'imageUrl': imageUrl,
      'uid': FirebaseAuth.instance.currentUser!.uid,
      'mainIngredients': mainIngredients,
      'subIngredients': subIngredients,
      'otherIngredients': otherIngredients,
      'likes': 0,
      'likedUsers': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  Widget ingredientSection(
      String title, List<String> list, VoidCallback addFn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(onPressed: addFn, icon: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list
              .map(
                (i) => Chip(
                  label: Text(i),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메뉴 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, height: 150)
                    : Image.network(defaultImage, height: 150),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '메뉴 이름'),
              ),
              const SizedBox(height: 16),
              ingredientSection("메인 재료", mainIngredients,
                  () => _addIngredient(mainIngredients)),
              ingredientSection("서브 재료", subIngredients,
                  () => _addIngredient(subIngredients)),
              ingredientSection("기타 재료", otherIngredients,
                  () => _addIngredient(otherIngredients)),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
