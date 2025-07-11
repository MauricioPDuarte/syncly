# Guia de Sincronização Incremental - Syncly

## Visão Geral

A sincronização incremental é uma otimização que permite ao Syncly sincronizar apenas os dados que foram modificados desde a última sincronização, em vez de baixar todos os dados novamente. Isso resulta em:

- ✅ **Menor uso de dados** - Transfere apenas o que mudou
- ✅ **Sincronização mais rápida** - Menos dados para processar
- ✅ **Melhor experiência do usuário** - Sincronizações mais frequentes e rápidas
- ✅ **Menor carga no servidor** - Reduz o processamento no backend

## Como Funciona

### Fluxo da Sincronização Incremental

1. **Verificação de Timestamp**: O Syncly verifica quando foi a última sincronização bem-sucedida
2. **Decisão do Tipo de Sync**: 
   - Se nunca houve sincronização → Sincronização completa
   - Se a última foi há muito tempo → Sincronização completa
   - Caso contrário → Sincronização incremental
3. **Envio da Data**: Para sincronização incremental, envia a data da última sincronização para o servidor
4. **Recebimento de Dados**: O servidor retorna apenas:
   - Dados novos criados desde a última sincronização
   - Dados atualizados desde a última sincronização
   - Lista de IDs de dados que foram excluídos
5. **Processamento Local**: 
   - Salva/atualiza os dados novos e modificados
   - Remove os dados que foram excluídos no servidor
6. **Atualização do Timestamp**: Salva o timestamp da sincronização bem-sucedida

## Implementação

### 1. Atualizar o SyncConfig

Implemente os novos métodos obrigatórios no seu `SyncConfig`:

```dart
class MeuSyncConfig extends SyncConfig {
  // ... outras implementações ...

  // ========== SINCRONIZAÇÃO INCREMENTAL ==========
  
  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('last_sync_timestamp');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  @override
  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_timestamp', timestamp.toIso8601String());
  }

  // Método clearSpecificData não é mais necessário
  // As estratégias de download são responsáveis por deletar os dados localmente

  @override
  bool get useIncrementalSync => true; // Habilitar sincronização incremental

  @override
  Duration get maxIncrementalSyncInterval => const Duration(days: 7); // Sincronização completa a cada 7 dias
}
```

### 2. Atualizar as Estratégias de Download

Modifique suas estratégias de download para suportar o parâmetro `lastSyncTimestamp`:

```dart
class MinhaDownloadStrategy implements IDownloadStrategy {
  @override
  Future<DownloadResult> downloadData({
    DateTime? lastSyncTimestamp,
    bool isIncremental = false,
  }) async {
    try {
      if (isIncremental && lastSyncTimestamp != null) {
        return await _performIncrementalSync(lastSyncTimestamp);
      } else {
        return await _performFullSync();
      }
    } catch (e) {
      return DownloadResult.failure('Erro no download: $e');
    }
  }

  Future<DownloadResult> _performIncrementalSync(DateTime lastSyncTimestamp) async {
    // Fazer requisição para endpoint incremental
    final response = await httpClient.get(
      '/api/data/incremental',
      queryParameters: {
        'since': lastSyncTimestamp.toIso8601String(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final newItems = data['new'] as List? ?? [];
    final updatedItems = data['updated'] as List? ?? [];
    final deletedIds = (data['deleted'] as List?)?.cast<String>() ?? [];

    // Salvar novos e atualizados
    await _saveToDatabase([...newItems, ...updatedItems]);

    // Deletar itens que foram excluídos no servidor
    if (deletedIds.isNotEmpty) {
      await _deleteFromDatabase(deletedIds);
    }

    return DownloadResult.success(
      message: 'Sincronização incremental concluída',
      itemsDownloaded: newItems.length + updatedItems.length,
      isIncremental: true,
    );
  }

  Future<DownloadResult> _performFullSync() async {
    // Fazer requisição para endpoint completo
    final response = await httpClient.get('/api/data/all');
    final data = response.data as List;

    await _saveToDatabase(data);

    return DownloadResult.success(
      message: 'Sincronização completa concluída',
      itemsDownloaded: data.length,
      isIncremental: false,
    );
  }

  Future<void> _deleteFromDatabase(List<String> deletedIds) async {
    // Implementar remoção dos itens deletados no servidor
    for (final id in deletedIds) {
      await database.delete(
        'minha_tabela',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
```

### 3. Implementar Endpoints no Backend

Seu backend precisa suportar sincronização incremental:

#### Endpoint de Sincronização Incremental
```http
GET /api/data/incremental?since=2024-01-15T10:30:00Z
```

**Resposta esperada:**
```json
{
  "new": [
    {"id": "123", "name": "Novo Item", "created_at": "2024-01-16T09:00:00Z"},
    // ... outros itens novos
  ],
  "updated": [
    {"id": "456", "name": "Item Atualizado", "updated_at": "2024-01-16T11:00:00Z"},
    // ... outros itens atualizados
  ],
  "deleted": ["789", "101"] // IDs dos itens excluídos
}
```

#### Endpoint de Sincronização Completa
```http
GET /api/data/all
```

**Resposta esperada:**
```json
[
  {"id": "123", "name": "Item 1", "created_at": "2024-01-15T09:00:00Z"},
  {"id": "456", "name": "Item 2", "created_at": "2024-01-15T10:00:00Z"},
  // ... todos os itens
]
```

## Configurações Avançadas

### Forçar Sincronização Completa

Para desabilitar temporariamente a sincronização incremental:

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get useIncrementalSync => false; // Sempre usar sincronização completa
}
```

### Ajustar Intervalo Máximo

Para controlar quando fazer sincronização completa:

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  Duration get maxIncrementalSyncInterval => const Duration(days: 3); // Sincronização completa a cada 3 dias
}
```

## Exemplo Completo

Veja o arquivo `example/lib/core/services/sync/strategies/incremental_download_strategy_example.dart` para um exemplo completo de implementação.

## Benefícios da Implementação

### Antes (Sincronização Completa)
- ❌ Apaga todos os dados locais
- ❌ Baixa todos os dados novamente
- ❌ Lento e consome muitos dados
- ❌ Experiência ruim para o usuário

### Depois (Sincronização Incremental)
- ✅ Mantém dados existentes
- ✅ Baixa apenas o que mudou
- ✅ Rápido e eficiente
- ✅ Estratégias de download gerenciam suas próprias deleções
- ✅ Melhor experiência do usuário

## Considerações Importantes

1. **Fallback para Sincronização Completa**: O sistema automaticamente volta para sincronização completa em casos de erro ou quando necessário

2. **Timestamps Precisos**: Certifique-se de que seu servidor e cliente tenham timestamps precisos e consistentes

3. **Tratamento de Conflitos**: Implemente lógica adequada para lidar com conflitos de dados

4. **Testes**: Teste tanto a sincronização incremental quanto a completa

5. **Monitoramento**: Monitore o desempenho e a eficácia da sincronização incremental

## Migração

Para migrar de sincronização completa para incremental:

1. Implemente os novos métodos no `SyncConfig`
2. Atualize suas estratégias de download
3. Implemente os endpoints incrementais no backend
4. Teste extensivamente
5. Ative gradualmente em produção

A primeira sincronização após a migração será sempre completa, e as subsequentes serão incrementais.