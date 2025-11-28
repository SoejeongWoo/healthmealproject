import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String name = "";
  String email = "";
  String uid = "";
  String statusMessage = "";
  bool isEditing = false;

  static const String defaultMessage = "맛있고 건강한 음식을 공유해봐요~";

  Future<void> loadUser(String userId) async {
    uid = userId;

    final doc =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();

    if (doc.exists) {
      final data = doc.data()!;

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

  void updateName(String newName) {
    name = newName;
    notifyListeners();
  }

  Future<void> saveAll() async {
    if (uid.isEmpty) return;

    await FirebaseFirestore.instance.collection('user').doc(uid).set(
      {
        "name": name,
        "email": email,
        "status_message": statusMessage,
        "uid": uid,
      },
      SetOptions(merge: true),
    );

    isEditing = false;
    notifyListeners();
  }
}
