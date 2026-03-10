import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// RouteMatchingService handles the interaction with Supabase PostGIS
/// spatial functions to match delivery orders with courier routes.
///
/// Uses the simplified route-alignment algorithm:
/// - Geographic proximity matching (ST_DWithin)
/// - Alignment score calculation
/// - Candidate ranking and filtering

class RouteMatchingService {
  final SupabaseClient _supabase;
  final _logger = Logger();

  RouteMatchingService(this._supabase);

  /// Find matching couriers for a delivery order
  /// 
  /// Returns:
  /// List of courier matches with alignment scores, sorted by score
  Future<List<CourierMatch>> findMatchingCouriers({
    required String orderId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required int alignmentThresholdMeters,
  }) async {
    try {
      _logger.i(
        '🔍 Finding matching couriers for order $orderId '
        '(threshold: ${alignmentThresholdMeters}m)'
      );

      // Call Supabase RPC function
      final response = await _supabase.rpc(
        'match_delivery_to_couriers',
        params: {
          'p_order_id': orderId,
          'p_alignment_threshold': alignmentThresholdMeters,
        },
      ) as List<dynamic>;

      final matches = response
          .map((match) => CourierMatch.fromJson(match as Map<String, dynamic>))
          .toList();

      _logger.i('✅ Found ${matches.length} matching couriers');
      return matches;
    } catch (e) {
      _logger.e('❌ Error finding matching couriers: $e');
      rethrow;
    }
  }

  /// Get courier's declared route details
  Future<CourierRoute?> getCourierRoute(String routeId) async {
    try {
      final response = await _supabase
          .from('routes')
          .select('*')
          .eq('id', routeId)
          .single();

      return CourierRoute.fromJson(response);
    } catch (e) {
      _logger.e('❌ Error fetching route: $e');
      return null;
    }
  }

  /// Create a job (delivery assignment)
  Future<String?> createJob({
    required String orderId,
    required String routeId,
    required String courierId,
    required int sequenceInRoute,
    required double alignmentScore,
  }) async {
    try {
      final response = await _supabase.from('jobs').insert({
        'order_id': orderId,
        'route_id': routeId,
        'courier_id': courierId,
        'sequence_in_route': sequenceInRoute,
        'alignment_score': alignmentScore,
        'status': 'pending',
      }).select('id');

      final jobId = (response as List).first['id'] as String;
      _logger.i('✅ Created job $jobId');
      return jobId;
    } catch (e) {
      _logger.e('❌ Error creating job: $e');
      return null;
    }
  }

  /// Update job status
  Future<bool> updateJobStatus(String jobId, String status) async {
    try {
      await _supabase
          .from('jobs')
          .update({'status': status})
          .eq('id', jobId);

      _logger.i('✅ Updated job $jobId to $status');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating job status: $e');
      return false;
    }
  }
}

/// Model: CourierMatch (from route matching algorithm)
class CourierMatch {
  final String courierId;
  final String routeId;
  final double alignmentScore; // 0.0 to 1.0 (lower is better)
  final String courierName;
  final String vehicleType;
  final double capacityRemaining;
  final int distanceToPickupMeters;
  final int distanceToDropoffMeters;

  CourierMatch({
    required this.courierId,
    required this.routeId,
    required this.alignmentScore,
    required this.courierName,
    required this.vehicleType,
    required this.capacityRemaining,
    required this.distanceToPickupMeters,
    required this.distanceToDropoffMeters,
  });

  factory CourierMatch.fromJson(Map<String, dynamic> json) {
    return CourierMatch(
      courierId: json['courier_id'] as String,
      routeId: json['route_id'] as String,
      alignmentScore: (json['alignment_score'] as num).toDouble(),
      courierName: json['courier_name'] as String,
      vehicleType: json['vehicle_type'] as String,
      capacityRemaining: (json['capacity_remaining_kg'] as num).toDouble(),
      distanceToPickupMeters: (json['distance_to_pickup_meters'] as int),
      distanceToDropoffMeters: (json['distance_to_dropoff_meters'] as int),
    );
  }

  /// Get match quality percentage (100% = perfect alignment, 0% = at threshold)
  int getMatchQualityPercent() {
    return ((1.0 - alignmentScore) * 100).toInt().clamp(0, 100);
  }

  @override
  String toString() =>
      'CourierMatch(id: $courierId, score: ${alignmentScore.toStringAsFixed(2)}, quality: ${getMatchQualityPercent()}%)';
}

/// Model: CourierRoute (declared route)
class CourierRoute {
  final String id;
  final String courierId;
  final String routePolyline; // Encoded polyline
  final List<dynamic> routeWaypoints; // JSONB array
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final String status; // declared, in_progress, completed

  CourierRoute({
    required this.id,
    required this.courierId,
    required this.routePolyline,
    required this.routeWaypoints,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.status,
  });

  factory CourierRoute.fromJson(Map<String, dynamic> json) {
    return CourierRoute(
      id: json['id'] as String,
      courierId: json['courier_id'] as String,
      routePolyline: json['route_polyline'] as String,
      routeWaypoints: json['route_waypoints'] as List<dynamic>,
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
      scheduledStartTime:
          DateTime.parse(json['scheduled_start_time'] as String),
      scheduledEndTime: DateTime.parse(json['scheduled_end_time'] as String),
      status: json['status'] as String,
    );
  }
}
