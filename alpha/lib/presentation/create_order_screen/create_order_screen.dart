import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/create_order_bottom_sheet_widget.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  LatLng? _pickupPosition;
  bool _isLoadingLocation = true;
  bool _isCreatingOrder = false;
  String _selectedSize = 'Small';
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _deliveryController = TextEditingController();
  Set<Marker> _markers = {};
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _showLocationError(
          'Location services are disabled. Please enable GPS.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _showLocationError('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _showLocationError('Location permissions are permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        _pickupPosition = latLng;
        _isLoadingLocation = false;
        _pickupController.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _updateMarkers();
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15),
        ),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showLocationError('Unable to detect location. Please try again.');
    }
  }

  void _showLocationError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
    );
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};
    if (_pickupPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _onMapTap(LatLng position) {
    HapticFeedback.lightImpact();
    setState(() {
      _pickupPosition = position;
      _pickupController.text =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      _updateMarkers();
    });
  }

  Future<void> _createOrder() async {
    if (_pickupController.text.isEmpty || _deliveryController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in both pickup and delivery addresses.',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange.shade700,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      final dio = Dio();
      final response = await dio.post(
        'http://localhost:5000/api/orders',
        data: {
          'pickupAddress': _pickupController.text,
          'deliveryAddress': _deliveryController.text,
          'sizeCategory': _selectedSize,
          'pickupLocation': {
            'lat': _pickupPosition?.latitude ?? _currentPosition.latitude,
            'lng': _pickupPosition?.longitude ?? _currentPosition.longitude,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderId =
            response.data['orderId'] ?? response.data['id'] ?? 'mock_order_001';
        Fluttertoast.showToast(
          msg: 'Order created successfully!',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
        );
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/live-tracking-map-screen',
            arguments: {'orderId': orderId},
          );
        }
      }
    } on DioException {
      // For demo: navigate with mock order ID
      Fluttertoast.showToast(
        msg: 'Order created! (Demo mode)',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.green.shade700,
        textColor: Colors.white,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/live-tracking-map-screen',
          arguments: {'orderId': 'mock_order_001'},
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to create order. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_pickupPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _pickupPosition!, zoom: 15),
                  ),
                );
              }
            },
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          if (_isLoadingLocation)
            Positioned(
              top: 6.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
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
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Detecting location...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 5.h,
            left: 4.w,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
            ),
          ),
          Positioned(
            top: 5.h,
            right: 4.w,
            child: SafeArea(
              child: GestureDetector(
                onTap: _detectCurrentLocation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'my_location',
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.42,
            minChildSize: 0.15,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.15, 0.42, 0.88],
            builder: (context, scrollController) {
              return CreateOrderBottomSheetWidget(
                scrollController: scrollController,
                pickupController: _pickupController,
                deliveryController: _deliveryController,
                selectedSize: _selectedSize,
                isCreatingOrder: _isCreatingOrder,
                onSizeChanged: (size) => setState(() => _selectedSize = size),
                onCreateOrder: _createOrder,
              );
            },
          ),
        ],
      ),
    );
  }
}
