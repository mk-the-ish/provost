import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/courier_providers.dart';

/// Delivery Tracking Screen with Google Maps
class DeliveryTrackingScreenV2 extends ConsumerStatefulWidget {
  const DeliveryTrackingScreenV2({Key? key}) : super(key: key);

  @override
  ConsumerState<DeliveryTrackingScreenV2> createState() =>
      _DeliveryTrackingScreenV2State();
}

class _DeliveryTrackingScreenV2State
    extends ConsumerState<DeliveryTrackingScreenV2> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _loadDeliveryMarkers();
  }

  void _loadDeliveryMarkers() {
    final job = ref.watch(activeDeliveryJobProvider);

    job.whenData((jobData) {
      if (jobData == null) return;

      setState(() {
        markers.clear();
        polylines.clear();

        // Pickup location marker
        final pickupLat = (jobData['pickup_lat'] ?? 0.0) as double;
        final pickupLng = (jobData['pickup_lng'] ?? 0.0) as double;

        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(pickupLat, pickupLng),
            infoWindow: InfoWindow(
              title: 'Pickup',
              snippet: jobData['pickup_location'] ?? 'Pickup Location',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );

        // Dropoff location marker
        final dropoffLat = (jobData['dropoff_lat'] ?? 0.0) as double;
        final dropoffLng = (jobData['dropoff_lng'] ?? 0.0) as double;

        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: LatLng(dropoffLat, dropoffLng),
            infoWindow: InfoWindow(
              title: 'Dropoff',
              snippet: jobData['dropoff_location'] ?? 'Dropoff Location',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );

        // Draw polyline between pickup and dropoff
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(pickupLat, pickupLng),
              LatLng(dropoffLat, dropoffLng),
            ],
            color: Colors.blue,
            width: 5,
          ),
        );

        // Animate camera to show both markers
        if (pickupLat != 0 && pickupLng != 0) {
          final bounds = LatLngBounds(
            southwest:
                LatLng(pickupLat.clamp(-90, 90), pickupLng.clamp(-180, 180)),
            northeast:
                LatLng(dropoffLat.clamp(-90, 90), dropoffLng.clamp(-180, 180)),
          );
          mapController.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(activeDeliveryJobProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Tracking'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: job.when(
        data: (jobData) {
          if (jobData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Delivery',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accept an order to start tracking',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Google Maps
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    jobData['pickup_lat'] ?? 0.0,
                    jobData['pickup_lng'] ?? 0.0,
                  ),
                  zoom: 15,
                ),
                markers: markers,
                polylines: polylines,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
              ),

              // Delivery Info Card
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery Status',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(jobData['status']),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              jobData['status']?.toUpperCase() ?? 'UNKNOWN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLocationRow(
                        'From',
                        jobData['pickup_location'] ?? 'Unknown',
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildLocationRow(
                        'To',
                        jobData['dropoff_location'] ?? 'Unknown',
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Mark as delivered
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Delivery marked as completed'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                          ),
                          child: const Text('Mark as Delivered'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error loading delivery',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading delivery...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLocationRow(
    String label,
    String location,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            label == 'From' ? Icons.location_on : Icons.location_on_outlined,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
