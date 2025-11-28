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

  final TextEditingController _timeController = TextEditingController();

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "최대 조리 시간 (분)",
                hintText: "예: 30 → 30분 이하의 메뉴",
                prefixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {});
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

                int? maxTime;
                if (_timeController.text.trim().isNotEmpty) {
                  maxTime = int.tryParse(_timeController.text.trim());
                }

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (_query.isNotEmpty) {
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

                    if (!name.contains(_query) &&
                        !description.contains(_query) &&
                        !allIngredients.contains(_query)) {
                      return false;
                    }
                  }

                  if (maxTime != null) {
                    int cookingTime = data['cookingTime'] ?? 0;
                    if (cookingTime > maxTime) return false;
                  }

                  return true;
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

                    int cookingTime = data['cookingTime'] ?? 0;
                    int hour = cookingTime ~/ 60;
                    int minute = cookingTime % 60;
                    String timeText =
                        hour > 0 ? "$hour시간 $minute분" : "$minute분";

                    return ListTile(
                      leading: imageUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(imageUrl),
                            )
                          : const CircleAvatar(child: Icon(Icons.image)),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (allIngredients.isNotEmpty)
                            Text(allIngredients.join(', ')),
                          const SizedBox(height: 2),
                          Text("조리 시간: $timeText",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
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
