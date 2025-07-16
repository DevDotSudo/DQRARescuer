import 'package:flutter/services.dart';

class NativeService {
  static const _channel = MethodChannel('com.dqra.rescuer/main');

  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startBackgroundService');
    } on PlatformException catch (e) {
      print("Failed to start service: ${e.message}");
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopBackgroundService');
    } on PlatformException catch (e) {
      print("Failed to stop service: ${e.message}");
    }
  }
}
