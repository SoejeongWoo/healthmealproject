import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final String docId;
  final String currentName;
  final int currentPrice;
  final String currentDescription;
  final String currentImageUrl;

  const EditProductPage({
    super.key,
    required this.docId,
    required this.currentName,
    required this.currentPrice,
    required this.currentDescription,
    required this.currentImageUrl,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  File? _newImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _priceController =
        TextEditingController(text: widget.currentPrice.toString());
    _descController = TextEditingController(text: widget.currentDescription);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
    }
  }

  Future<void> _updateProduct() async {
    String imageUrl = widget.currentImageUrl;

    if (_newImage != null) {
      final ref =
          FirebaseStorage.instance.ref().child('products/${widget.docId}.jpg');
      await ref.putFile(_newImage!);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.docId)
        .update({
      'name': _nameController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'description': _descController.text,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _newImage != null
                    ? Image.file(_newImage!, height: 150)
                    : Image.network(widget.currentImageUrl, height: 150),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text("Save"),
                onPressed: _updateProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
