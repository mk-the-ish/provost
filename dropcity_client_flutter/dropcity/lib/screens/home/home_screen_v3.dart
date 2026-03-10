import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import '../../providers/delivery_tracking_provider.dart';

class HomeScreenV3 extends ConsumerStatefulWidget {
  const HomeScreenV3({super.key});

  @override
  ConsumerState<HomeScreenV3> createState() => _HomeScreenV3State();
}

class _HomeScreenV3State extends ConsumerState<HomeScreenV3> {
  GoogleMapController? _mapController;
  final Logger _logger = Logger();

  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = <Polyline>{};

  LatLng? _pickupLocation;
  String? _pickupAddress;
  LatLng? _dropoffLocation;
  String? _dropoffAddress;

  bool _isLoadingLocation = false;
  int _selectionMode = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() {
        _addOrReplaceMarker(
          markerId: 'my-location',
          position: currentLatLng,
          title: 'My Location',
          hue: BitmapDescriptor.hueBlue,
        );
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15),
      );
    } catch (e) {
      _logger.e('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _addOrReplaceMarker({
    required String markerId,
    required LatLng position,
    required String title,
    required double hue,
  }) {
    _markers.removeWhere((m) => m.markerId.value == markerId);
    _markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ),
    );
  }

  void _updateCourierMarker(LatLng courierPosition) {
    setState(() {
      _addOrReplaceMarker(
        markerId: 'courier',
        position: courierPosition,
        title: 'Courier Location',
        hue: BitmapDescriptor.hueYellow,
      );
    });
  }

  void _onMapTap(LatLng latLng) {
    if (_selectionMode == 0) {
      setState(() {
        _pickupLocation = latLng;
        _pickupAddress =
            '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
        _addOrReplaceMarker(
          markerId: 'pickup',
          position: latLng,
          title: 'Pickup',
          hue: BitmapDescriptor.hueGreen,
        );
        _selectionMode = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Now tap the map to select dropoff location'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectionMode == 1) {
      setState(() {
        _dropoffLocation = latLng;
        _dropoffAddress =
            '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
        _addOrReplaceMarker(
          markerId: 'dropoff',
          position: latLng,
          title: 'Dropoff',
          hue: BitmapDescriptor.hueRed,
        );
        _selectionMode = -1;
        _drawRoute();
      });
    }
  }

  void _drawRoute() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      return;
    }

    _polylines
      ..clear()
      ..add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: <LatLng>[_pickupLocation!, _dropoffLocation!],
          color: Colors.blue,
          width: 5,
          geodesic: true,
        ),
      );
  }

  double _calculateDistance() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      return 0;
    }

    final meters = Geolocator.distanceBetween(
      _pickupLocation!.latitude,
      _pickupLocation!.longitude,
      _dropoffLocation!.latitude,
      _dropoffLocation!.longitude,
    );

    return meters / 1000;
  }

  void _proceedToCreateOrder() {
    if (_pickupLocation == null || _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and dropoff')),
      );
      return;
    }

    context.push('/order/create', extra: {
      'pickupLocation': {
        'latitude': _pickupLocation!.latitude,
        'longitude': _pickupLocation!.longitude,
      },
      'pickupAddress': _pickupAddress,
      'dropoffLocation': {
        'latitude': _dropoffLocation!.latitude,
        'longitude': _dropoffLocation!.longitude,
      },
      'dropoffAddress': _dropoffAddress,
      'estimatedDistance': _calculateDistance(),
    });
  }

  void _resetSelections() {
    setState(() {
      _pickupLocation = null;
      _dropoffLocation = null;
      _pickupAddress = null;
      _dropoffAddress = null;
      _selectionMode = 0;
      _polylines.clear();
      _markers.removeWhere(
        (m) =>
            m.markerId.value == 'pickup' ||
            m.markerId.value == 'dropoff' ||
            m.markerId.value == 'courier',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final courierLocation = ref.watch(courierLocationProvider);
    final activeDelivery = ref.watch(deliveryTrackingProvider);

    if (courierLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _updateCourierMarker(
          LatLng(courierLocation.latitude, courierLocation.longitude),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Pickup & Dropoff'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        actions: [
          if (activeDelivery != null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'Courier On Way',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            onTap: activeDelivery == null ? _onMapTap : null,
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.7749, -122.4194),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            trafficEnabled: false,
            zoomControlsEnabled: true,
          ),
          if (_selectionMode >= 0)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectionMode == 0 ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectionMode == 0
                      ? 'Tap to select PICKUP'
                      : 'Tap to select DROPOFF',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_pickupLocation != null || _dropoffLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_pickupLocation != null) ...[
                      const Text('Pickup Location'),
                      Text(_pickupAddress ?? ''),
                      const SizedBox(height: 8),
                    ],
                    if (_dropoffLocation != null) ...[
                      const Text('Dropoff Location'),
                      Text(_dropoffAddress ?? ''),
                      const SizedBox(height: 8),
                      Text(
                        'Distance: ${_calculateDistance().toStringAsFixed(2)} km',
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetSelections,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _proceedToCreateOrder,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
