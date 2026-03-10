import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../services/socket_service.dart';

/// Courier location data class
class CourierLocation {
  final String courierId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  CourierLocation({
    required this.courierId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  factory CourierLocation.fromMap(Map<String, dynamic> map) {
    return CourierLocation(
      courierId: map['courierId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
    );
  }
}

/// Active delivery tracking data
class ActiveDelivery {
  final String orderId;
  final String courierId;
  final CourierLocation? courierLocation;
  final String deliveryPin;
  final String status;

  ActiveDelivery({
    required this.orderId,
    required this.courierId,
    this.courierLocation,
    required this.deliveryPin,
    required this.status,
  });
}

/// Notifier for managing active delivery and real-time courier location
class DeliveryTrackingNotifier extends StateNotifier<ActiveDelivery?> {
  final Logger _logger = Logger();
  final SocketService _socketService = SocketService();

  DeliveryTrackingNotifier() : super(null);

  /// Start tracking a delivery
  /// Called when user accepts/creates an order
  void startTracking({
    required String orderId,
    required String courierId,
    required String userId,
    required String deliveryPin,
  }) {
    _logger.i('Starting delivery tracking for order: $orderId');

    // Update state with order info
    state = ActiveDelivery(
      orderId: orderId,
      courierId: courierId,
      courierLocation: null,
      deliveryPin: deliveryPin,
      status: 'accepted',
    );

    // Join order room for real-time updates
    _socketService.joinOrder(orderId, userId, userType: 'client');

    // Listen to real-time courier location updates
    _socketService.onCourierLocationUpdate = (location) {
      _handleCourierLocationUpdate(location);
    };

    // Listen to status changes
    _socketService.onStatusUpdate = (status) {
      _handleStatusUpdate(status);
    };

    // Listen to delivery completion
    _socketService.onDeliveryComplete = () {
      _handleDeliveryComplete();
    };
  }

  /// Handle incoming courier location update
  void _handleCourierLocationUpdate(Map<String, dynamic> data) {
    if (state == null) return;

    final location = CourierLocation.fromMap(data);
    _logger.d('📍 Courier location updated: ${location.latitude}, ${location.longitude}');

    // Update state with new courier location
    state = ActiveDelivery(
      orderId: state!.orderId,
      courierId: state!.courierId,
      courierLocation: location,
      deliveryPin: state!.deliveryPin,
      status: state!.status,
    );
  }

  /// Handle status updates
  void _handleStatusUpdate(Map<String, dynamic> data) {
    if (state == null) return;

    final newStatus = data['status'] as String? ?? 'unknown';
    _logger.i('Status updated: $newStatus');

    state = ActiveDelivery(
      orderId: state!.orderId,
      courierId: state!.courierId,
      courierLocation: state!.courierLocation,
      deliveryPin: state!.deliveryPin,
      status: newStatus,
    );
  }

  /// Handle delivery completion
  void _handleDeliveryComplete() {
    _logger.i('Delivery completed');
    state = null; // Clear tracking state
  }

  /// Stop tracking current delivery
  void stopTracking() {
    if (state != null) {
      _logger.i('Stopping delivery tracking for order: ${state!.orderId}');
    }
    state = null;
  }
}

/// Provider for active delivery tracking
final deliveryTrackingProvider =
    StateNotifierProvider<DeliveryTrackingNotifier, ActiveDelivery?>((ref) {
  return DeliveryTrackingNotifier();
});

/// Provider for just the courier location
final courierLocationProvider = Provider<CourierLocation?>((ref) {
  final delivery = ref.watch(deliveryTrackingProvider);
  return delivery?.courierLocation;
});

/// Provider for active order ID
final activeOrderIdProvider = Provider<String?>((ref) {
  final delivery = ref.watch(deliveryTrackingProvider);
  return delivery?.orderId;
});
