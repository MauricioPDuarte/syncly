import 'package:syncly/sync.dart';
import 'package:uuid/uuid.dart';

class Todo {
  final String id;
  
  final String title;
  final String description;
  final bool isCompleted;
  
  final DateTime createdAt;
  
  final DateTime updatedAt;
  
  final DateTime? lastSyncAt;
  final bool needsSync;
  final SyncOperation pendingOperation;
  
  String get entityType => 'todo';
  
  bool get isMediaEntity => false;

  Todo({
    String? id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastSyncAt,
    this.needsSync = true,
    this.pendingOperation = SyncOperation.create,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncAt,
    bool? needsSync,
    SyncOperation? pendingOperation,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      needsSync: needsSync ?? this.needsSync,
      pendingOperation: pendingOperation ?? this.pendingOperation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'needsSync': needsSync,
      'pendingOperation': pendingOperation.name,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSyncAt: json['lastSyncAt'] != null 
          ? DateTime.parse(json['lastSyncAt'] as String) 
          : null,
      needsSync: json['needsSync'] as bool? ?? true,
      pendingOperation: SyncOperation.values.firstWhere(
        (e) => e.name == json['pendingOperation'],
        orElse: () => SyncOperation.create,
      ),
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, isCompleted: $isCompleted, needsSync: $needsSync)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}