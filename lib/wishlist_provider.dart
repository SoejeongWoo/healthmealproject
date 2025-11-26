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

  // Firestore에서 wishlist 불러오기 (🔥 안전 버전)
  Future<void> loadWishlist() async {
    if (_uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('user').doc(_uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // 문서 자체가 없으면 생성
      await docRef.set({'wishlist': []});
      _wishlist = [];
      notifyListeners();
      return;
    }

    final data = doc.data() as Map<String, dynamic>?;

    // 🔥 wishlist 필드 자체가 없거나 null이면 자동으로 복구
    final rawWishlist = data?['wishlist'];
    if (rawWishlist == null || rawWishlist is! List) {
      _wishlist = [];
      await docRef.set({'wishlist': []}, SetOptions(merge: true));
    } else {
      _wishlist = List<String>.from(rawWishlist);
    }

    notifyListeners();
  }

  // Firestore에 저장
  Future<void> saveWishlist() async {
    if (_uid == null) return;

    await FirebaseFirestore.instance
        .collection('user')
        .doc(_uid)
        .set({'wishlist': _wishlist}, SetOptions(merge: true));
  }

  // ❤️ 좋아요 + 위시리스트 toggle (좋아요 증가/감소 포함)
  Future<void> toggleWishlist(String docId) async {
    final productRef =
        FirebaseFirestore.instance.collection('products').doc(docId);

    final productSnapshot = await productRef.get();
    final data = productSnapshot.data() as Map<String, dynamic>?;

    int currentLikes = data?['likes'] ?? 0;

    // 이미 좋아요 상태 → 좋아요 -1
    if (_wishlist.contains(docId)) {
      _wishlist.remove(docId);

      await productRef.update({
        "likes": currentLikes > 0 ? currentLikes - 1 : 0,
      });
    }
    // 좋아요 추가 → 좋아요 +1
    else {
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
