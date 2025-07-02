/// Operações de sincronização disponíveis
///
/// Define as operações que podem ser realizadas nas entidades:
/// - [create]: Criação de nova entidade
/// - [update]: Atualização de entidade existente
/// - [delete]: Exclusão de entidade
enum SyncOperation {
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE');

  const SyncOperation(this.value);
  final String value;

  /// Converte uma string para o enum correspondente
  static SyncOperation fromString(String value) {
    return SyncOperation.values.firstWhere(
      (operation) => operation.value == value,
      orElse: () => throw ArgumentError('Operação não suportada: $value'),
    );
  }
}