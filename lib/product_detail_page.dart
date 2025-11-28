import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'edit_product_page.dart';
import 'wishlist_provider.dart';

class ProductDetailPage extends StatelessWidget {
  final String docId;

  const ProductDetailPage({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? '';
        final imageUrl = data['imageUrl'] ?? '';
        final description = data['description'] ?? '';
        final List<String> foodOptions =
            List<String>.from(data['foodOptions'] ?? []);
        final uid = data['uid'] ?? '';

        final createdAt = data['createdAt'];
        final updatedAt = data['updatedAt'];

        final mainIngredients =
            List<String>.from(data['mainIngredients'] ?? []);
        final subIngredients = List<String>.from(data['subIngredients'] ?? []);
        final otherIngredients =
            List<String>.from(data['otherIngredients'] ?? []);

        final myUid = FirebaseAuth.instance.currentUser!.uid;
        final isOwner = myUid == uid;

        final rawTime = data['cookingTime'];
        int cookingTime = 0;

        if (rawTime is int) {
          cookingTime = rawTime;
        } else if (rawTime is String) {
          cookingTime = int.tryParse(rawTime) ?? 0;
        }

        String cookingTimeText = "";
        if (cookingTime > 0) {
          int hour = cookingTime ~/ 60;
          int minute = cookingTime % 60;

          if (hour > 0) {
            cookingTimeText = "$hour시간 $minute분";
          } else {
            cookingTimeText = "$minute분";
          }
        }

        Widget ingredientSection(String title, List<String> list) {
          if (list.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title: ",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: list.map((i) => Chip(label: Text(i))).toList(),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Healthy Recipe Detail"),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.create),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProductPage(
                          docId: docId,
                          currentName: name,
                          currentDescription: description,
                          currentImageUrl: imageUrl,
                          mainIngredients: mainIngredients,
                          subIngredients: subIngredients,
                          otherIngredients: otherIngredients,
                        ),
                      ),
                    );
                  },
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(docId)
                        .delete();

                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('products/$docId.jpg');

                    try {
                      await ref.delete();
                    } catch (_) {}

                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<WishlistProvider>(
                        builder: (context, wishlistProvider, child) {
                          final isInWishlist =
                              wishlistProvider.isInWishlist(docId);

                          return IconButton(
                            icon: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isInWishlist ? Colors.red : Colors.grey,
                              size: 30,
                            ),
                            onPressed: () {
                              wishlistProvider.toggleWishlist(docId);
                            },
                          );
                        },
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .doc(docId)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Text(
                              "0",
                              style: TextStyle(fontSize: 16),
                            );
                          }
                          final currentLikes = snap.data!['likes'] ?? 0;

                          return Text(
                            "$currentLikes",
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (cookingTimeText.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      "⏱ 조리시간: $cookingTimeText",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ingredientSection("메인 재료", mainIngredients),
                ingredientSection("서브 재료", subIngredients),
                ingredientSection("기타 재료", otherIngredients),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description),
                      const SizedBox(height: 15),

                      // ⭐ 옵션들
                      if (foodOptions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: foodOptions.map((opt) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "#$opt",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Author UID: $uid"),
                      if (createdAt != null)
                        Text("Created: ${createdAt.toDate()}"),
                      if (updatedAt != null)
                        Text("Updated: ${updatedAt.toDate()}"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
