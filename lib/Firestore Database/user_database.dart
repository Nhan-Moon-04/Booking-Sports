import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class UserDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }
}