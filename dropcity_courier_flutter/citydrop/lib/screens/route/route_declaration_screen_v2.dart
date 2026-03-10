import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Enhanced Route Declaration Screen with Maps
class RouteDeclarationScreenV2 extends ConsumerStatefulWidget {
  const RouteDeclarationScreenV2({Key? key}) : super(key: key);

  @override
  ConsumerState<RouteDeclarationScreenV2> createState() =>
      _RouteDeclarationScreenV2State();
}

class _RouteDeclarationScreenV2State extends ConsumerState<RouteDeclarationScreenV2> {
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // Default coordinates (San Francisco)
  static const LatLng defaultLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController();
    _destinationController = TextEditingController();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addMarker(LatLng position, String id, String title) {
    setState(() {
      markers.removeWhere((m) => m.markerId.value == id);
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            id == 'origin'
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
        ),
      );

      // Draw polyline if both markers exist
      if (markers.length == 2) {
        final originMarker =
            markers.firstWhere((m) => m.markerId.value == 'origin');
        final destMarker =
            markers.firstWhere((m) => m.markerId.value == 'destination');

        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [originMarker.position, destMarker.position],
            color: Colors.blue,
            width: 5,
          ),
        );

        // Animate camera to show both markers
        final bounds = LatLngBounds(
          southwest: LatLng(
            [originMarker.position.latitude, destMarker.position.latitude]
                .reduce((a, b) => a < b ? a : b),
            [originMarker.position.longitude, destMarker.position.longitude]
                .reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            [originMarker.position.latitude, destMarker.position.latitude]
                .reduce((a, b) => a > b ? a : b),
            [originMarker.position.longitude, destMarker.position.longitude]
                .reduce((a, b) => a > b ? a : b),
          ),
        );
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    });
  }

  void _startRoute() {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both origin and destination')),
      );
      return;
    }

    if (markers.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both locations on the map')),
      );
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route declared successfully!')),
    );

    // Navigate to matching screen
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go('/matching');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Declare Your Route'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 1,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: defaultLocation,
                zoom: 15,
              ),
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: true,
              onLongPress: (LatLng position) {
                if (markers.length == 0) {
                  _addMarker(position, 'origin', 'Origin');
                  _originController.text = 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
                } else if (markers.length == 1) {
                  _addMarker(position, 'destination', 'Destination');
                  _destinationController.text = 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
                } else {
                  // Clear and start fresh
                  setState(() {
                    markers.clear();
                    polylines.clear();
                  });
                  _originController.clear();
                  _destinationController.clear();
                  _addMarker(position, 'origin', 'Origin');
                  _originController.text = 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
                }
              },
            ),
          ),

          // Form Section
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Long press on the map to select origin and destination',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Origin Field
                  Text(
                    'Origin',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _originController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Long press on map',
                      prefixIcon: const Icon(Icons.location_on),
                      prefixIconColor: Colors.green,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Destination Field
                  Text(
                    'Destination',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destinationController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Long press on map',
                      prefixIcon: const Icon(Icons.location_on),
                      prefixIconColor: Colors.red,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status Indicator
                  if (markers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${markers.length}/2 locations selected',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Start Route Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _startRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text(
                            'Start Route',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
