import 'package:cloud_firestore/cloud_firestore.dart';

class Emergency {
  final String id;
  final GeoPoint location;
  final String municipality;
  final String? rescuerId;
  final String? rescuerName;
  final String status;
  final Timestamp timestamp;
  final String userAddress;
  final String userContact;
  final String userName;
  final String emergencyType;
  final String emergencyDescription;
  
  Emergency({
    required this.id,
    required this.location,
    required this.municipality,
    required this.emergencyType,
    required this.emergencyDescription,
    this.rescuerId,
    this.rescuerName,
    required this.status,
    required this.timestamp,
    required this.userAddress,
    required this.userContact,
    required this.userName,
  });

  factory Emergency.fromMap(Map<String, dynamic> data, String id) {
    return Emergency(
      id: id,
      location: data['location'] ?? '',
      municipality: data['municipality'] ?? '',
      rescuerId: data['rescuerId'],
      rescuerName: data['rescuerName'],
      status: data['status'] ?? 'pending',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      userAddress: data['userAddress'] ?? '',
      userContact: data['userContact'] ?? '',
      userName: data['userName'] ?? '',
      emergencyType: data['emergencyType'] ?? '',
      emergencyDescription: data['emergencyDescription'] ?? ''

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'municipality': municipality,
      'rescuerId': rescuerId,
      'rescuerName': rescuerName,
      'status': status,
      'timestamp': timestamp,
      'userAddress': userAddress,
      'userContact': userContact,
      'userName': userName,
      'emergencyType': emergencyType,
      'emergencyDescription': emergencyDescription,
    };
  }

  DateTime get createdAt => timestamp.toDate();
}