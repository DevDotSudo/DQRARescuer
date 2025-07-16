import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteService {
  static const String _apiKey = 'AIzaSyBOAWJ-Se49ja1_41m5dNtPJbpelf0raqo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?'
            'origin=${origin.latitude},${origin.longitude}&'
            'destination=${destination.latitude},${destination.longitude}&'
            'key=$_apiKey&'
            'mode=driving'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final points = data['routes'][0]['overview_polyline']['points'];
          return PolylinePoints().decodePolyline(points)
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to load directions');
      }
    } catch (e) {
      throw Exception('Routing error: $e');
    }
  }
} 