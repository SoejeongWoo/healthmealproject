import 'package:flutter/material.dart';

class DropDownProvider extends ChangeNotifier {
  String sortOption = "desc";

  void setSortOption(String value) {
    sortOption = value;
    notifyListeners();
  }
}
