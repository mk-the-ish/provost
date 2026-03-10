import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bottom_tracking_card_widget.dart';
import './widgets/courier_info_widget.dart';
import './widgets/delivery_status_widget.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  const LiveTrackingMapScreen({super.key});

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Mock order data
  final Map<String, dynamic> _orderData = {
    "orderId": "ORD-2026-0305-001",
    "status": "IN_TRANSIT",
    "courierName": "James Wilson",
    "courierPhone": "+1 (555) 234-5678",
    "courierAvatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_183f5ab63-1763296652710.png",
    "courierAvatarLabel":
        "Professional photo of a courier man with short dark hair wearing a blue delivery jacket",
    "estimatedArrival": "12 min",
    "pickupAddress": "123 Main Street, Downtown, NY 10001",
    "deliveryAddress": "456 Park Avenue, Midtown, NY 10022",
    "deliveryPin": "7284",
    "sizeCategory": "MEDIUM",
    "pickupPhotoUrl":
        "https://img.rocket.new/generatedImages/rocket_gen_img_1e68ad380-1772714304134.png",
    "pickupPhotoLabel":
        "A cardboard package sealed with tape sitting on a wooden table ready for pickup",
  };

  static const LatLng _pickupLocation = LatLng(40.7128, -74.0060);
  static const LatLng _destinationLocation = LatLng(40.7580, -73.9855);

  // Simulated courier positions for demo
  final List<LatLng> _courierPath = [
    LatLng(40.7200, -74.0010),
    LatLng(40.7250, -73.9980),
    LatLng(40.7300, -73.9950),
    LatLng(40.7350, -73.9920),
    LatLng(40.7400, -73.9900),
    LatLng(40.7450, -73.9880),
    LatLng(40.7500, -73.9870),
  ];

  int _courierPathIndex = 0;
  LatLng _courierLocation = LatLng(40.7200, -74.0010);
  Timer? _locationTimer;

  final Set<Marker> _markers = {};
  final bool _isExpanded = false;
  String _currentStatus = "IN_TRANSIT";

  final List<Map<String, dynamic>> _statusTimeline = [
    {
      "status": "PENDING",
      "label": "Order Placed",
      "time": "10:30 AM",
      "done": true,
    },
    {
      "status": "MATCHED",
      "label": "Courier Matched",
      "time": "10:35 AM",
      "done": true,
    },
    {
      "status": "IN_TRANSIT",
      "label": "In Transit",
      "time": "10:50 AM",
      "done": true,
    },
    {"status": "DELIVERED", "label": "Delivered", "time": "--", "done": false},
  ];

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _startCourierSimulation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _setupMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('courier'),
        position: _courierLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Courier'),
      ),
    );
  }

  void _startCourierSimulation() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (_courierPathIndex < _courierPath.length - 1) {
        _courierPathIndex++;
        setState(() {
          _courierLocation = _courierPath[_courierPathIndex];
          _markers.removeWhere((m) => m.markerId.value == 'courier');
          _markers.add(
            Marker(
              markerId: const MarkerId('courier'),
              position: _courierLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: const InfoWindow(title: 'Courier'),
            ),
          );
        });
        _autoZoom();
      } else {
        timer.cancel();
        if (mounted) {
          setState(() => _currentStatus = "DELIVERED");
        }
      }
    });
  }

  void _autoZoom() {
    if (_mapController == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        [
              _pickupLocation.latitude,
              _destinationLocation.latitude,
              _courierLocation.latitude,
            ].reduce((a, b) => a < b ? a : b) -
            0.005,
        [
              _pickupLocation.longitude,
              _destinationLocation.longitude,
              _courierLocation.longitude,
            ].reduce((a, b) => a < b ? a : b) -
            0.005,
      ),
      northeast: LatLng(
        [
              _pickupLocation.latitude,
              _destinationLocation.latitude,
              _courierLocation.latitude,
            ].reduce((a, b) => a > b ? a : b) +
            0.005,
        [
              _pickupLocation.longitude,
              _destinationLocation.longitude,
              _courierLocation.longitude,
            ].reduce((a, b) => a > b ? a : b) +
            0.005,
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  void _centerOnCurrentLocation() {
    _autoZoom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(40.7350, -73.9930),
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 500), _autoZoom);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed('/create-order-screen'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.elevationShadow2,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: theme.colorScheme.onSurface,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.2.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: AppTheme.radiusMedium,
                        boxShadow: AppTheme.elevationShadow2,
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'local_shipping',
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Order #${_orderData["orderId"]}',
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusChip(status: _currentStatus),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zoom / location controls
          Positioned(
            right: 4.w,
            bottom: 32.h,
            child: Column(
              children: [
                _MapControlButton(
                  iconName: 'my_location',
                  onTap: _centerOnCurrentLocation,
                  theme: theme,
                ),
                SizedBox(height: 1.h),
                _MapControlButton(
                  iconName: 'add',
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  theme: theme,
                ),
                SizedBox(height: 0.5.h),
                _MapControlButton(
                  iconName: 'remove',
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  theme: theme,
                ),
              ],
            ),
          ),

          // Bottom draggable sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.18,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: AppTheme.elevationShadow3,
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CourierInfoWidget(
                            orderData: _orderData,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),
                          BottomTrackingCardWidget(
                            orderData: _orderData,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),
                          DeliveryStatusWidget(
                            statusTimeline: _statusTimeline,
                            currentStatus: _currentStatus,
                            theme: theme,
                          ),
                          SizedBox(height: 2.h),
                          // Proof of condition
                          (_currentStatus == "DELIVERED" ||
                                  _currentStatus == "PICKED_UP")
                              ? _ProofOfConditionWidget(
                                  photoUrl:
                                      _orderData["pickupPhotoUrl"] as String,
                                  photoLabel:
                                      _orderData["pickupPhotoLabel"] as String,
                                  theme: theme,
                                )
                              : const SizedBox.shrink(),
                          SizedBox(height: 3.h),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Calling courier...'),
                                      ),
                                    );
                                  },
                                  icon: CustomIconWidget(
                                    iconName: 'phone',
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                  label: const Text('Call'),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Opening chat...'),
                                      ),
                                    );
                                  },
                                  icon: CustomIconWidget(
                                    iconName: 'chat',
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text('Message'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'PENDING':
        color = AppTheme.warningColor;
        label = 'Pending';
        break;
      case 'MATCHED':
        color = AppTheme.primaryLight;
        label = 'Matched';
        break;
      case 'IN_TRANSIT':
        color = AppTheme.successColor;
        label = 'In Transit';
        break;
      case 'DELIVERED':
        color = AppTheme.successColor;
        label = 'Delivered';
        break;
      default:
        color = AppTheme.secondaryLight;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;
  final ThemeData theme;
  const _MapControlButton({
    required this.iconName,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: AppTheme.elevationShadow2,
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ProofOfConditionWidget extends StatelessWidget {
  final String photoUrl;
  final String photoLabel;
  final ThemeData theme;
  const _ProofOfConditionWidget({
    required this.photoUrl,
    required this.photoLabel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proof of Condition', style: theme.textTheme.titleSmall),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: AppTheme.radiusMedium,
          child: CustomImageWidget(
            imageUrl: photoUrl,
            width: double.infinity,
            height: 15.h,
            fit: BoxFit.cover,
            semanticLabel: photoLabel,
          ),
        ),
      ],
    );
  }
}
