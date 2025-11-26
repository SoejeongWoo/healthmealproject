import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("검색")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "메뉴 이름 또는 재료로 검색",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  if (_query.isEmpty) return true;

                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final description =
                      (data['description'] ?? '').toString().toLowerCase();

                  final mainIngredients =
                      List<String>.from(data['mainIngredients'] ?? []);
                  final subIngredients =
                      List<String>.from(data['subIngredients'] ?? []);
                  final otherIngredients =
                      List<String>.from(data['otherIngredients'] ?? []);

                  final allIngredients = [
                    ...mainIngredients,
                    ...subIngredients,
                    ...otherIngredients,
                  ].join(' ').toLowerCase();

                  return name.contains(_query) ||
                      description.contains(_query) ||
                      allIngredients.contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("검색 결과가 없습니다."));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? '';
                    final imageUrl = data['imageUrl'] ?? '';
                    final mainIngredients =
                        List<String>.from(data['mainIngredients'] ?? []);
                    final subIngredients =
                        List<String>.from(data['subIngredients'] ?? []);
                    final otherIngredients =
                        List<String>.from(data['otherIngredients'] ?? []);

                    final allIngredients = [
                      ...mainIngredients,
                      ...subIngredients,
                      ...otherIngredients,
                    ];

                    return ListTile(
                      leading: imageUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(imageUrl),
                            )
                          : const CircleAvatar(child: Icon(Icons.image)),
                      title: Text(name),
                      subtitle: allIngredients.isNotEmpty
                          ? Text(allIngredients.join(', '))
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(docId: doc.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
