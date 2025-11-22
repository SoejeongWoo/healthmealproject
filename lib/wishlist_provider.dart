import 'package:flutter/material.dart';

class WishlistProvider extends ChangeNotifier {
  final List<String> _wishlist = [];

  List<String> get wishlist => _wishlist;

  bool isInWishlist(String docId) {
    return _wishlist.contains(docId);
  }

  void toggleWishlist(String docId) {
    if (_wishlist.contains(docId)) {
      _wishlist.remove(docId);
    } else {
      _wishlist.add(docId);
    }
    notifyListeners();
  }
}
