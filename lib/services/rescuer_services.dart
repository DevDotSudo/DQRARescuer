// services/rescuer_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescuer/model/rescuer_model.dart';

class RescuerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> usernameExists(String username) async {
    final snapshot = await _firestore
        .collection('ADMINS')
        .doc('RESCUERS')
        .collection('LISTS')
        .where('username', isEqualTo: username)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  
  Future<String?> getPasswordByUsername(String username) async {
    final snapshot = await _firestore
        .collection('ADMINS')
        .doc('RESCUERS')
        .collection('LISTS')
        .where('username', isEqualTo: username)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['password'];
    }
    return null;
  }

  Future<Rescuer?> getRescuerByUsername(String username) async {
    final snapshot = await _firestore
        .collection('ADMINS')
        .doc('RESCUERS')
        .collection('LISTS')
        .where('username', isEqualTo: username)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return Rescuer.fromMap(snapshot.docs.first.data());
    }
    return null;
  }
}