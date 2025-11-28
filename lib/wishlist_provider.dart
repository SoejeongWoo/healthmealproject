import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistProvider extends ChangeNotifier {
  List<String> _wishlist = [];
  String? _uid;

  List<String> get wishlist => _wishlist;

  // 유저 UID 설정
  void setUser(String uid) {
    _uid = uid;
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    if (_uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('user').doc(_uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({'wishlist': []});
      _wishlist = [];
      notifyListeners();
      return;
    }

    final data = doc.data() as Map<String, dynamic>?;

    final rawWishlist = data?['wishlist'];
    if (rawWishlist == null || rawWishlist is! List) {
      _wishlist = [];
      await docRef.set({'wishlist': []}, SetOptions(merge: true));
    } else {
      _wishlist = List<String>.from(rawWishlist);
    }

    notifyListeners();
  }

  Future<void> saveWishlist() async {
    if (_uid == null) return;

    await FirebaseFirestore.instance
        .collection('user')
        .doc(_uid)
        .set({'wishlist': _wishlist}, SetOptions(merge: true));
  }

  Future<void> toggleWishlist(String docId) async {
    final productRef =
        FirebaseFirestore.instance.collection('products').doc(docId);

    final productSnapshot = await productRef.get();
    final data = productSnapshot.data() as Map<String, dynamic>?;

    int currentLikes = data?['likes'] ?? 0;

    if (_wishlist.contains(docId)) {
      _wishlist.remove(docId);

      await productRef.update({
        "likes": currentLikes > 0 ? currentLikes - 1 : 0,
      });
    } else {
      _wishlist.add(docId);

      await productRef.update({
        "likes": currentLikes + 1,
      });
    }

    await saveWishlist();
    notifyListeners();
  }

  bool isInWishlist(String docId) {
    return _wishlist.contains(docId);
  }
}
