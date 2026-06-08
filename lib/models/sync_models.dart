enum OperationType {
  create,
  update,
  delete,
}

enum EntityType {
  solicitud_servicio,
  diagnostico,
  servicio,
  incidente,
}

enum SyncStatus {
  pending,
  processing,
  completed,
  failed,
}

class SyncItem {
  final OperationType operationType;
  final EntityType entityType;
  final String clientSyncId;
  final int? entityId;
  final Map<String, dynamic> payload;
  final DateTime? clientTimestamp;

  SyncItem({
    required this.operationType,
    required this.entityType,
    required this.clientSyncId,
    this.entityId,
    required this.payload,
    this.clientTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation_type': operationType.name,
      'entity_type': entityType.name,
      'client_sync_id': clientSyncId,
      'entity_id': entityId,
      'payload': payload,
      'client_timestamp': clientTimestamp?.toIso8601String(),
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      operationType: OperationType.values.firstWhere(
        (e) => e.name == json['operation_type'],
      ),
      entityType: EntityType.values.firstWhere(
        (e) => e.name == json['entity_type'],
      ),
      clientSyncId: json['client_sync_id'],
      entityId: json['entity_id'],
      payload: json['payload'] as Map<String, dynamic>,
      clientTimestamp: json['client_timestamp'] != null
          ? DateTime.parse(json['client_timestamp'])
          : null,
    );
  }
}

class SyncRequest {
  final List<SyncItem> items;
  final int? userId;
  final Map<String, dynamic>? deviceInfo;

  SyncRequest({
    required this.items,
    this.userId,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'user_id': userId,
      'device_info': deviceInfo,
    };
  }
}

class SyncItemResult {
  final String clientSyncId;
  final String status;
  final int? serverEntityId;
  final String? errorMessage;

  SyncItemResult({
    required this.clientSyncId,
    required this.status,
    this.serverEntityId,
    this.errorMessage,
  });

  factory SyncItemResult.fromJson(Map<String, dynamic> json) {
    return SyncItemResult(
      clientSyncId: json['client_sync_id'],
      status: json['status'],
      serverEntityId: json['server_entity_id'],
      errorMessage: json['error_message'],
    );
  }
}

class SyncResponse {
  final bool success;
  final int totalItems;
  final int successfulItems;
  final int failedItems;
  final int conflictedItems;
  final List<SyncItemResult> results;
  final DateTime serverTimestamp;

  SyncResponse({
    required this.success,
    required this.totalItems,
    required this.successfulItems,
    required this.failedItems,
    required this.conflictedItems,
    required this.results,
    required this.serverTimestamp,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      success: json['success'],
      totalItems: json['total_items'],
      successfulItems: json['successful_items'],
      failedItems: json['failed_items'],
      conflictedItems: json['conflicted_items'],
      results: (json['results'] as List)
          .map((item) => SyncItemResult.fromJson(item))
          .toList(),
      serverTimestamp: DateTime.parse(json['server_timestamp']),
    );
  }
}

class SyncStatusResponse {
  final int pendingItems;
  final DateTime? lastSyncTimestamp;
  final bool syncInProgress;

  SyncStatusResponse({
    required this.pendingItems,
    this.lastSyncTimestamp,
    required this.syncInProgress,
  });

  factory SyncStatusResponse.fromJson(Map<String, dynamic> json) {
    return SyncStatusResponse(
      pendingItems: json['pending_items'],
      lastSyncTimestamp: json['last_sync_timestamp'] != null
          ? DateTime.parse(json['last_sync_timestamp'])
          : null,
      syncInProgress: json['sync_in_progress'],
    );
  }
}
