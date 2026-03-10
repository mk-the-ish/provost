import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'api_provider.dart';

// Available Order model for couriers
class AvailableOrder {
  final String id;
  final String customerId;
  final String pickupAddress;
  final String deliveryAddress;
  final double weight;
  final double distance;
  final DateTime createdAt;

  AvailableOrder({
    required this.id,
    required this.customerId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.weight,
    required this.distance,
    required this.createdAt,
  });

  factory AvailableOrder.fromJson(Map<String, dynamic> json) {
    return AvailableOrder(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      pickupAddress: json['pickupAddress'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

// Courier Order model (Assigned orders)
class CourierOrder {
  final String id;
  final String customerId;
  final String status;
  final String pickupAddress;
  final String deliveryAddress;
  final double weight;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  CourierOrder({
    required this.id,
    required this.customerId,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.weight,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  factory CourierOrder.fromJson(Map<String, dynamic> json) {
    return CourierOrder(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      status: json['status'] ?? 'pending',
      pickupAddress: json['pickupAddress'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

// Available orders notifier
class AvailableOrdersNotifier
    extends StateNotifier<AsyncValue<List<AvailableOrder>>> {
  final ApiClient apiClient;

  AvailableOrdersNotifier(this.apiClient) : super(const AsyncValue.loading()) {
    _loadAvailableOrders();
  }

  Future<void> _loadAvailableOrders() async {
    state = const AsyncValue.loading();
    try {
      final result = await apiClient.getMatchingOrders();
      final orders = (result['matchingOrders'] as List<dynamic>?)
              ?.map((e) => AvailableOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      final result = await apiClient.matchOrderWithCourier(
        orderId: orderId,
        courierId: 'current-courier-id',
      );

      if (result['success'] == true) {
        await _loadAvailableOrders();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshOrders() async {
    await _loadAvailableOrders();
  }
}

// Courier orders notifier
class CourierOrdersNotifier extends StateNotifier<AsyncValue<List<CourierOrder>>> {
  final ApiClient apiClient;

  CourierOrdersNotifier(this.apiClient) : super(const AsyncValue.loading()) {
    _loadCourierOrders();
  }

  Future<void> _loadCourierOrders({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final result = await apiClient.getCourierOrders(status: status);
      final orders = (result['orders'] as List<dynamic>?)
              ?.map((e) => CourierOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeOrder(String orderId) async {
    try {
      final result = await apiClient.completeOrder(orderId);

      if (result['success'] == true) {
        await _loadCourierOrders();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshOrders() async {
    await _loadCourierOrders();
  }
}

// Available orders provider
final availableOrdersProvider = StateNotifierProvider<AvailableOrdersNotifier,
    AsyncValue<List<AvailableOrder>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AvailableOrdersNotifier(apiClient);
});

// Courier orders provider
final courierOrdersProvider =
    StateNotifierProvider<CourierOrdersNotifier, AsyncValue<List<CourierOrder>>>(
        (ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CourierOrdersNotifier(apiClient);
});

// Active orders for courier
final activeCourierOrdersProvider =
    Provider<AsyncValue<List<CourierOrder>>>((ref) {
  final orders = ref.watch(courierOrdersProvider);
  return orders.whenData(
    (list) => list
        .where((order) =>
            order.status != 'completed' && order.status != 'cancelled')
        .toList(),
  );
});

// Get single order details
final courierOrderDetailsProvider =
    FutureProvider.family<CourierOrder, String>((ref, orderId) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getOrderDetails(orderId);
  return CourierOrder.fromJson(result['order'] ?? {});
});
