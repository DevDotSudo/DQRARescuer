// controllers/map_controller.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rescuer/model/emergency_model.dart';
import 'package:rescuer/services/location_service.dart';
import 'package:rescuer/services/route_service.dart';

class MapController {
  final LocationService _locationService;
  final RouteService _routeService;
  
  LatLng? currentLocation;
  String formattedLocation = '';
  Emergency? emergency;
  List<LatLng> routePoints = [];
  String? errorMessage;

  MapController({
    required LocationService locationService,
    required RouteService routeService,
  }) : _locationService = locationService,
       _routeService = routeService;

  Future<void> initializeLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      currentLocation = LatLng(position.latitude, position.longitude);
      formattedLocation = _locationService.formatPosition(position);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to get location: $e';
      rethrow;
    }
  }

  Future<void> loadEmergencyRoute(Emergency emergency) async {
    try {
      await initializeLocation();
      this.emergency = emergency;
      
      routePoints = await _routeService.getRoutePoints(
        currentLocation!,
        LatLng(emergency.location.latitude, emergency.location.longitude),
      );
      
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load route: $e';
      rethrow;
    }
  }

  Set<Marker> getMarkers() {
    final markers = <Marker>{};
    
    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    if (emergency != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('emergency_location'),
          position: LatLng(emergency!.location.latitude, emergency!.location.longitude),
          infoWindow: InfoWindow(
            title: 'Emergency Location',
            snippet: '${emergency!.userName}\n${emergency!.userAddress}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> getPolylines() {
    if (routePoints.isEmpty) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      ),
    };
  }

  LatLngBounds? getBounds() {
    if (currentLocation == null || emergency == null) return null;
    
    return LatLngBounds(
      southwest: LatLng(
        min(currentLocation!.latitude, emergency!.location.latitude),
        min(currentLocation!.longitude, emergency!.location.longitude),
      ),
      northeast: LatLng(
        max(currentLocation!.latitude, emergency!.location.latitude),
        max(currentLocation!.longitude, emergency!.location.longitude),
      ),
    );
  }
}