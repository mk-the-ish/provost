import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  late socket_io.Socket _socket;
  final Logger _logger = Logger();
  bool _isConnected = false;
  String? _currentOrderId;

  Function(Map<String, dynamic>)? onCourierLocationUpdate;
  Function(Map<String, dynamic>)? onStatusUpdate;
  Function()? onDeliveryComplete;

  bool get isConnected => _isConnected;

  void initialize(String backendUrl) {
    try {
      _socket = socket_io.io(
        backendUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket.onConnect((_) {
        _isConnected = true;
        _logger.i('Connected to Socket.io server');
      });

      _socket.onDisconnect((_) {
        _isConnected = false;
        _logger.w('Disconnected from Socket.io server');
      });

      _socket.onError((error) {
        _logger.e('Socket.io error: $error');
      });

      _socket.connect();
    } catch (e) {
      _logger.e('Error initializing Socket.io: $e');
    }
  }

  void joinOrder(String orderId, String userId, {String userType = 'client'}) {
    try {
      _currentOrderId = orderId;

      _socket.emit('join-order', {
        'orderId': orderId,
        'userId': userId,
        'userType': userType,
      });

      _socket.on('courier-location-update', _handleCourierLocationUpdate);
      _socket.on('delivery-pin-update', _handleDeliveryPinUpdate);
      _socket.on('photo-received', _handlePhotoUpdate);
      _socket.on('status-changed', _handleStatusChange);
      _socket.on('user-disconnected', _handleUserDisconnected);
    } catch (e) {
      _logger.e('Error joining order: $e');
    }
  }

  void requestDeliveryPin(String orderId) {
    try {
      _socket.emit('request-delivery-pin', {'orderId': orderId});
    } catch (e) {
      _logger.e('Error requesting delivery PIN: $e');
    }
  }

  void broadcastLocation(
    String courierId,
    String orderId,
    double latitude,
    double longitude,
    double accuracy,
  ) {
    try {
      _socket.emit('location-update', {
        'courierId': courierId,
        'orderId': orderId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      });
    } catch (e) {
      _logger.e('Error broadcasting location: $e');
    }
  }

  void sendPhotoUpdate(
    String courierId,
    String orderId,
    String photoType,
    String photoUrl,
  ) {
    try {
      _socket.emit('photo-update', {
        'courierId': courierId,
        'orderId': orderId,
        'photoType': photoType,
        'photoUrl': photoUrl,
      });
    } catch (e) {
      _logger.e('Error sending photo update: $e');
    }
  }

  void broadcastStatusUpdate(String orderId, String status, String message) {
    try {
      _socket.emit('order-status-update', {
        'orderId': orderId,
        'status': status,
        'message': message,
      });
    } catch (e) {
      _logger.e('Error broadcasting status: $e');
    }
  }

  void onDeliveryPinUpdate(Function(String pin, String message) callback) {
    _socket.on('delivery-pin-update', (data) {
      callback(
        (data['deliveryPin'] ?? '').toString(),
        (data['message'] ?? '').toString(),
      );
    });
  }

  void onPhotoUpdate(
    Function(String photoType, String photoUrl, String timestamp) callback,
  ) {
    _socket.on('photo-received', (data) {
      callback(
        (data['photoType'] ?? '').toString(),
        (data['photoUrl'] ?? '').toString(),
        (data['timestamp'] ?? '').toString(),
      );
    });
  }

  void onStatusChange(Function(String status, String message) callback) {
    _socket.on('status-changed', (data) {
      callback(
        (data['status'] ?? '').toString(),
        (data['message'] ?? '').toString(),
      );
    });
  }

  void _handleCourierLocationUpdate(dynamic data) {
    final map = (data as Map).cast<String, dynamic>();
    onCourierLocationUpdate?.call(map);
  }

  void _handleDeliveryPinUpdate(dynamic data) {
    _logger.i('Delivery PIN received: ${data['deliveryPin']}');
  }

  void _handlePhotoUpdate(dynamic data) {
    _logger.i('Photo received: ${data['photoType']}');
  }

  void _handleStatusChange(dynamic data) {
    final map = (data as Map).cast<String, dynamic>();
    onStatusUpdate?.call(map);

    final status = (map['status'] ?? '').toString().toLowerCase();
    if (status == 'completed' || status == 'delivered') {
      onDeliveryComplete?.call();
    }
  }

  void _handleUserDisconnected(dynamic data) {
    _logger.w('User disconnected: ${data['userType']}');
  }

  void leaveOrder(String orderId) {
    try {
      if (_currentOrderId == orderId) {
        _currentOrderId = null;
        _socket.off('courier-location-update');
        _socket.off('delivery-pin-update');
        _socket.off('photo-received');
        _socket.off('status-changed');
        _socket.off('user-disconnected');
      }
    } catch (e) {
      _logger.e('Error leaving order: $e');
    }
  }

  void disconnect() {
    try {
      _socket.disconnect();
      _isConnected = false;
    } catch (e) {
      _logger.e('Error disconnecting: $e');
    }
  }

  void reconnect() {
    try {
      _socket.connect();
    } catch (e) {
      _logger.e('Error reconnecting: $e');
    }
  }
}
