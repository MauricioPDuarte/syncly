class SyncError {
  final String id;
  final String message;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? category;
  final String? entityType;
  final String? entityId;
  final bool isSent;

  const SyncError({
    required this.id,
    required this.message,
    this.stackTrace,
    this.metadata,
    required this.timestamp,
    this.category,
    this.entityType,
    this.entityId,
    this.isSent = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'stackTrace': stackTrace,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'entityType': entityType,
      'entityId': entityId,
      'isSent': isSent,
    };
  }

  factory SyncError.fromJson(Map<String, dynamic> json) {
    return SyncError(
      id: json['id'],
      message: json['message'],
      stackTrace: json['stackTrace'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
      category: json['category'],
      entityType: json['entityType'],
      entityId: json['entityId'],
      isSent: json['isSent'] ?? false,
    );
  }

  SyncError copyWith({
    String? id,
    String? message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    String? category,
    String? entityType,
    String? entityId,
    bool? isSent,
  }) {
    return SyncError(
      id: id ?? this.id,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      isSent: isSent ?? this.isSent,
    );
  }
}
