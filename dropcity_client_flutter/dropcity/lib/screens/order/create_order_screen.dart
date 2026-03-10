import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import 'widgets/address_input_widget.dart';
import 'widgets/size_selector_widget.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  late TextEditingController _pickupAddressController;
  late TextEditingController _deliveryAddressController;
  late TextEditingController _descriptionController;
  String _selectedSize = 'small';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pickupAddressController = TextEditingController();
    _deliveryAddressController = TextEditingController();
    _descriptionController = TextEditingController();

    Future.microtask(() {
      ref.read(locationProvider.notifier).getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fillWithCurrentLocation(TextEditingController controller) async {
    await ref.read(locationProvider.notifier).getCurrentLocation();

    final location = ref.read(locationProvider).value;
    if (!mounted) {
      return;
    }

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to detect current location.'),
        ),
      );
      return;
    }

    controller.text =
        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
  }

  Future<void> _createOrder() async {
    if (_pickupAddressController.text.trim().isEmpty ||
        _deliveryAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserLocation? location = ref.read(locationProvider).value;
      if (location == null) {
        await ref.read(locationProvider.notifier).getCurrentLocation();
        location = ref.read(locationProvider).value;
      }

      if (location == null) {
        throw Exception('Unable to get your current location for order creation.');
      }

      final pickupLocation = _resolveCoordinates(
        _pickupAddressController.text,
        location,
      );
      final deliveryLocation = _resolveCoordinates(
        _deliveryAddressController.text,
        location,
        deliveryFallback: true,
      );

      final orderId = await ref.read(ordersProvider.notifier).createOrder(
            pickupLocation: pickupLocation,
            pickupAddress: _pickupAddressController.text.trim(),
            deliveryLocation: deliveryLocation,
            deliveryAddress: _deliveryAddressController.text.trim(),
            description: _descriptionController.text.trim(),
            weight: _weightForSize(_selectedSize),
            estimatedDistance:
                _estimateDistanceKm(pickupLocation, deliveryLocation),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/order/$orderId');
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create order: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, double> _resolveCoordinates(
    String rawAddress,
    UserLocation fallback, {
    bool deliveryFallback = false,
  }) {
    final parts = rawAddress.split(',').map((part) => part.trim()).toList();
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) {
        return {
          'latitude': lat,
          'longitude': lng,
        };
      }
    }

    if (deliveryFallback) {
      return {
        'latitude': fallback.latitude + 0.002,
        'longitude': fallback.longitude + 0.002,
      };
    }

    return {
      'latitude': fallback.latitude,
      'longitude': fallback.longitude,
    };
  }

  double _estimateDistanceKm(
    Map<String, double> pickup,
    Map<String, double> delivery,
  ) {
    final meters = Geolocator.distanceBetween(
      pickup['latitude']!,
      pickup['longitude']!,
      delivery['latitude']!,
      delivery['longitude']!,
    );
    final kilometers = meters / 1000;
    if (kilometers < 0.1) {
      return 0.1;
    }
    return kilometers;
  }

  double _weightForSize(String size) {
    switch (size) {
      case 'large':
        return 6.0;
      case 'medium':
        return 3.0;
      case 'small':
      default:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Order',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AddressInputWidget(
                  label: 'Pickup Location',
                  controller: _pickupAddressController,
                  onLocationTap: () =>
                      _fillWithCurrentLocation(_pickupAddressController),
                ),
                SizedBox(height: 2.5.h),
                AddressInputWidget(
                  label: 'Delivery Location',
                  controller: _deliveryAddressController,
                  onLocationTap: () =>
                      _fillWithCurrentLocation(_deliveryAddressController),
                ),
                SizedBox(height: 2.5.h),
                Text(
                  'Package Description',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.8.h),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Describe what you are sending',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.description,
                      color: theme.colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
                SizedBox(height: 2.5.h),
                SizeSelectorWidget(
                  onSizeSelected: (size) {
                    setState(() => _selectedSize = size);
                  },
                ),
                SizedBox(height: 3.h),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 5.5.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 2.h,
                          width: 2.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Create Order',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

