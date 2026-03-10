import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

// Order model
class Order {
  final String id;
  final String customerId;
  final String? assignedCourierId;
  final String status;
  final String pickupAddress;
  final String deliveryAddress;
  final double weight;
  final double estimatedDistance;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? courierRating;
  final String? courierFeedback;

  Order({
    required this.id,
    required this.customerId,
    this.assignedCourierId,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.weight,
    required this.estimatedDistance,
    required this.createdAt,
    this.completedAt,
    this.courierRating,
    this.courierFeedback,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      assignedCourierId: json['assignedCourierId'],
      status: json['status'] ?? 'pending',
      pickupAddress: json['pickupAddress'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      estimatedDistance: (json['estimatedDistance'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      courierRating: json['ratings']?['courierRating'],
      courierFeedback: json['ratings']?['courierFeedback'],
    );
  }
}

// Order notifier
class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final ApiClient apiClient;

  OrderNotifier(this.apiClient) : super(const AsyncValue.loading()) {
    _loadOrders();
  }

  Future<void> _loadOrders({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final result = await apiClient.getOrders(status: status);
      final orders = (result['orders'] as List<dynamic>?)
              ?.map((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> createOrder({
    required Map<String, double> pickupLocation,
    required String pickupAddress,
    required Map<String, double> deliveryLocation,
    required String deliveryAddress,
    required String description,
    required double weight,
    required double estimatedDistance,
  }) async {
    try {
      final result = await apiClient.createOrder(
        pickupLocation: pickupLocation,
        pickupAddress: pickupAddress,
        deliveryLocation: deliveryLocation,
        deliveryAddress: deliveryAddress,
        description: description,
        weight: weight,
        estimatedDistance: estimatedDistance,
      );

      if (result['success'] == true) {
        await _loadOrders();
        return result['orderId'];
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rateOrder({
    required String orderId,
    required int rating,
    String review = '',
  }) async {
    try {
      final result = await apiClient.rateOrder(
        orderId: orderId,
        rating: rating,
        review: review,
      );

      if (result['success'] == true) {
        await _loadOrders();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, {String reason = ''}) async {
    try {
      final result = await apiClient.cancelOrder(
        orderId: orderId,
        reason: reason,
      );

      if (result['success'] == true) {
        await _loadOrders();
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Order provider
final ordersProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderNotifier(apiClient);
});

// Get single order
final orderDetailsProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getOrderDetails(orderId);
  return Order.fromJson(result['order'] ?? {});
});

// Get active orders
final activeOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final orders = ref.watch(ordersProvider);
  return orders.whenData(
    (list) => list
        .where((order) =>
            order.status != 'completed' && order.status != 'cancelled')
        .toList(),
  );
});

// Get completed orders
final completedOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final orders = ref.watch(ordersProvider);
  return orders.whenData(
    (list) =>
        list.where((order) => order.status == 'completed').toList(),
  );
});
