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
          child: Text("Your favorite recipe is empty."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Recipes")),
      body: ListView.builder(
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
                return const ListTile(
                  title: Text("Loading..."),
                );
              }

              if (!snapshot.data!.exists) {
                return ListTile(
                  title: Text("Item $docId not found"),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(
                  data['imageUrl'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
                title: Text(data['name']),

                // 아이템 클릭하면 디테일 페이지 이동
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(docId: docId),
                    ),
                  );
                },

                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    context.read<WishlistProvider>().toggleWishlist(docId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
