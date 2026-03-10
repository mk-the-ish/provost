import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

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
        position.timestamp.millisecondsSinceEpoch,
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

      try {
        await apiClient.updateLocation(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } catch (_) {
        // Ignore backend location sync failures.
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

          try {
            await apiClient.updateLocation(
              latitude: location.latitude,
              longitude: location.longitude,
            );
          } catch (_) {
            // Ignore backend location sync failures.
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
    // Placeholder: keep stream subscription and cancel it when wiring stop flow.
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<UserLocation?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationNotifier(apiClient);
});

final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final permission = await Geolocator.checkPermission();
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
});

final latitudeProvider = Provider<double?>((ref) {
  final location = ref.watch(locationProvider);
  return location.whenData((loc) => loc?.latitude).value;
});

final longitudeProvider = Provider<double?>((ref) {
  final location = ref.watch(locationProvider);
  return location.whenData((loc) => loc?.longitude).value;
});

final isLocationRecentProvider = Provider<bool>((ref) {
  final location = ref.watch(locationProvider);
  return location.whenData((loc) {
        if (loc == null) return false;
        final now = DateTime.now();
        final diff = now.difference(loc.timestamp);
        return diff.inMinutes < 1;
      }).value ??
      false;
});
