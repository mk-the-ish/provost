import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {

    /// Returns the stored auth token, or null if not present.
    Future<String?> getAuthToken() async {
      return await _storage.read(key: 'auth_token');
    }

    /// Logs out by deleting the stored auth token.
    Future<void> logout() async {
      await _storage.delete(key: 'auth_token');
    }
  static const String baseUrl = 'https://provost.onrender.com/api';



  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    );

    // Add authorization token to all requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors by clearing token
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'auth_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ============ AUTHENTICATION ============

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<Map<String, dynamic>> registerCourier({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String vehicleType,
    required String vehicleNumber,
    required String licenseNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/courier',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumber,
          'licenseNumber': licenseNumber,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data as Map<String, dynamic>;

      // Save token
      if (data['token'] != null) {
        await _storage.write(
          key: 'auth_token',
          value: data['token'],
        );
      }

      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/update-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> estimateDeliveryTime({
    required String courierId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/estimate/$courierId',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> storeDeliveryEvent({
    required String orderId,
    required String eventType,
    Map<String, dynamic>? details,
  }) async {
    try {
      final response = await _dio.post(
        '/tracking/event/$orderId',
        data: {
          'eventType': eventType,
          'details': details ?? {},
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDeliveryEvents(String orderId) async {
    try {
      final response = await _dio.get('/tracking/events/$orderId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ MATCHING ============

  Future<Map<String, dynamic>> getMatchingOrders() async {
    try {
      final response = await _dio.get('/matching/orders');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> matchOrderWithCourier({
    required String orderId,
    required String courierId,
  }) async {
    try {
      final response = await _dio.post(
        '/matching/match',
        data: {
          'orderId': orderId,
          'courierId': courierId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ ORDERS ============

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '/orders/$orderId/status',
        data: {
          'status': status,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    try {
      final response = await _dio.put('/orders/$orderId/complete');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCourierOrders({String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) {
        params['status'] = status;
      }

      final response = await _dio.get(
        '/couriers/orders',
        queryParameters: params,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ ROUTES ============

  Future<Map<String, dynamic>> declareRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String encodedPolyline,
    double? distanceKm,
    String? estimatedDuration,
    int? polylinePointCount,
  }) async {
    try {
      final response = await _dio.post(
        '/routes/declare',
        data: {
          'startLat': startLat,
          'startLng': startLng,
          'endLat': endLat,
          'endLng': endLng,
          'encodedPolyline': encodedPolyline,
          'distance': distanceKm?.toStringAsFixed(2),
          'estimatedDuration': estimatedDuration,
          'polylinePointCount': polylinePointCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ COURIER PROFILE ============

  Future<Map<String, dynamic>> getCourierProfile() async {
    try {
      final response = await _dio.get('/couriers/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCourierProfile({
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    try {
      final response = await _dio.put(
        '/couriers/profile',
        data: {
          'name': name,
          'phone': phone,
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumber,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteCourierProfile() async {
    try {
      await _dio.delete('/couriers/profile');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCourierStatus(bool isOnline) async {
    try {
      final response = await _dio.put(
        '/couriers/status',
        data: {
          'isOnline': isOnline,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ ERROR HANDLING ============

  Exception _handleError(DioException error) {
    String message = 'An error occurred';

    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? 'An error occurred';
      }
      return ApiException(
        message: message,
        statusCode: error.response?.statusCode,
      );
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Server timeout. Please try again later.';
    }

    return ApiException(message: message);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => message;
}
