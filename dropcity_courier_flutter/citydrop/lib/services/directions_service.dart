import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service to fetch real road routes using Google Directions API via HTTP
class DirectionsService {
  static const String _googleMapsApiKey =
      'AIzaSyBfu7EtubnUKLE8UVxQxmSYnb1HrpmofzQ'; // Replace with your key

  final Dio _dio = Dio();
  final PolylinePoints _polylinePoints = PolylinePoints();

  /// Fetch the road route between two locations using flutter_polyline_points
  /// Returns a list of LatLng points representing the road path
  Future<List<LatLng>> getRoutePoints(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleMapsApiKey,
        request: PolylineRequest(
          origin: PointLatLng(start.latitude, start.longitude),
          destination: PointLatLng(end.latitude, end.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        return result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
      }

      // Fallback to straight line if no route found
      return [start, end];
    } catch (e) {
      // Fallback to straight line on error
      print('Error fetching route: $e');
      return [start, end];
    }
  }

  /// Get route details including distance and duration
  Future<RouteDetails?> getRouteDetails(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${start.latitude},${start.longitude}',
          'destination': '${end.latitude},${end.longitude}',
          'key': _googleMapsApiKey,
          'mode': 'driving',
        },
      );

      if (response.statusCode == 200 &&
          response.data['status'] == 'OK' &&
          response.data['routes'].isNotEmpty) {
        final route = response.data['routes'][0];
        final leg = route['legs'][0];

        final distanceValue = leg['distance']['value'] as int; // meters
        final durationText = leg['duration']['text'] as String; // "45 mins"

        final points = _decodePolyline(route['overview_polyline']['points']);

        return RouteDetails(
          distance: distanceValue / 1000, // Convert to km
          duration: durationText,
          pointCount: points.length,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching route details: $e');
      return null;
    }
  }

  /// Encode polyline points to a string for backend transmission
  /// Backend expects "lat,lng|lat,lng|lat,lng" format for PostGIS decoding
  String encodePolyline(List<LatLng> points) {
    if (points.isEmpty) return '';

    return points.map((p) => '${p.latitude},${p.longitude}').join('|');
  }

  /// Decode encoded polyline string back to LatLng list
  List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];
    final List<LatLng> points = [];
    final List<String> pairs = encoded.split('|');

    for (final pair in pairs) {
      final coords = pair.split(',');
      if (coords.length == 2) {
        points.add(
          LatLng(
            double.tryParse(coords[0]) ?? 0,
            double.tryParse(coords[1]) ?? 0,
          ),
        );
      }
    }
    return points;
  }

  /// Calculate distance between two points in kilometers (Haversine formula)
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadiusKm = 6371;
    final dLat = _toRad(end.latitude - start.latitude);
    final dLon = _toRad(end.longitude - start.longitude);
    final lat1 = _toRad(start.latitude);
    final lat2 = _toRad(end.latitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRad(double degree) => degree * (3.14159265359 / 180);

  /// Decode Google's polyline encoding algorithm
  /// Returns list of LatLng points from encoded polyline string
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

/// Model for route details
class RouteDetails {
  final double distance; // in km
  final String duration; // formatted string
  final int pointCount; // number of polyline points

  RouteDetails({
    required this.distance,
    required this.duration,
    required this.pointCount,
  });
}
