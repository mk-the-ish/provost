import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

// Tracking data model
class TrackingData {
  final String orderId;
  final String courierName;
  final String courierPhone;
  final String vehicleType;
  final double rating;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final String orderStatus;
  final DateTime? estimatedArrival;
  final double? courierLatitude;
  final double? courierLongitude;
  final double courierRating;
  final DateTime? eta;

  TrackingData({
    required this.orderId,
    required this.courierName,
    required this.courierPhone,
    required this.vehicleType,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    required this.orderStatus,
    this.estimatedArrival,
    this.courierLatitude,
    this.courierLongitude,
    this.courierRating = 0.0,
    this.eta,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    final courierDetails = json['courierDetails'] ?? {};
    final currentLocation = json['currentLocation'] ?? {};

    return TrackingData(
      orderId: json['orderId'] ?? '',
      courierName: courierDetails['fullName'] ?? 'Unknown',
      courierPhone: courierDetails['phoneNumber'] ?? '',
      vehicleType: courierDetails['vehicleType'] ?? '',
      rating: (courierDetails['rating'] ?? 0).toDouble(),
      latitude: (currentLocation['latitude'] ?? 0).toDouble(),
      longitude: (currentLocation['longitude'] ?? 0).toDouble(),
      lastUpdated: currentLocation['updatedAt'] != null
          ? DateTime.parse(currentLocation['updatedAt'])
          : DateTime.now(),
      orderStatus: json['orderStatus'] ?? 'pending',
      estimatedArrival: json['estimatedArrival'] != null
          ? DateTime.parse(json['estimatedArrival'])
          : null,
      courierLatitude: (currentLocation['latitude'] as num?)?.toDouble(),
      courierLongitude: (currentLocation['longitude'] as num?)?.toDouble(),
      courierRating: (courierDetails['rating'] ?? 0).toDouble(),
      eta: json['estimatedArrival'] != null
          ? DateTime.parse(json['estimatedArrival'])
          : null,
    );
  }
}

// Delivery event model
class DeliveryEvent {
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic>? details;
  final String? location;

  DeliveryEvent({
    required this.eventType,
    required this.timestamp,
    this.details,
    this.location,
  });

  factory DeliveryEvent.fromJson(Map<String, dynamic> json) {
    return DeliveryEvent(
      eventType: json['eventType'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      details: json['details'] as Map<String, dynamic>?,
      location: json['location'] as String?,
    );
  }
}

// Tracking notifier
class TrackingNotifier extends StateNotifier<AsyncValue<TrackingData?>> {
  final ApiClient apiClient;

  TrackingNotifier(this.apiClient) : super(const AsyncValue.data(null));

  Future<void> getTracking(String orderId) async {
    state = const AsyncValue.loading();
    try {
      final result = await apiClient.getLiveTracking(orderId);
      final trackingData = TrackingData.fromJson(result);
      state = AsyncValue.data(trackingData);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> stopTracking() async {
    state = const AsyncValue.data(null);
  }
}

// Tracking provider - family provider to handle orderId parameter
final trackingProvider = StateNotifierProvider.family<
    TrackingNotifier,
    AsyncValue<TrackingData?>,
    String>((ref, orderId) {
  final apiClient = ref.watch(apiClientProvider);
  final notifier = TrackingNotifier(apiClient);
  // Auto-fetch tracking data when provider is watched
  notifier.getTracking(orderId);
  return notifier;
});

// Get delivery events
final deliveryEventsProvider =
    FutureProvider.family<List<DeliveryEvent>, String>((ref, orderId) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getDeliveryEvents(orderId);
  final events = (result['events'] as List<dynamic>?)
          ?.map((e) => DeliveryEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [];
  return events;
});

// Get courier route
final courierRouteProvider =
    FutureProvider.family<List<Map<String, double>>, String>(
        (ref, orderId) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getCourierRoute(orderId);
  final route = (result['route'] as List<dynamic>?)
          ?.map((e) => {
                'latitude': (e['latitude'] as num).toDouble(),
                'longitude': (e['longitude'] as num).toDouble(),
              })
          .toList() ??
      [];
  return route;
});

// Estimate delivery time
final deliveryEtaProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, courierId) async {
  // Note: This would need the delivery location from the order.
  // Kept as placeholder until courier ETA endpoint call is wired.
  return {};
});

