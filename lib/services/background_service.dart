import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:rescuer/model/rescuer_model.dart';

class BackgroundService {
  static const MethodChannel _channel = MethodChannel('com.dqra.rescuer/main');
  static const EventChannel _emergencyChannel = 
      EventChannel('com.dqra.rescuer/emergency');

  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      debugPrint("Failed to initialize background service: ${e.message}");
      rethrow;
    }
  }

  Future<void> startService(Rescuer rescuer) async {
    try {
      await _channel.invokeMethod('startBackgroundService', {
        'municipality': rescuer.municipality,
        'rescuerName': rescuer.username,
        'rescuerData': rescuer.toMap(), // Send full rescuer data if needed
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to start service: ${e.message}");
      rethrow;
    }
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopBackgroundService');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop service: ${e.message}");
      rethrow;
    }
  }

  Stream<dynamic> get emergencyStream {
    return _emergencyChannel.receiveBroadcastStream().handleError((error) {
      debugPrint("Emergency stream error: $error");
    });
  }
}