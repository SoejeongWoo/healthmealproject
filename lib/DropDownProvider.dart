import 'package:flutter/material.dart';

class DropDownProvider extends ChangeNotifier {
  String sortOption = "recent"; // 기본: 최신순

  void setSortOption(String value) {
    sortOption = value;
    notifyListeners();
  }
}
