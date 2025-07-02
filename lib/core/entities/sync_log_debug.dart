import '../enums/sync_log_debug_level.dart';

class SyncLogDebug {
  final String id;
  final DateTime timestamp;
  final SyncLogDebugLevel level;
  final String message;
  final String? category;
  final String? tag;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;
  final String? userId;
  final String? sessionId;

  const SyncLogDebug({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.category,
    this.tag,
    this.metadata,
    this.stackTrace,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'category': category,
      'tag': tag,
      'metadata': metadata,
      'stackTrace': stackTrace,
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  factory SyncLogDebug.fromJson(Map<String, dynamic> json) {
    return SyncLogDebug(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      level: SyncLogDebugLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => SyncLogDebugLevel.info,
      ),
      message: json['message'],
      category: json['category'],
      tag: json['tag'],
      metadata: json['metadata'],
      stackTrace: json['stackTrace'],
      userId: json['userId'],
      sessionId: json['sessionId'],
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${level.name.toUpperCase()}] ');
    buffer.write('${timestamp.toIso8601String()} ');
    if (category != null) buffer.write('[$category] ');
    if (tag != null) buffer.write('($tag) ');
    buffer.write(message);
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write(' | Metadata: $metadata');
    }
    return buffer.toString();
  }
}
