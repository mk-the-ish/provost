import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

// Courier profile model
class CourierProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final int totalDeliveries;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  CourierProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.rating,
    required this.totalDeliveries,
    required this.isOnline,
    required this.createdAt,
    this.lastActiveAt,
  });

  factory CourierProfile.fromJson(Map<String, dynamic> json) {
    return CourierProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'] ?? 'bike',
      vehicleNumber: json['vehicleNumber'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'])
          : null,
    );
  }
}

// Courier profile notifier
class CourierProfileNotifier
    extends StateNotifier<AsyncValue<CourierProfile?>> {
  final ApiClient apiClient;

  CourierProfileNotifier(this.apiClient) : super(const AsyncValue.data(null)) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final result = await apiClient.getCourierProfile();
      final profile = CourierProfile.fromJson(result['profile'] ?? {});
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final result = await apiClient.updateCourierStatus(isOnline);

      if (result['success'] == true) {
        await _loadProfile();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }
}

// Courier profile provider
final courierProfileProvider =
    StateNotifierProvider<CourierProfileNotifier, AsyncValue<CourierProfile?>>(
        (ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CourierProfileNotifier(apiClient);
});

// Courier name selector
final courierNameProvider = Provider<String?>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.whenData((p) => p?.name).value;
});

// Courier rating selector
final courierRatingProvider = Provider<double>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.whenData((p) => p?.rating ?? 0.0).value ?? 0.0;
});

// Courier online status selector
final courierOnlineStatusProvider = Provider<bool>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.whenData((p) => p?.isOnline ?? false).value ?? false;
});

// Total deliveries selector
final totalDeliveriesProvider = Provider<int>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.whenData((p) => p?.totalDeliveries ?? 0).value ?? 0;
});

// Vehicle info selector
final vehicleInfoProvider = Provider<Map<String, String>?>((ref) {
  final profile = ref.watch(courierProfileProvider);
  return profile.whenData((p) {
    if (p == null) return null;
    return {
      'type': p.vehicleType,
      'number': p.vehicleNumber,
    };
  }).value;
});
