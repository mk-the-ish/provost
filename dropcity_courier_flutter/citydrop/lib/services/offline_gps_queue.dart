import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// OfflineGpsQueue manages local SQLite storage for GPS pings
/// when the courier app is offline or has poor connectivity.
///
/// Schema:
/// - id (INTEGER PRIMARY KEY AUTOINCREMENT)
/// - latitude (REAL)
/// - longitude (REAL)
/// - accuracy (REAL)
/// - timestamp (INTEGER - Unix milliseconds)
/// - synced (BOOLEAN - default 0/false)
/// - sync_attempt_count (INTEGER - default 0)

class OfflineGpsQueue {
  static final OfflineGpsQueue _instance = OfflineGpsQueue._internal();
  static Database? _database;

  factory OfflineGpsQueue() {
    return _instance;
  }

  OfflineGpsQueue._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'dropcity_offline_gps.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_gps_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            timestamp INTEGER NOT NULL,
            synced BOOLEAN DEFAULT 0,
            sync_attempt_count INTEGER DEFAULT 0
          )
        ''');

        // Index for unsynced pings (for batch sync)
        await db.execute('''
          CREATE INDEX idx_unsynced 
          ON offline_gps_queue(synced, timestamp ASC)
        ''');
      },
    );
  }

  /// Insert a new GPS ping into the offline queue
  Future<int> insertGpsPing({
    required double latitude,
    required double longitude,
    required double accuracy,
    required int timestamp, // Unix milliseconds
  }) async {
    final db = await database;
    return await db.insert(
      'offline_gps_queue',
      {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp,
        'synced': 0,
        'sync_attempt_count': 0,
      },
    );
  }

  /// Get all unsynced GPS pings (for batch sync to backend)
  Future<List<Map<String, dynamic>>> getUnsyncedPings() async {
    final db = await database;
    return await db.query(
      'offline_gps_queue',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  /// Get unsynced pings count
  Future<int> getUnsyncedPingsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_gps_queue WHERE synced = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark a batch of pings as synced
  Future<int> markPingsSynced(List<int> pingIds) async {
    final db = await database;
    if (pingIds.isEmpty) return 0;

    final placeholders = List.filled(pingIds.length, '?').join(',');
    return await db.rawUpdate(
      'UPDATE offline_gps_queue SET synced = 1, sync_attempt_count = sync_attempt_count + 1 '
      'WHERE id IN ($placeholders)',
      pingIds,
    );
  }

  /// Increment sync attempt count for failed syncs
  Future<int> incrementSyncAttempt(int pingId) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE offline_gps_queue SET sync_attempt_count = sync_attempt_count + 1 '
      'WHERE id = ?',
      [pingId],
    );
  }

  /// Delete old synced pings (older than 30 days)
  Future<int> deleteOldSyncedPings(int olderThanMillis) async {
    final db = await database;
    return await db.delete(
      'offline_gps_queue',
      where: 'synced = 1 AND timestamp < ?',
      whereArgs: [olderThanMillis],
    );
  }

  /// Clear all offline queue (for testing or cleanup)
  Future<int> clearQueue() async {
    final db = await database;
    return await db.delete('offline_gps_queue');
  }

  /// Get queue size in bytes (for monitoring)
  Future<int> getQueueSizeBytes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()'
    );
    return (result.first['size'] as int?) ?? 0;
  }

  /// Get statistics about the queue
  Future<Map<String, int>> getQueueStats() async {
    final db = await database;
    final total = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_gps_queue'
    );
    final unsynced = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_gps_queue WHERE synced = 0'
    );
    final synced = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_gps_queue WHERE synced = 1'
    );

    return {
      'total': Sqflite.firstIntValue(total) ?? 0,
      'unsynced': Sqflite.firstIntValue(unsynced) ?? 0,
      'synced': Sqflite.firstIntValue(synced) ?? 0,
    };
  }
}
