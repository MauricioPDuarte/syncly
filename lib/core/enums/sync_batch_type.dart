/// Tipos de lote para sincronização
///
/// Define os tipos de dados que podem ser sincronizados:
/// - [files]: Lotes contendo arquivos para upload
/// - [data]: Lotes contendo dados estruturados (não arquivos)
enum SyncBatchType {
  files('FILES'),
  data('DATA');

  const SyncBatchType(this.displayName);

  final String displayName;
}
