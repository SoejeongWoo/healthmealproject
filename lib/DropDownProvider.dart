import 'package:flutter/material.dart';

class DropDownProvider extends ChangeNotifier {
  String sortOption = "recent";

  void setSortOption(String value) {
    sortOption = value;
    notifyListeners();
  }
}
