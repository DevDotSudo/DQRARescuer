import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rescuer/controller/map_controller.dart';
import 'package:rescuer/model/emergency_model.dart';
import 'package:rescuer/services/location_service.dart';
import 'package:rescuer/services/route_service.dart';

class MapDialog extends StatefulWidget {
  final Emergency? emergency;
  
  const MapDialog({
    super.key,
    this.emergency,
  });

  @override
  State<MapDialog> createState() => _MapDialogState();
}

class _MapDialogState extends State<MapDialog> {
  late final MapController _controller;
  late GoogleMapController _mapController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = MapController(
      locationService: LocationService(),
      routeService: RouteService(),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.emergency != null) {
        await _controller.loadEmergencyRoute(widget.emergency!);
      } else {
        await _controller.initializeLocation();
      }
      
      if (_controller.currentLocation != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_controller.currentLocation!, 15),
        );
      }
      
      if (widget.emergency != null && _controller.currentLocation != null) {
        final bounds = _controller.getBounds();
        if (bounds != null) {
          _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_controller.errorMessage ?? e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.emergency != null 
                                ? 'Emergency Navigation' 
                                : 'Your Location',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  if (widget.emergency != null) _buildEmergencyCard(theme),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          GoogleMap(
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            initialCameraPosition: CameraPosition(
                              target: _controller.currentLocation ?? 
                                    (widget.emergency != null 
                                      ? LatLng(
                                          widget.emergency!.location.latitude,
                                          widget.emergency!.location.longitude)
                                      : const LatLng(0, 0)),
                              zoom: 15,
                            ),
                            markers: _controller.getMarkers(),
                            polylines: _controller.getPolylines(),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            padding: const EdgeInsets.only(bottom: 60),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton.small(
                              backgroundColor: colorScheme.surface,
                              onPressed: () {
                                if (_controller.currentLocation != null) {
                                  _mapController.animateCamera(
                                    CameraUpdate.newLatLng(
                                      _controller.currentLocation!),
                                  );
                                }
                              },
                              child: Icon(
                                Icons.my_location,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(ThemeData theme) {
    if (widget.emergency == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.emergency!.status),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(widget.emergency!.status),
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.emergency!.userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatTime(widget.emergency!.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, widget.emergency!.userContact),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.location_on, widget.emergency!.userAddress),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.info_outline, 
                'Status: ${widget.emergency!.status.toUpperCase()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'ongoing':
        return Icons.directions_run;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.warning;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}