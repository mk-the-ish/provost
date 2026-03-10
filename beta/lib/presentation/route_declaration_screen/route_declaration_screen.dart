import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/order_bottom_sheet_widget.dart';
import './widgets/order_card_widget.dart';
import './widgets/route_search_bar_widget.dart';

class RouteDeclarationScreen extends StatefulWidget {
  const RouteDeclarationScreen({super.key});

  @override
  State<RouteDeclarationScreen> createState() => _RouteDeclarationScreenState();
}

class _RouteDeclarationScreenState extends State<RouteDeclarationScreen> {
  GoogleMapController? _mapController;
  LatLng? _startLocation;
  LatLng? _endLocation;
  bool _isSelectingStart = true;
  bool _routeDeclared = false;
  bool _isOffline = false;
  bool _isLoading = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final List<Map<String, dynamic>> _matchedOrders = [
    {
      "id": "ORD-001",
      "sizeCategory": "Medium",
      "pickupAddress": "123 Main St, Downtown, NY 10001",
      "deliveryAddress": "456 Park Ave, Midtown, NY 10022",
      "lat": 40.7128,
      "lng": -74.0060,
      "recipientName": "Alice Johnson",
      "weight": "2.5 kg",
    },
    {
      "id": "ORD-002",
      "sizeCategory": "Small",
      "pickupAddress": "789 Broadway, SoHo, NY 10012",
      "deliveryAddress": "321 5th Ave, Flatiron, NY 10016",
      "lat": 40.7228,
      "lng": -73.9980,
      "recipientName": "Bob Martinez",
      "weight": "0.8 kg",
    },
    {
      "id": "ORD-003",
      "sizeCategory": "Large",
      "pickupAddress": "55 Water St, Financial District, NY 10041",
      "deliveryAddress": "200 Liberty St, Battery Park, NY 10281",
      "lat": 40.7050,
      "lng": -74.0130,
      "recipientName": "Carol White",
      "weight": "8.2 kg",
    },
    {
      "id": "ORD-004",
      "sizeCategory": "XL",
      "pickupAddress": "1 World Trade Center, NY 10007",
      "deliveryAddress": "30 Rockefeller Plaza, NY 10112",
      "lat": 40.7127,
      "lng": -74.0134,
      "recipientName": "David Chen",
      "weight": "15.0 kg",
    },
  ];

  static const LatLng _defaultCenter = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  void _checkConnectivity() {
    // Simulate connectivity check
    setState(() => _isOffline = false);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    HapticFeedback.mediumImpact();
    if (_isSelectingStart) {
      setState(() {
        _startLocation = position;
        _markers.removeWhere((m) => m.markerId.value == 'start');
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: 'Start Location'),
          ),
        );
      });
    } else {
      setState(() {
        _endLocation = position;
        _markers.removeWhere((m) => m.markerId.value == 'end');
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'End Location'),
          ),
        );
      });
    }
    if (_startLocation != null && _endLocation != null) {
      _drawPolyline();
    }
  }

  void _drawPolyline() {
    if (_startLocation == null || _endLocation == null) return;
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_startLocation!, _endLocation!],
          color: const Color(0xFF2563EB),
          width: 4,
          patterns: [],
        ),
      );
    });
    _adjustBounds();
  }

  void _adjustBounds() {
    if (_startLocation == null || _endLocation == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _startLocation!.latitude < _endLocation!.latitude
            ? _startLocation!.latitude
            : _endLocation!.latitude,
        _startLocation!.longitude < _endLocation!.longitude
            ? _startLocation!.longitude
            : _endLocation!.longitude,
      ),
      northeast: LatLng(
        _startLocation!.latitude > _endLocation!.latitude
            ? _startLocation!.latitude
            : _endLocation!.latitude,
        _startLocation!.longitude > _endLocation!.longitude
            ? _startLocation!.longitude
            : _endLocation!.longitude,
      ),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _declareRoute() {
    if (_startLocation == null || _endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select both start and end locations on the map',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _routeDeclared = true;
      });
      _addOrderMarkers();
      _showOrderBottomSheet();
    });
  }

  void _addOrderMarkers() {
    for (int i = 0; i < _matchedOrders.length; i++) {
      final order = _matchedOrders[i];
      _markers.add(
        Marker(
          markerId: MarkerId('order_$i'),
          position: LatLng(order['lat'] as double, order['lng'] as double),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: 'Order ${i + 1}: ${order['id']}',
            snippet: order['pickupAddress'] as String,
          ),
          onTap: () => _showOrderPreview(order),
        ),
      );
    }
    setState(() {});
  }

  void _showOrderPreview(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          OrderCardWidget(order: order, onDismiss: () => Navigator.pop(ctx)),
    );
  }

  void _showOrderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => OrderBottomSheetWidget(
        orders: _matchedOrders,
        onOrderTap: (order) {
          Navigator.pop(ctx);
          _showOrderPreview(order);
        },
      ),
    );
  }

  void _confirmRoute() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/active-delivery-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: 13,
              ),
              onTap: _onMapTap,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Top overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  children: [
                    RouteSearchBarWidget(
                      isOffline: _isOffline,
                      isSelectingStart: _isSelectingStart,
                      startLocation: _startLocation,
                      endLocation: _endLocation,
                      onToggleSelection: () {
                        setState(() => _isSelectingStart = !_isSelectingStart);
                      },
                    ),
                    SizedBox(height: 1.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _declareRoute,
                        icon: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : CustomIconWidget(
                                iconName: 'route',
                                color: theme.colorScheme.onPrimary,
                                size: 20,
                              ),
                        label: Text(
                          _isLoading ? 'Finding Orders...' : 'Declare a Route',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Selection mode indicator
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isSelectingStart ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _isSelectingStart
                            ? 'Tap map to set Start location'
                            : 'Tap map to set End location',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Offline badge
            _isOffline
                ? Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: AppTheme.warningColor,
                      padding: EdgeInsets.symmetric(vertical: 0.5.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'wifi_off',
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Offline Mode – Route cached locally',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            // FAB confirm route
            _routeDeclared
                ? Positioned(
                    bottom: 3.h,
                    right: 4.w,
                    child: FloatingActionButton.extended(
                      onPressed: _confirmRoute,
                      icon: CustomIconWidget(
                        iconName: 'check_circle',
                        color: Colors.white,
                        size: 22,
                      ),
                      label: const Text('Confirm Route'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  )
                : const SizedBox.shrink(),
            // View orders FAB
            _routeDeclared
                ? Positioned(
                    bottom: 3.h,
                    left: 4.w,
                    child: FloatingActionButton(
                      onPressed: _showOrderBottomSheet,
                      backgroundColor: theme.colorScheme.primary,
                      child: CustomIconWidget(
                        iconName: 'list_alt',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            // My location button
            Positioned(
              bottom: _routeDeclared ? 12.h : 3.h,
              right: 4.w,
              child: _routeDeclared
                  ? const SizedBox.shrink()
                  : FloatingActionButton.small(
                      onPressed: () async {
                        try {
                          final pos = await Geolocator.getCurrentPosition();
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(
                              LatLng(pos.latitude, pos.longitude),
                            ),
                          );
                        } catch (_) {}
                      },
                      backgroundColor: theme.colorScheme.surface,
                      child: CustomIconWidget(
                        iconName: 'my_location',
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
