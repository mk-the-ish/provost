import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'offline_gps_queue.dart';
import 'socket_service.dart';

/// ConnectivityAwareGpsTracker manages:
/// 1. Real-time GPS location tracking (high frequency)
/// 2. Offline queue management (SQLite local storage)
/// 3. Intelligent sync when connectivity is restored (batched every 30 seconds)
/// 4. Battery-aware tracking frequency adjustment

class ConnectivityAwareGpsTracker {
  static final ConnectivityAwareGpsTracker _instance =
      ConnectivityAwareGpsTracker._internal();

  factory ConnectivityAwareGpsTracker() {
    return _instance;
  }

  ConnectivityAwareGpsTracker._internal();

  final _logger = Logger();
  final _connectivity = Connectivity();
  final _offlineQueue = OfflineGpsQueue();
  final _firestore = FirebaseFirestore.instance;
  final _socketService = SocketService();

  // Tracking state
  bool _isTracking = false;
  bool _isOnline = true;
  Timer? _trackingTimer;
  Timer? _syncTimer;
  StreamSubscription? _connectivityStream;

  // Current active order (for Socket.io broadcasting)
  String? _activeOrderId;

  // Configuration
  final int _trackingIntervalSeconds = 30; // GPS update frequency
  final int _syncIntervalSeconds = 30; // Offline queue sync frequency
  final int _highAccuracyMinDistance = 5; // meters

  /// Initialize the tracker and start listening to connectivity
  Future<void> initialize(String courierId) async {
    _logger.i('🟢 Initializing GPS tracker for courier: $courierId');

    // Request location permissions
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _logger.e('❌ Location permission denied');
      return;
    }

    // Start monitoring connectivity
    _connectivityStream = _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result, courierId);
    });

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _handleConnectivityChange(result, courierId);
  }

  /// Handle connectivity state changes
  void _handleConnectivityChange(
    ConnectivityResult result,
    String courierId,
  ) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    _logger.i('🌐 Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');

    if (!wasOnline && _isOnline) {
      // Just came back online - start sync
      _logger.i('✅ Back online! Starting offline queue sync...');
      _startSync(courierId);
    } else if (wasOnline && !_isOnline) {
      // Just went offline - stop sync timer, keep tracking
      _logger.i('⚠️ Lost connectivity. Caching GPS pings locally...');
      _syncTimer?.cancel();
    }
  }

  /// Start high-frequency GPS tracking
  Future<void> startTracking(String courierId, {String? activeOrderId}) async {
    if (_isTracking) {
      _logger.w('⚠️ Tracking already active');
      return;
    }

    _isTracking = true;
    _activeOrderId = activeOrderId; // Store active order for Socket.io
    _logger.i('▶️ Starting GPS tracking...');

    // Track immediately, then every interval
    _performGpsUpdate(courierId);
    _trackingTimer =
        Timer.periodic(Duration(seconds: _trackingIntervalSeconds), (_) {
      _performGpsUpdate(courierId);
    });
  }

  /// Perform a single GPS location update
  Future<void> _performGpsUpdate(String courierId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (_isOnline) {
        // Online: send directly to Firebase
        await _sendToFirebase(courierId, position, timestamp);
      } else {
        // Offline: queue locally
        await _offlineQueue.insertGpsPing(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: timestamp,
        );

        final count = await _offlineQueue.getUnsyncedPingsCount();
        _logger.d('📍 GPS ping queued (total unsynced: $count)');
      }
    } catch (e) {
      _logger.e('❌ Error getting position: $e');
    }
  }

  /// Send location to Firebase Firestore and broadcast via Socket.io
  Future<void> _sendToFirebase(
    String courierId,
    Position position,
    int timestamp,
  ) async {
    try {
      await _firestore.collection('courier_locations').doc(courierId).set({
        'courier_id': courierId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': timestamp,
        'is_online': true,
        'last_sync': timestamp,
      }, SetOptions(merge: true));

      // Broadcast location via Socket.io if order is active
      if (_activeOrderId != null && _socketService.isConnected) {
        _socketService.broadcastLocation(
          courierId: courierId,
          orderId: _activeOrderId!,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
        _logger.d('📡 Location broadcasted via Socket.io');
      }

      _logger.d('✅ Location sent to Firebase');
    } catch (e) {
      _logger.e('❌ Error sending to Firebase: $e');
    }
  }

  /// Start batch syncing offline queue (every 30 seconds if online)
  void _startSync(String courierId) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: _syncIntervalSeconds), (_) {
      _syncOfflineQueue(courierId);
    });
  }

  /// Sync all unsynced GPS pings from offline queue
  Future<void> _syncOfflineQueue(String courierId) async {
    if (!_isOnline) {
      _logger.w('⚠️ Not online, skipping sync');
      return;
    }

    try {
      final unsyncedPings = await _offlineQueue.getUnsyncedPings();
      if (unsyncedPings.isEmpty) {
        _logger.d('✅ Offline queue empty, nothing to sync');
        return;
      }

      _logger.i('🔄 Syncing ${unsyncedPings.length} offline GPS pings...');

      // Batch pings into Firestore collection for backend processing
      final batch = _firestore.batch();
      final pingIds = <int>[];

      for (final ping in unsyncedPings) {
        final docRef = _firestore
            .collection('sync_queues')
            .doc('${courierId}_${ping['timestamp']}');

        batch.set(docRef, {
          'courier_id': courierId,
          'latitude': ping['latitude'],
          'longitude': ping['longitude'],
          'accuracy': ping['accuracy'],
          'timestamp': ping['timestamp'],
          'synced': false,
          'sync_attempts': (ping['sync_attempt_count'] as int?) ?? 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });

        pingIds.add(ping['id'] as int);
      }

      // Commit batch
      await batch.commit();

      // Mark as synced in local queue
      await _offlineQueue.markPingsSynced(pingIds);

      _logger.i('✅ Synced ${unsyncedPings.length} pings to Firestore');
    } catch (e) {
      _logger.e('❌ Error syncing offline queue: $e');
    }
  }

  /// Stop GPS tracking
  void stopTracking() {
    _isTracking = false;
    _activeOrderId = null;
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _logger.i('⏹️ GPS tracking stopped');
  }

  /// Set active order for Socket.io broadcasting
  void setActiveOrder(String? orderId) {
    _activeOrderId = orderId;
    _logger.i('📋 Active order set to: $_activeOrderId');
  }

  /// Get active order
  String? getActiveOrder() {
    return _activeOrderId;
  }
    _isTracking = false;
    _trackingTimer?.cancel();
    _syncTimer?.cancel();
    _logger.i('⏹️ GPS tracking stopped');
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _connectivityStream?.cancel();
    _logger.i('🗑️ GPS tracker disposed');
  }

  // Getters
  bool get isOnline => _isOnline;
  bool get isTracking => _isTracking;
}
