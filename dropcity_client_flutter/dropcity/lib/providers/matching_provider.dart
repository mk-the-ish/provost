import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

// Courier model for matching
class Courier {
  final String id;
  final String name;
  final double rating;
  final String vehicleType;
  final double distance;
  final bool isOnline;

  Courier({
    required this.id,
    required this.name,
    required this.rating,
    required this.vehicleType,
    required this.distance,
    required this.isOnline,
  });

  factory Courier.fromJson(Map<String, dynamic> json) {
    return Courier(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Courier',
      rating: (json['rating'] ?? 0).toDouble(),
      vehicleType: json['vehicleType'] ?? 'bike',
      distance: (json['distance'] ?? 0).toDouble(),
      isOnline: json['isOnline'] ?? false,
    );
  }
}

// Matching notifier for finding couriers
class MatchingNotifier extends StateNotifier<AsyncValue<List<Courier>>> {
  final ApiClient apiClient;

  MatchingNotifier(this.apiClient) : super(const AsyncValue.data([]));

  Future<void> findAvailableCouriers({
    required double latitude,
    required double longitude,
    double maxDistance = 10.0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await apiClient.findAvailableCouriers(
        latitude: latitude,
        longitude: longitude,
        maxDistance: maxDistance,
      );

      final couriers = (result['couriers'] as List<dynamic>?)
              ?.map((e) => Courier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      state = AsyncValue.data(couriers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> matchOrderWithCourier(String orderId, String courierId) async {
    try {
      final result = await apiClient.matchOrderWithCourier(
        orderId: orderId,
        courierId: courierId,
      );

      return result['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  void clearCouriers() {
    state = const AsyncValue.data([]);
  }
}

// Matching provider
final matchingProvider = StateNotifierProvider<MatchingNotifier,
    AsyncValue<List<Courier>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchingNotifier(apiClient);
});

// Get couriers by rating (sorted)
final couriersByRatingProvider = Provider<AsyncValue<List<Courier>>>((ref) {
  final couriers = ref.watch(matchingProvider);
  return couriers.whenData(
    (list) => List.from(list)..sort((a, b) => b.rating.compareTo(a.rating)),
  );
});

// Get couriers by distance (sorted nearest first)
final couriersByDistanceProvider = Provider<AsyncValue<List<Courier>>>((ref) {
  final couriers = ref.watch(matchingProvider);
  return couriers.whenData(
    (list) => List.from(list)..sort((a, b) => a.distance.compareTo(b.distance)),
  );
});

// Get online couriers only
final onlineCouriersProvider = Provider<AsyncValue<List<Courier>>>((ref) {
  final couriers = ref.watch(matchingProvider);
  return couriers.whenData(
    (list) => list.where((courier) => courier.isOnline).toList(),
  );
});
