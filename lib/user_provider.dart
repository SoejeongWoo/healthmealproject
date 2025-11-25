import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String name = "";
  String email = "";
  String uid = "";
  String statusMessage = "";
  bool isEditing = false;

  static const String defaultMessage =
      "I promise to take the test honestly before God.";

  Future<void> loadUser(String userId) async {
    uid = userId;

    final doc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();

    if (doc.exists) {
      final data = doc.data()!;

      // 🔥 anonymous 제거 → 항상 실제 이메일/이름 사용
      name = data['name'] ?? "";
      email = data['email'] ?? "";
      uid = data['uid'] ?? userId;

      statusMessage = (data['status_message'] == null ||
              data['status_message'].toString().trim().isEmpty)
          ? defaultMessage
          : data['status_message'];
    } else {
      await FirebaseFirestore.instance.collection('user').doc(userId).set({
        "name": "",
        "email": "",
        "uid": userId,
        "status_message": defaultMessage,
      });

      statusMessage = defaultMessage;
    }

    notifyListeners();
  }

  void startEditing() {
    isEditing = true;
    notifyListeners();
  }

  void updateStatus(String newMessage) {
    statusMessage = newMessage;
    notifyListeners();
  }

  Future<void> saveStatus() async {
    await FirebaseFirestore.instance.collection('user').doc(uid).update({
      'status_message': statusMessage,
    });
    isEditing = false;
    notifyListeners();
  }
}
