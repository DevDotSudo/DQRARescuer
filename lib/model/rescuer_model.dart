// models/rescuer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Rescuer {
  final String username;
  final String password;
  final String fullName;
  final String contactNumber;
  final String address;
  final String municipality;
  final String gender;
  final int age;
  final DateTime createdAt;

  Rescuer({
    required this.username,
    required this.password,
    required this.fullName,
    required this.contactNumber,
    required this.address,
    required this.municipality,
    required this.gender,
    required this.age,
    required this.createdAt,
  });

  factory Rescuer.fromMap(Map<String, dynamic> data) {
    return Rescuer(
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      fullName: data['fullName'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      address: data['address'] ?? '',
      municipality: data['municipality'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'fullName': fullName,
      'contactNumber': contactNumber,
      'address': address,
      'municipality': municipality,
      'gender': gender,
      'age': age,
      'createdAt': createdAt,
    };
  }
}