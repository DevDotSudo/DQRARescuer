import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  String formatPosition(Position position) {
    final lat = position.latitude;
    final lng = position.longitude;
    final latDirection = lat >= 0 ? 'N' : 'S';
    final lngDirection = lng >= 0 ? 'E' : 'W';
    
    return '[${lat.abs().toStringAsFixed(7)}° $latDirection, '
           '${lng.abs().toStringAsFixed(7)}° $lngDirection]';
  }
}