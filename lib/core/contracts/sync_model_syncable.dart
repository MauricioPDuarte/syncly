/// Classe abstrata base para modelos que podem ser sincronizados
/// Força a implementação de métodos essenciais para sincronização
abstract interface class SyncModelSyncable {
  String get id;
  String get entityType;
  Map<String, dynamic> toJson();
  DateTime get createdAt;
  DateTime get updatedAt;
  bool get isMediaEntity => false;
}
