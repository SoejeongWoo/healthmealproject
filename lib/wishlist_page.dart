import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'wishlist_provider.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>().wishlist;

    if (wishlist.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Wishlist")),
        body: const Center(
          child: Text("Your wishlist is empty."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Wishlist")),
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
                subtitle: Text("₩${data['price']}"),
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
