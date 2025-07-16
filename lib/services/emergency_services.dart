import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescuer/model/emergency_model.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Emergency>> getEmergenciesByMunicipalityAndUsername({
    required String municipality,
    required String name,
    String? status,
  }) {
    var query = _firestore
        .collection('EMERGENCY')
        .doc(municipality)
        .collection('LISTS')
        .where('rescuerName', isEqualTo: name)
        .orderBy('timestamp', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => Emergency.fromMap(doc.data(), doc.id))
              .toList(),
    );
  }

  Future<void> updateEmergencyStatus({
    required String municipality,
    required String emergencyId,
    required String status,
    required String rescuerId,
    required String rescuerName,
  }) async {
    await _firestore
        .collection('EMERGENCY')
        .doc(municipality)
        .collection('LISTS')
        .doc(emergencyId)
        .update({
          'status': status,
          'rescuerId': rescuerId,
          'rescuerName': rescuerName,
        });
  }

  StreamSubscription listenForNewEmergencies({
    required String municipality,
    required String rescuerName,
    required Function(Emergency) onNewEmergency,
  }) {
    return FirebaseFirestore.instance
        .collection('EMERGENCY')
        .doc(municipality)
        .collection('LISTS')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .limit(1) // get only the latest one
        .snapshots()
        .listen((snapshot) {
          for (var docChange in snapshot.docChanges) {
            if (docChange.type == DocumentChangeType.added) {
              final data = docChange.doc.data();
              if (data != null) {
                final emergency = Emergency.fromMap(data, docChange.doc.id);
                if (emergency.status == 'pending') {
                  onNewEmergency(emergency);
                }
              }
            }
          }
        });
  }
}
