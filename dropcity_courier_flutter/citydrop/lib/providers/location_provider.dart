import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

// Location model
class UserLocation {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  factory UserLocation.fromPosition(Position position) {
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        position.timestamp?.millisecondsSinceEpoch ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
      };
}

// Location notifier
class LocationNotifier extends StateNotifier<AsyncValue<UserLocation?>> {
  final ApiClient apiClient;

  LocationNotifier(this.apiClient) : super(const AsyncValue.data(null));

  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result != LocationPermission.denied &&
          result != LocationPermission.deniedForever;
    }
    return permission != LocationPermission.deniedForever;
  }

  Future<void> getCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = UserLocation.fromPosition(position);
      state = AsyncValue.data(location);

      // Optionally update backend
      try {
        await apiClient.updateLocation(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } catch (e) {
        // Don't fail the location update if API fails
        print('Failed to update location on server: $e');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startLocationTracking({
    Duration updateInterval = const Duration(seconds: 30),
    double distanceFilter = 10.0,
  }) async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter.toInt(),
          timeLimit: Duration(minutes: 5),
        ),
      ).listen(
        (Position position) async {
          final location = UserLocation.fromPosition(position);
          state = AsyncValue.data(location);

          // Update backend with new location
          try {
            await apiClient.updateLocation(
              latitude: location.latitude,
              longitude: location.longitude,
            );
          } catch (e) {
            print('Failed to update location on server: $e');
          }
        },
        onError: (e) {
          state = AsyncValue.error(e, StackTrace.current);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void stopLocationTracking() {
    // Note: Stream subscription should be stored and cancelled
    // This is a placeholder for stream management
  }
}

// Location provider
final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<UserLocation?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationNotifier(apiClient);
});

// Location permission provider
final locationPermissionProvider =
    FutureProvider<bool>((ref) async {
  final permission = await Geolocator.checkPermission();
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
});

// Latitude and longitude selectors
final latitudeProvider = Provider<double?>((ref) {
  final location = ref.watch(locationProvider);
  return location.whenData((loc) => loc?.latitude).value;
});

final longitudeProvider = Provider<double?>((ref) {
  final location = ref.watch(locationProvider);
  return location.whenData((loc) => loc?.longitude).value;
});

// Check if location is recent (within 1 minute)
final isLocationRecentProvider = Provider<bool>((ref) {
  final location = ref.watch(locationProvider);
  return location.whenData((loc) {
    if (loc == null) return false;
    final now = DateTime.now();
    final diff = now.difference(loc.timestamp);
    return diff.inMinutes < 1;
  }).value ?? false;
});
