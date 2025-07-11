import 'package:syncly/sync.dart';
import 'package:flutter/foundation.dart';

/// Exemplo de implementação de uma estratégia de download que suporta sincronização incremental
///
/// Esta classe demonstra como implementar uma estratégia que:
/// - Faz sincronização completa quando necessário
/// - Faz sincronização incremental baseada em timestamp
/// - Retorna informações sobre dados excluídos no servidor
class IncrementalDownloadStrategyExample implements IDownloadStrategy {
  final String baseUrl;
  final String entityType;
  
  IncrementalDownloadStrategyExample({
    required this.baseUrl,
    required this.entityType,
  });

  @override
  Future<DownloadResult> downloadData({DateTime? lastSyncTimestamp}) async {
    try {
      final isIncremental = lastSyncTimestamp != null;
      
      debugPrint('=== Iniciando download $entityType (${isIncremental ? 'incremental' : 'completo'}) ===');
      
      if (isIncremental) {
        debugPrint('Última sincronização: $lastSyncTimestamp');
        return await _performIncrementalSync(lastSyncTimestamp);
      } else {
        return await _performFullSync();
      }
    } catch (e) {
      debugPrint('Erro no download de $entityType: $e');
      return DownloadResult.failure('Erro ao baixar $entityType: $e');
    }
  }

  /// Executa sincronização completa
  Future<DownloadResult> _performFullSync() async {
    debugPrint('Executando sincronização completa para $entityType...');
    
    // TODO: Implementar chamada para o endpoint de sincronização completa
    // Exemplo:
    // final response = await httpClient.get('$baseUrl/$entityType/all');
    // final data = response.data as List;
    // await _saveDataToLocalDatabase(data);
    
    // Simulação para exemplo
    await Future.delayed(const Duration(seconds: 1));
    const itemsDownloaded = 100; // Simular 100 itens baixados
    
    debugPrint('Sincronização completa de $entityType concluída: $itemsDownloaded itens');
    
    return DownloadResult.success(
      message: 'Sincronização completa de $entityType concluída',
      itemsDownloaded: itemsDownloaded,
      isIncremental: false,
      metadata: {
        'entityType': entityType,
        'syncType': 'full',
      },
    );
  }

  /// Executa sincronização incremental
  Future<DownloadResult> _performIncrementalSync(DateTime lastSyncTimestamp) async {
    debugPrint('Executando sincronização incremental para $entityType desde $lastSyncTimestamp...');
    
    // TODO: Implementar chamada para o endpoint de sincronização incremental
    // Exemplo:
    // final response = await httpClient.get(
    //   '$baseUrl/$entityType/incremental',
    //   queryParameters: {
    //     'since': lastSyncTimestamp.toIso8601String(),
    //   },
    // );
    // 
    // final responseData = response.data as Map<String, dynamic>;
    // final newItems = responseData['new'] as List? ?? [];
    // final updatedItems = responseData['updated'] as List? ?? [];
    // final deletedIds = responseData['deleted'] as List<String>? ?? [];
    // 
    // // Salvar novos e atualizados
    // await _saveDataToLocalDatabase([...newItems, ...updatedItems]);
    // 
    // // Retornar informações sobre excluídos para processamento
    // final deletedEntities = deletedIds.isNotEmpty 
    //     ? {entityType: deletedIds} 
    //     : null;
    
    // Simulação para exemplo
    await Future.delayed(const Duration(milliseconds: 500));
    const newItems = 5; // Simular 5 novos itens
    const updatedItems = 3; // Simular 3 itens atualizados
    const deletedIds = ['item_123', 'item_456']; // Simular 2 itens excluídos
    
    const totalItems = newItems + updatedItems;
    final deletedEntities = deletedIds.isNotEmpty 
        ? {entityType: deletedIds} 
        : null;
    
    debugPrint('Sincronização incremental de $entityType concluída:');
    debugPrint('  - Novos: $newItems');
    debugPrint('  - Atualizados: $updatedItems');
    debugPrint('  - Excluídos: ${deletedIds.length}');
    
    return DownloadResult.success(
      message: 'Sincronização incremental de $entityType concluída',
      itemsDownloaded: totalItems,
      isIncremental: true,
      deletedEntities: deletedEntities,
      metadata: {
        'entityType': entityType,
        'syncType': 'incremental',
        'newItems': newItems,
        'updatedItems': updatedItems,
        'deletedItems': deletedIds.length,
      },
    );
  }

  /// Salva dados no banco de dados local
  /// 
  /// TODO: Implementar baseado no seu sistema de persistência quando necessário
  // Future<void> _saveDataToLocalDatabase(List<dynamic> data) async {
  //   // Exemplo de implementação:
  //   // for (final item in data) {
  //   //   await database.insertOrUpdate(entityType, item);
  //   // }
  //   
  //   debugPrint('Salvando ${data.length} itens de $entityType no banco local...');
  // }
}

/// Exemplo de como registrar as estratégias incrementais
class IncrementalSyncStrategiesExample {
  static List<IDownloadStrategy> getStrategies(String baseUrl) {
    return [
      IncrementalDownloadStrategyExample(
        baseUrl: baseUrl,
        entityType: 'users',
      ),
      IncrementalDownloadStrategyExample(
        baseUrl: baseUrl,
        entityType: 'products',
      ),
      IncrementalDownloadStrategyExample(
        baseUrl: baseUrl,
        entityType: 'orders',
      ),
    ];
  }
}