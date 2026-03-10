import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';

/// Socket.io Service for Real-Time Communication
/// Handles location broadcasts, delivery PIN requests, and order updates
class SocketService {
  static final SocketService _instance = SocketService._internal();
  late io.Socket socket;
  final Logger _logger = Logger();

  // Callbacks for different events
  Function(Map<String, dynamic>)? onDeliveryPinRequest;
  Function(Map<String, dynamic>)? onPhotoPinRequest;
  Function(Map<String, dynamic>)? onStatusUpdate;
  Function(String)? onError;
  Function()? onConnect;
  Function()? onDisconnect;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// Initialize Socket.io connection
  Future<void> initialize(String backendUrl) async {
    try {
      socket = io.io(backendUrl, <String, dynamic>{
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'reconnectionAttempts': 5,
        'transports': ['websocket'],
      });

      // Connection events
      socket.onConnect((_) {
        _logger.i('Socket.io connected');
        onConnect?.call();
      });

      socket.onDisconnect((_) {
        _logger.w('Socket.io disconnected');
        onDisconnect?.call();
      });

      // Listen for delivery PIN requests
      socket.on('request-delivery-pin', (data) {
        _logger.i('Delivery PIN requested: $data');
        onDeliveryPinRequest?.call(data as Map<String, dynamic>);
      });

      // Listen for photo PIN requests (photo + PIN together)
      socket.on('request-photo-pin', (data) {
        _logger.i('Photo PIN requested: $data');
        onPhotoPinRequest?.call(data as Map<String, dynamic>);
      });

      // Listen for status updates
      socket.on('status-update', (data) {
        _logger.i('Status update: $data');
        onStatusUpdate?.call(data as Map<String, dynamic>);
      });

      // Error handling
      socket.onError((error) {
        _logger.e('Socket.io error: $error');
        onError?.call(error.toString());
      });

      _logger.i('Socket.io initialized and listening to events');
    } catch (e) {
      _logger.e('Failed to initialize Socket.io: $e');
      rethrow;
    }
  }

  /// Join order tracking room
  void joinOrder({
    required String orderId,
    required String courierId,
    required String userType,
  }) {
    try {
      socket.emit('join-order', {
        'orderId': orderId,
        'userId': courierId,
        'userType': userType,
      });
      _logger.i('Joined order room: $orderId');
    } catch (e) {
      _logger.e('Failed to join order: $e');
      onError?.call(e.toString());
    }
  }

  /// Broadcast current location to order room
  void broadcastLocation({
    required String courierId,
    required String orderId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) {
    try {
      socket.emit('location-update', {
        'courierId': courierId,
        'orderId': orderId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _logger.d('Location broadcasted: ($latitude, $longitude)');
    } catch (e) {
      _logger.e('Failed to broadcast location: $e');
      onError?.call(e.toString());
    }
  }

  /// Send pickup photo URL to order room
  void broadcastPickupPhoto({
    required String courierId,
    required String orderId,
    required String photoUrl,
  }) {
    try {
      socket.emit('photo-update', {
        'courierId': courierId,
        'orderId': orderId,
        'photoType': 'pickup',
        'photoUrl': photoUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _logger.i('Pickup photo broadcasted: $photoUrl');
    } catch (e) {
      _logger.e('Failed to broadcast pickup photo: $e');
      onError?.call(e.toString());
    }
  }

  /// Send delivery photo URL to order room
  void broadcastDeliveryPhoto({
    required String courierId,
    required String orderId,
    required String photoUrl,
  }) {
    try {
      socket.emit('photo-update', {
        'courierId': courierId,
        'orderId': orderId,
        'photoType': 'delivery',
        'photoUrl': photoUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _logger.i('Delivery photo broadcasted: $photoUrl');
    } catch (e) {
      _logger.e('Failed to broadcast delivery photo: $e');
      onError?.call(e.toString());
    }
  }

  /// Verify delivery PIN
  void verifyDeliveryPin({
    required String orderId,
    required String enteredPin,
  }) {
    try {
      socket.emit('verify-delivery-pin', {
        'orderId': orderId,
        'enteredPin': enteredPin,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _logger.i('PIN verification sent for order: $orderId');
    } catch (e) {
      _logger.e('Failed to verify PIN: $e');
      onError?.call(e.toString());
    }
  }

  /// Broadcast delivery completion status
  void broadcastDeliveryComplete({
    required String orderId,
    required String courierId,
    String? notes,
  }) {
    try {
      socket.emit('order-status-update', {
        'orderId': orderId,
        'courierId': courierId,
        'status': 'delivered',
        'message': notes ?? 'Delivery completed successfully',
        'timestamp': DateTime.now().toIso8601String(),
      });
      _logger.i('Delivery completion broadcasted for order: $orderId');
    } catch (e) {
      _logger.e('Failed to broadcast delivery completion: $e');
      onError?.call(e.toString());
    }
  }

  /// Leave order room
  void leaveOrder({required String orderId}) {
    try {
      socket.emit('leave-order', {'orderId': orderId});
      _logger.i('Left order room: $orderId');
    } catch (e) {
      _logger.e('Failed to leave order: $e');
      onError?.call(e.toString());
    }
  }

  /// Disconnect socket
  void disconnect() {
    try {
      socket.disconnect();
      _logger.i('Socket.io disconnected');
    } catch (e) {
      _logger.e('Failed to disconnect: $e');
    }
  }

  /// Check connection status
  bool get isConnected => socket.connected;

  /// Reconnect socket
  void reconnect() {
    try {
      socket.connect();
      _logger.i('Socket.io reconnecting...');
    } catch (e) {
      _logger.e('Failed to reconnect: $e');
    }
  }
}
