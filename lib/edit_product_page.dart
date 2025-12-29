import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final String docId;
  final String currentName;
  final String currentDescription;
  final String currentImageUrl;
  final List<String> mainIngredients;
  final List<String> subIngredients;
  final List<String> otherIngredients;

  const EditProductPage({
    super.key,
    required this.docId,
    required this.currentName,
    required this.currentDescription,
    required this.currentImageUrl,
    required this.mainIngredients,
    required this.subIngredients,
    required this.otherIngredients,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();
  final List<String> allFoodOptions = [
    "디저트",
    "가볍게 먹는 식사",
    "든든한 식사",
    "고단백",
  ];

  List<String> selectedFoodOptions = [];

  late List<String> mainIngredients;
  late List<String> subIngredients;
  late List<String> otherIngredients;

  File? _newImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descController = TextEditingController(text: widget.currentDescription);

    mainIngredients = List.from(widget.mainIngredients);
    subIngredients = List.from(widget.subIngredients);
    otherIngredients = List.from(widget.otherIngredients);

    _loadExistingCookingTime();
  }

  Future<void> _loadExistingCookingTime() async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.docId)
        .get();

    int totalMinutes = doc.data()?['cookingTime'] ?? 0;

    int hour = totalMinutes ~/ 60;
    int minute = totalMinutes % 60;

    _hourController.text = hour.toString();
    _minuteController.text = minute.toString();
    selectedFoodOptions = List<String>.from(doc.data()?['foodOptions'] ?? []);
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
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

  Future<void> _updateProduct() async {
    String imageUrl = widget.currentImageUrl;

    if (_newImage != null) {
      final ref =
          FirebaseStorage.instance.ref().child('products/${widget.docId}.jpg');
      await ref.putFile(_newImage!);
      imageUrl = await ref.getDownloadURL();
    }

    int hour = int.tryParse(_hourController.text) ?? 0;
    int minute = int.tryParse(_minuteController.text) ?? 0;
    int totalMinutes = hour * 60 + minute;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.docId)
        .update({
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'imageUrl': imageUrl,
      'mainIngredients': mainIngredients,
      'subIngredients': subIngredients,
      'otherIngredients': otherIngredients,
      'updatedAt': FieldValue.serverTimestamp(),
      'cookingTime': totalMinutes,
      'foodOptions': selectedFoodOptions,
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
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < list.length; i++)
              ListTile(
                key: ValueKey("$title-$i-${list[i]}"),
                leading: const Icon(Icons.drag_handle),
                title: Text(list[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      list.removeAt(i);
                    });
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("메뉴 수정")),
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
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "메뉴 이름"),
              ),
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "조리 시간을 입력하시오",
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hourController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '시간',
                                hintText: '예: 1',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _minuteController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '분',
                                hintText: '예: 30',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ingredientSection("메인 재료", mainIngredients,
                  () => _addIngredient(mainIngredients)),
              ingredientSection("서브 재료", subIngredients,
                  () => _addIngredient(subIngredients)),
              ingredientSection("기타 재료", otherIngredients,
                  () => _addIngredient(otherIngredients)),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "설명"),
                maxLines: 3,
              ),
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("음식 옵션 선택",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: allFoodOptions.map((opt) {
                          final isSelected = selectedFoodOptions.contains(opt);
                          return FilterChip(
                            label: Text(opt),
                            selected: isSelected,
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  selectedFoodOptions.add(opt);
                                } else {
                                  selectedFoodOptions.remove(opt);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _updateProduct,
                child: const Text("저장"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
