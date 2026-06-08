import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sync_models.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  static Database? _database;

  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _databaseName = 'offline_sync.db';
  static const int _databaseVersion = 1;
  static const String _tableSyncQueue = 'sync_queue';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableSyncQueue (
        client_sync_id TEXT PRIMARY KEY,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        payload TEXT NOT NULL,
        client_timestamp TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        error_message TEXT
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_status ON $_tableSyncQueue(status)
    ''');
    await db.execute('''
      CREATE INDEX idx_created_at ON $_tableSyncQueue(created_at)
    ''');
  }

  Future<void> addSyncItem(SyncItem item) async {
    final db = await database;
    await db.insert(
      _tableSyncQueue,
      {
        'client_sync_id': item.clientSyncId,
        'operation_type': item.operationType.name,
        'entity_type': item.entityType.name,
        'entity_id': item.entityId,
        'payload': jsonEncode(item.payload),
        'client_timestamp': item.clientTimestamp?.toIso8601String(),
        'status': SyncStatus.pending.name,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncItem>> getPendingItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableSyncQueue,
      where: 'status = ?',
      whereArgs: [SyncStatus.pending.name],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => _mapToSyncItem(map)).toList();
  }

  Future<void> deleteSyncItem(String clientSyncId) async {
    final db = await database;
    await db.delete(
      _tableSyncQueue,
      where: 'client_sync_id = ?',
      whereArgs: [clientSyncId],
    );
  }

  Future<void> updateSyncItemStatus(
    String clientSyncId,
    SyncStatus status, {
    String? errorMessage,
  }) async {
    final db = await database;
    await db.update(
      _tableSyncQueue,
      {
        'status': status.name,
        if (errorMessage != null) 'error_message': errorMessage,
      },
      where: 'client_sync_id = ?',
      whereArgs: [clientSyncId],
    );
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableSyncQueue WHERE status = ?',
      [SyncStatus.pending.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> incrementRetryCount(String clientSyncId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE $_tableSyncQueue
      SET retry_count = retry_count + 1
      WHERE client_sync_id = ?
    ''', [clientSyncId]);
  }

  Future<void> clearFailedItems() async {
    final db = await database;
    await db.delete(
      _tableSyncQueue,
      where: 'status = ?',
      whereArgs: [SyncStatus.failed.name],
    );
  }

  Future<void> clearAllItems() async {
    final db = await database;
    await db.delete(_tableSyncQueue);
  }

  SyncItem _mapToSyncItem(Map<String, dynamic> map) {
    return SyncItem(
      operationType: OperationType.values.firstWhere(
        (e) => e.name == map['operation_type'],
      ),
      entityType: EntityType.values.firstWhere(
        (e) => e.name == map['entity_type'],
      ),
      clientSyncId: map['client_sync_id'],
      entityId: map['entity_id'],
      payload: map['payload'] is String
          ? jsonDecode(map['payload'] as String)
          : map['payload'] as Map<String, dynamic>,
      clientTimestamp: map['client_timestamp'] != null
          ? DateTime.parse(map['client_timestamp'])
          : null,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
