import 'package:flutter/material.dart';

class LoginProvider extends ChangeNotifier {
  String loginType = "none";
  String userName = "";

  void setGoogleUser(String name) {
    loginType = "google";
    userName = name;
    notifyListeners();
  }

  void setEmailUser(String email) {
    loginType = "email";
    userName = email;
    notifyListeners();
  }

  void reset() {
    loginType = "none";
    userName = "";
    notifyListeners();
  }
}
