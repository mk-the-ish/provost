import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_state_provider.dart';

// ======================= Models =======================

class Courier {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final int capacity;
  final bool isOnline;
  final double rating;

  Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.capacity,
    required this.isOnline,
    required this.rating,
  });

  factory Courier.fromJson(Map<String, dynamic> json) {
    return Courier(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'motorcycle',
      capacity: json['capacity'] ?? 1,
      isOnline: json['is_online'] ?? false,
      rating: (json['rating'] ?? 5.0).toDouble(),
    );
  }
}

class CourierRoute {
  final String id;
  final String courierId;
  final String origin;
  final double originLat;
  final double originLng;
  final String destination;
  final double destinationLat;
  final double destinationLng;
  final String vehicleType;
  final int capacity;
  final bool isActive;

  CourierRoute({
    required this.id,
    required this.courierId,
    required this.origin,
    required this.originLat,
    required this.originLng,
    required this.destination,
    required this.destinationLat,
    required this.destinationLng,
    required this.vehicleType,
    required this.capacity,
    required this.isActive,
  });
}

class MatchingOrder {
  final String id;
  final String orderId;
  final String clientId;
  final String clientName;
  final String pickupLocation;
  final double pickupLat;
  final double pickupLng;
  final String dropoffLocation;
  final double dropoffLat;
  final double dropoffLng;
  final int alignmentScore;
  final double distanceToPickup;
  final int estimatedMinutes;
  final DateTime createdAt;

  MatchingOrder({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.clientName,
    required this.pickupLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLocation,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.alignmentScore,
    required this.distanceToPickup,
    required this.estimatedMinutes,
    required this.createdAt,
  });

  factory MatchingOrder.fromJson(Map<String, dynamic> json) {
    return MatchingOrder(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      clientName: json['client_name'] ?? 'Unknown Customer',
      pickupLocation: json['pickup_address'] ?? json['pickup_location'] ?? 'Unknown',
      pickupLat: (json['pickup_lat'] ?? 0.0).toDouble(),
      pickupLng: (json['pickup_lng'] ?? 0.0).toDouble(),
      dropoffLocation: json['dropoff_address'] ?? json['dropoff_location'] ?? 'Unknown',
      dropoffLat: (json['dropoff_lat'] ?? 0.0).toDouble(),
      dropoffLng: (json['dropoff_lng'] ?? 0.0).toDouble(),
      alignmentScore: (json['alignment_score'] ?? 0) as int,
      distanceToPickup: (json['distance_to_pickup'] ?? 0.0).toDouble(),
      estimatedMinutes: (json['estimated_minutes'] ?? 15) as int,
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class OfflineQueueStats {
  final int pendingGpsPoints;
  final int failedUploads;
  final int totalPings;
  final int syncedPings;
  final int unsyncedPings;
  final int syncAttempts;
  final DateTime lastSync;

  OfflineQueueStats({
    required this.pendingGpsPoints,
    required this.failedUploads,
    this.totalPings = 0,
    this.syncedPings = 0,
    this.unsyncedPings = 0,
    this.syncAttempts = 0,
    required this.lastSync,
  });
}

// ======================= Providers =======================

/// Get current authenticated user's courier profile
final currentCourierProvider = FutureProvider<Courier?>((ref) async {
  final authState = ref.watch(authProvider);
  
  if (!authState.isLoggedIn || authState.userId == null) return null;

  // Return a basic courier object with available data
  return Courier(
    id: authState.userId ?? '',
    name: '${authState.email}',
    phone: '',
    vehicleType: 'motorcycle',
    capacity: 1,
    isOnline: authState.isLoggedIn,
    rating: 5.0,
  );
});

/// Stream of current courier's active route
final currentRouteProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isLoggedIn) {
    return Stream.value(null);
  }

  return Stream.value(null); // Placeholder - implement with backend API
});

/// Real-time stream of matching orders
final matchingOrdersProvider = StreamProvider<List<MatchingOrder>>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isLoggedIn) {
    return Stream.value([]);
  }

  return Stream.value([]); // Placeholder - implement with backend API
});

/// Stream of courier's active delivery job
final activeDeliveryJobProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isLoggedIn) {
    return Stream.value(null);
  }

  return Stream.value(null); // Placeholder - implement with backend API
});

/// Offline queue statistics
final offlineQueueStatsProvider = StreamProvider<OfflineQueueStats>((ref) {
  final initialValue = OfflineQueueStats(
    pendingGpsPoints: 0,
    failedUploads: 0,
    lastSync: DateTime.now(),
  );
  
  return Stream.value(initialValue).asyncExpand((_) {
    return Stream.periodic(Duration(seconds: 5), (_) {
      return OfflineQueueStats(
        pendingGpsPoints: 0,
        failedUploads: 0,
        lastSync: DateTime.now(),
      );
    });
  });
});

/// Courier's delivery statistics
final courierStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  
  if (!authState.isLoggedIn) return {};

  return {
    'totalDeliveries': 0,
    'rating': 5.0,
    'earnings': 0,
  }; // Placeholder - implement with backend API
});

/// Accept an order (mutation provider)
final acceptOrderProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  final authState = ref.watch(authProvider);
  
  if (!authState.isLoggedIn) return false;

  try {
    // Call backend API to accept order
    // await ref.read(apiClientProvider).acceptOrder(orderId);
    return true;
  } catch (e) {
    print('Error accepting order: $e');
    return false;
  }
});
