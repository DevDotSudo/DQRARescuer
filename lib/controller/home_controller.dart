import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rescuer/model/emergency_model.dart';
import 'package:rescuer/model/rescuer_model.dart';
import 'package:rescuer/services/emergency_services.dart';

class HomeController {
  final EmergencyService emergencyService;
  final Rescuer currentRescuer;
  
  HomeController({
    required this.emergencyService,
    required this.currentRescuer,
  });

  Stream<List<Emergency>> getPendingEmergencies() {
    return emergencyService.getEmergenciesByMunicipalityAndUsername(
      municipality:  currentRescuer.municipality,
      name: currentRescuer.fullName,
      status: 'pending',
    );
  }

  String formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) return 'Unknown time';
  final dt = timestamp.toDate();
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
         '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

  
  Stream<List<Emergency>> getOngoingEmergencies() {
    return emergencyService.getEmergenciesByMunicipalityAndUsername(
      municipality:  currentRescuer.municipality,
      name: currentRescuer.fullName,
      status: 'ongoing',
    );
  }

  Stream<List<Emergency>> getCompletedEmergencies() {
    return emergencyService.getEmergenciesByMunicipalityAndUsername(
      municipality:  currentRescuer.municipality,
      name: currentRescuer.fullName,
      status: 'completed',
    );
  }

  Future<void> acceptEmergency(String emergencyId) async {
    await emergencyService.updateEmergencyStatus(
      municipality: currentRescuer.municipality,
      emergencyId: emergencyId,
      status: 'ongoing',
      rescuerId: currentRescuer.username,
      rescuerName: currentRescuer.fullName,
    );
  }

  Future<void> completeEmergency(String emergencyId) async {
    await emergencyService.updateEmergencyStatus(
      municipality: currentRescuer.municipality,
      emergencyId: emergencyId,
      status: 'completed',
      rescuerId: currentRescuer.username,
      rescuerName: currentRescuer.fullName,
    );
  }
}