import 'dart:async';
import 'package:syncly/sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly_example/core/services/rest_client/rest_client.dart';

/// Downloader específico para download de Todos
///
/// Esta classe é responsável por:
/// - Buscar Todos do servidor
/// - Processar e salvar os dados no banco local
class TodoDownloader implements IDownloadStrategy {
  late final RestClient _restClient;

  TodoDownloader() {
    // Obter RestClient do container de injeção de dependência
    _restClient = Modular.get<RestClient>();
  }

  @override
  Future<DownloadResult> downloadData() async {
    try {
      debugPrint('Buscando todos atualizados...');

      // Simular download de dados do servidor
      await Future.delayed(const Duration(seconds: 1));

      // Para o exemplo, retornamos sucesso sem dados reais
      debugPrint('Todos baixados com sucesso');

      return DownloadResult.success(
        message: 'Todos baixados com sucesso',
        itemsDownloaded: 0,
        metadata: {
          'type': 'todos',
        },
      );
    } catch (e) {
      debugPrint('Erro ao baixar Todos: $e');
      return DownloadResult.failure('Erro ao baixar Todos: $e');
    }
  }
}
