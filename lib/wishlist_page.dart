import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'wishlist_provider.dart';
import 'product_detail_page.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>().wishlist;

    if (wishlist.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Favorite Recipes")),
        body: const Center(
          child: Text(
            "Your favorite recipe is empty.",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Recipes")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: wishlist.length,
        itemBuilder: (context, index) {
          final docId = wishlist[index];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('products')
                .doc(docId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                );
              }

              if (!snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              final imageUrl = data['imageUrl'] ?? "";
              final name = data['name'] ?? "";
              final List<String> ingredients =
                  List<String>.from(data['mainIngredients'] ?? []);

              final ingredientPreview = ingredients.isNotEmpty
                  ? ingredients.take(3).join(", ")
                  : "No ingredients";

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(docId: docId),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ingredientPreview,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("Remove Favorite"),
                                content: const Text("정말로 즐겨찾기에서 삭제할까요?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("아니요"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("예"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            context
                                .read<WishlistProvider>()
                                .toggleWishlist(docId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
