import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';
import '../../providers/order_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/screen_specific/bottom_tracking_widget.dart';
import '../../widgets/screen_specific/courier_info_card_widget.dart';
import '../../widgets/screen_specific/estimated_arrival_widget.dart';
import 'widgets/delivery_status_widget.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({
    required this.orderId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trackingAsync = ref.watch(trackingProvider(orderId));
    final orderAsync = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Delivery',
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
      body: trackingAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
        error: (error, _) => _ErrorWidget(
          error: error.toString(),
          onRetry: () => ref.refresh(trackingProvider(orderId)),
          theme: theme,
        ),
        data: (tracking) {
          if (tracking == null) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          final estimateData = _estimateData(tracking.eta);
          final status =
              tracking.orderStatus.isEmpty ? 'pending' : tracking.orderStatus;
          final courierName =
              tracking.courierName.isEmpty ? 'Courier pending' : tracking.courierName;
          final courierRating =
              tracking.courierRating > 0 ? tracking.courierRating : tracking.rating;
          final deliveryPin = _deliveryPin(orderId);

          return Stack(
            children: [
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Live map view',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.42,
                minChildSize: 0.35,
                maxChildSize: 0.85,
                builder: (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 10.w,
                            height: 0.5.h,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        EstimatedArrivalWidget(
                          estimateData: estimateData,
                          theme: theme,
                        ),
                        SizedBox(height: 2.h),
                        CourierInfoCardWidget(
                          courierData: {
                            'name': courierName,
                            'profileImage':
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(courierName)}&background=1D4ED8&color=FFFFFF',
                            'vehicle': tracking.vehicleType.isEmpty
                                ? 'Vehicle details unavailable'
                                : tracking.vehicleType,
                            'rating': _safeRating(courierRating),
                          },
                          theme: theme,
                        ),
                        SizedBox(height: 2.h),
                        DeliveryStatusWidget(
                          statusTimeline: [
                            {'label': 'Order Placed', 'done': true},
                            {'label': 'Accepted', 'done': true},
                            {'label': 'In Transit', 'done': status == 'in_transit'},
                            {'label': 'Delivered', 'done': status == 'delivered'},
                          ],
                          currentStatus: status,
                          theme: theme,
                        ),
                        SizedBox(height: 2.h),
                        orderAsync.when(
                          data: (order) => BottomTrackingCardWidget(
                            orderData: {
                              'pickupAddress': order.pickupAddress,
                              'deliveryAddress': order.deliveryAddress,
                              'deliveryPin': deliveryPin,
                            },
                            theme: theme,
                          ),
                          loading: () => Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          error: (error, _) => Center(
                            child: Text('Error loading order: $error'),
                          ),
                        ),
                        SizedBox(height: 2.h),
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
                                icon: const Icon(Icons.call),
                                label: const Text('Call'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Opening courier chat...'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('Message'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic> _estimateData(DateTime? eta) {
    final remaining = _remainingMinutes(eta);
    if (remaining <= 0) {
      return {
        'time': '0',
        'unit': 'mins',
        'status': 'on_time',
      };
    }

    return {
      'time': remaining.toString(),
      'unit': 'mins',
      'status': 'on_time',
    };
  }



  int _remainingMinutes(DateTime? eta) {
    if (eta == null) {
      return 15;
    }
    final minutes = eta.difference(DateTime.now()).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  String _deliveryPin(String source) {
    final digitsOnly = source.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 4) {
      return digitsOnly.substring(digitsOnly.length - 4);
    }

    final hashValue = source.codeUnits.fold<int>(0, (a, b) => a + b);
    return (1000 + (hashValue % 9000)).toString();
  }

  double _safeRating(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 5) {
      return 5;
    }
    return double.parse(value.toStringAsFixed(1));
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final ThemeData theme;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: theme.colorScheme.error,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'Error loading tracking',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

