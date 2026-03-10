import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/delivery_detail_sheet_widget.dart';
import './widgets/next_delivery_card_widget.dart';
import './widgets/quick_action_menu_widget.dart';

class ActiveDeliveryDashboardInitialPage extends StatefulWidget {
  const ActiveDeliveryDashboardInitialPage({super.key});

  @override
  State<ActiveDeliveryDashboardInitialPage> createState() =>
      _ActiveDeliveryDashboardInitialPageState();
}

class _ActiveDeliveryDashboardInitialPageState
    extends State<ActiveDeliveryDashboardInitialPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isOnline = true;
  bool _isLoading = true;
  bool _showQuickMenu = false;
  Timer? _locationTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int _selectedDeliveryIndex = -1;

  final List<Map<String, dynamic>> _deliveries = [
    {
      "id": "DEL-001",
      "address": "1234 Oak Street, San Francisco, CA 94102",
      "packageSize": "Medium",
      "status": "pending",
      "lat": 37.7749,
      "lng": -122.4194,
      "customer": "Sarah Johnson",
      "phone": "+1 (415) 555-0101",
      "eta": "12 min",
      "semanticLabel": "Delivery location marker for 1234 Oak Street",
    },
    {
      "id": "DEL-002",
      "address": "567 Pine Avenue, San Francisco, CA 94103",
      "packageSize": "Large",
      "status": "picked_up",
      "lat": 37.7799,
      "lng": -122.4144,
      "customer": "Marcus Williams",
      "phone": "+1 (415) 555-0202",
      "eta": "25 min",
      "semanticLabel": "Delivery location marker for 567 Pine Avenue",
    },
    {
      "id": "DEL-003",
      "address": "890 Market Street, San Francisco, CA 94105",
      "packageSize": "Small",
      "status": "delivered",
      "lat": 37.7699,
      "lng": -122.4244,
      "customer": "Emily Chen",
      "phone": "+1 (415) 555-0303",
      "eta": "Delivered",
      "semanticLabel": "Delivery location marker for 890 Market Street",
    },
  ];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initLocation();
    _buildMarkers();
    _buildPolyline();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _connectivitySubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      setState(() {
        _isOnline = results.any((r) => r != ConnectivityResult.none);
      });
    });
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }
      await _updateLocation();
      _locationTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updateLocation(),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      _buildMarkers();
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _buildMarkers() {
    final Set<Marker> markers = {};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('courier_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    for (int i = 0; i < _deliveries.length; i++) {
      final delivery = _deliveries[i];
      final status = delivery['status'] as String;
      double hue;
      if (status == 'pending') {
        hue = BitmapDescriptor.hueOrange;
      } else if (status == 'picked_up') {
        hue = BitmapDescriptor.hueYellow;
      } else {
        hue = BitmapDescriptor.hueGreen;
      }
      markers.add(
        Marker(
          markerId: MarkerId('delivery_$i'),
          position: LatLng(
            delivery['lat'] as double,
            delivery['lng'] as double,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: 'DEL-00${i + 1}',
            snippet: delivery['address'] as String,
          ),
          onTap: () => _showDeliveryDetail(i),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _buildPolyline() {
    final List<LatLng> points = [
      _defaultLocation,
      ..._deliveries
          .map((d) => LatLng(d['lat'] as double, d['lng'] as double))
          ,
    ];

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: const Color(0xFF2563EB),
          width: 4,
          patterns: [],
        ),
      };
    });
  }

  void _showDeliveryDetail(int index) {
    setState(() => _selectedDeliveryIndex = index);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryDetailSheetWidget(
        delivery: _deliveries[index],
        onNavigate: () {
          Navigator.pop(context);
          _launchNavigation(_deliveries[index]);
        },
        onCallCustomer: () => Navigator.pop(context),
        onMarkArrived: () => Navigator.pop(context),
        onSkipDelivery: () => Navigator.pop(context),
      ),
    );
  }

  void _launchNavigation(Map<String, dynamic> delivery) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening navigation to ${delivery['address']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _updateLocation();
    _buildMarkers();
    _buildPolyline();
  }

  void _handleManualSync() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS queue synced successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() => _showQuickMenu = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition != null
                                ? LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  )
                                : _defaultLocation,
                            zoom: 14,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          markers: _markers,
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                        Positioned(
                          top: 2.h,
                          left: 4.w,
                          right: 4.w,
                          child: _buildStatusBar(theme, isDark),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildBottomPanel(theme, isDark),
                        ),
                      ],
                    ),
                  ),
            if (_showQuickMenu)
              Positioned(
                bottom: 28.h,
                right: 4.w,
                child: QuickActionMenuWidget(
                  onManualSync: _handleManualSync,
                  onReportIssue: () {
                    setState(() => _showQuickMenu = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Issue reported'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onEmergencyContact: () {
                    setState(() => _showQuickMenu = false);
                  },
                ),
              ),
            Positioned(
              bottom: 22.h,
              right: 4.w,
              child: FloatingActionButton(
                onPressed: () =>
                    setState(() => _showQuickMenu = !_showQuickMenu),
                backgroundColor: theme.colorScheme.primary,
                child: CustomIconWidget(
                  iconName: _showQuickMenu ? 'close' : 'menu',
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: _isOnline
            ? AppTheme.successColor.withValues(alpha: 0.95)
            : AppTheme.errorLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: _isOnline ? 'wifi' : 'wifi_off',
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 2.w),
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'local_shipping',
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 1.w),
              Text(
                '${_deliveries.where((d) => d['status'] != 'delivered').length} Active',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'my_location',
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 1.w),
              Text(
                'GPS Active',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme, bool isDark) {
    final pendingDeliveries = _deliveries
        .where((d) => d['status'] != 'delivered')
        .toList();
    if (pendingDeliveries.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Delivery',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/pickup-workflow-screen'),
                  icon: CustomIconWidget(
                    iconName: 'arrow_forward',
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  label: Text(
                    'Pickup',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 16.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: pendingDeliveries.length,
              itemBuilder: (context, index) {
                return NextDeliveryCardWidget(
                  delivery: pendingDeliveries[index],
                  onTap: () {
                    final originalIndex = _deliveries.indexOf(
                      pendingDeliveries[index],
                    );
                    _showDeliveryDetail(originalIndex);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }
}
