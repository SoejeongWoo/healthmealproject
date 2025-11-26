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

          return const Scaffold(
            body: SizedBox.shrink(),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? '';
        final imageUrl = data['imageUrl'] ?? '';
        final description = data['description'] ?? '';
        final uid = data['uid'] ?? '';
        final createdAt = data['createdAt'];
        final updatedAt = data['updatedAt'];

        final likes = data['likes'] ?? 0;
        final likedUsers = List<String>.from(data['likedUsers'] ?? []);

        final mainIngredients =
            List<String>.from(data['mainIngredients'] ?? []);
        final subIngredients = List<String>.from(data['subIngredients'] ?? []);
        final otherIngredients =
            List<String>.from(data['otherIngredients'] ?? []);

        final myUid = FirebaseAuth.instance.currentUser!.uid;
        final isOwner = myUid == uid;

        Future<void> likeProduct() async {
          final ref =
              FirebaseFirestore.instance.collection('products').doc(docId);

          if (likedUsers.contains(myUid)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You can only do it once!!")),
            );
            return;
          }

          await ref.update({
            'likes': likes + 1,
            'likedUsers': FieldValue.arrayUnion([myUid]),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("I like it")),
          );
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

                // 나머지 공간 전체에서 Chip들이 줄바꿈 되면서 표시됨
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
                    } catch (_) {
                      // 이미지가 없을 수도 있으니 무시
                    }

                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          floatingActionButton:
              Consumer<WishlistProvider>(builder: (context, wishlist, child) {
            final isInWishlist = wishlist.isInWishlist(docId);

            return FloatingActionButton(
              backgroundColor: isInWishlist ? Colors.green : Colors.blue,
              child: Icon(
                isInWishlist ? Icons.check : Icons.favorite,
                color: Colors.white,
              ),
              onPressed: () {
                wishlist.toggleWishlist(docId);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isInWishlist
                          ? "Removed from favorites"
                          : "Added to favorites",
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          }),
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
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: likedUsers.contains(myUid)
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        onPressed: likeProduct,
                      ),
                      Text("$likes"),
                    ],
                  ),
                ),
                ingredientSection("메인 재료", mainIngredients),
                ingredientSection("서브 재료", subIngredients),
                ingredientSection("기타 재료", otherIngredients),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(description),
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
