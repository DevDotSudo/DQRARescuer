// screens/rescuer/rescuer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:rescuer/model/rescuer_model.dart';

class RescuerHomeScreen extends StatelessWidget {
  final Rescuer currentRescuer;

  const RescuerHomeScreen({super.key, required this.currentRescuer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${currentRescuer.fullName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Implement logout functionality
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Municipality: ${currentRescuer.municipality}'),
            Text('Contact: ${currentRescuer.contactNumber}'),
            // Add more rescuer-specific UI components here
          ],
        ),
      ),
    );
  }
}