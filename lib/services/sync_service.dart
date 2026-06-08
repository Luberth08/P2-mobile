import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sync_models.dart';
import 'offline_storage_service.dart';
import 'connectivity_service.dart';
import 'session.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final OfflineStorageService _storage = OfflineStorageService();
  final ConnectivityService _connectivity = ConnectivityService();
  bool _syncInProgress = false;

  static const String _baseUrl = 'http://localhost:8000/api/v1/sync';

  Future<void> init() async {
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && !_syncInProgress) {
        syncPendingItems();
      }
    });
  }

  Future<void> queueSyncItem(SyncItem item) async {
    final isOnline = await _connectivity.isConnected();

    if (isOnline) {
      // Try to sync immediately if online
      try {
        await _syncSingleItem(item);
      } catch (e) {
        // If sync fails, save locally
        print('Immediate sync failed, saving locally: $e');
        await _storage.addSyncItem(item);
      }
    } else {
      // Save locally if offline
      await _storage.addSyncItem(item);
    }
  }

  Future<void> syncPendingItems() async {
    if (_syncInProgress) {
      print('Sync already in progress');
      return;
    }

    final isOnline = await _connectivity.isConnected();
    if (!isOnline) {
      print('Device is offline, skipping sync');
      return;
    }

    final pendingItems = await _storage.getPendingItems();
    if (pendingItems.isEmpty) {
      print('No pending items to sync');
      return;
    }

    print('Syncing ${pendingItems.length} pending items');
    _syncInProgress = true;

    try {
      final syncRequest = SyncRequest(
        items: pendingItems,
        userId: await _getUserId(),
        deviceInfo: _getDeviceInfo(),
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_getToken()}',
        },
        body: jsonEncode(syncRequest.toJson()),
      );

      if (response.statusCode == 200) {
        final syncResponse = SyncResponse.fromJson(jsonDecode(response.body));

        // Process results
        for (final result in syncResponse.results) {
          if (result.status == 'success') {
            await _storage.deleteSyncItem(result.clientSyncId);
            print('Item synced successfully: ${result.clientSyncId}');
          } else {
            print('Failed to sync item ${result.clientSyncId}: ${result.errorMessage}');
            await _storage.updateSyncItemStatus(
              result.clientSyncId,
              SyncStatus.failed,
              errorMessage: result.errorMessage,
            );
          }
        }

        print('Sync completed: ${syncResponse.successfulItems} successful, ${syncResponse.failedItems} failed');
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error during sync: $e');
      // Mark items as failed
      for (final item in pendingItems) {
        await _storage.updateSyncItemStatus(
          item.clientSyncId,
          SyncStatus.failed,
          errorMessage: e.toString(),
        );
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncSingleItem(SyncItem item) async {
    final syncRequest = SyncRequest(
      items: [item],
      userId: await _getUserId(),
      deviceInfo: _getDeviceInfo(),
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/pending'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_getToken()}',
      },
      body: jsonEncode(syncRequest.toJson()),
    );

    if (response.statusCode == 200) {
      final syncResponse = SyncResponse.fromJson(jsonDecode(response.body));
      if (syncResponse.results[0].status != 'success') {
        throw Exception(syncResponse.results[0].errorMessage ?? 'Sync failed');
      }
    } else {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  Future<SyncStatusResponse> getSyncStatus() async {
    final pendingCount = await _storage.getPendingCount();
    return SyncStatusResponse(
      pendingItems: pendingCount,
      lastSyncTimestamp: null, // Could be stored in preferences
      syncInProgress: _syncInProgress,
    );
  }

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health'),
      headers: {
        'Authorization': 'Bearer ${_getToken()}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Health check failed');
    }
  }

  Future<String?> _getToken() async {
    return await Session.getToken();
  }

  Future<int?> _getUserId() async {
    // Extract user ID from token or session
    // For now, return null - can be implemented later
    return null;
  }

  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': 'flutter',
      'device_type': 'mobile',
      // Add more device info as needed
    };
  }

  bool get syncInProgress => _syncInProgress;
}
