import '../../entities/sync_data.dart';
import '../../enums/sync_status.dart';
import '../../interfaces/i_sync_service.dart';
import '../../theme/sync_theme.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../sync_initializer.dart';
import '../controllers/sync_indicator_controller.dart';
import '../utils/sync_status_helpers.dart';
import '../utils/sync_icon_builder.dart';
import '../utils/sync_dialogs.dart';

/// Widget para mostrar detalhes do sync em um bottom sheet
class SyncDetailsBottomSheet extends StatefulWidget {
  const SyncDetailsBottomSheet({
    super.key,
  });

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SyncDetailsBottomSheet(),
    );
  }

  @override
  State<SyncDetailsBottomSheet> createState() => _SyncDetailsBottomSheetState();
}

class _SyncDetailsBottomSheetState extends State<SyncDetailsBottomSheet> {
  bool? _backgroundSyncState;
  late final SyncIndicatorController _controller;
  late final ISyncService syncService;

  @override
  void initState() {
    super.initState();
    try {
      syncService = GetIt.instance.get<ISyncService>();
      _controller = GetIt.instance.get<SyncIndicatorController>();
      _controller.addListener(_onControllerChanged);
    } catch (e) {
      debugPrint('Serviços não disponíveis via GetIt: $e');
      // Criar um controller padrão ou lidar com o erro
      rethrow;
    }
    // Reset o estado local para forçar nova consulta
    _backgroundSyncState = null;
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle do bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Título
          const Text(
            'Detalhes da Sincronização',
            style: TextStyle(
              fontSize: 22, // Aumentado para melhor visibilidade em campo
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Status atual
          ValueListenableBuilder<SyncData>(
            valueListenable: syncService.syncData,
            builder: (context, syncData, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: syncService.isOnline,
                builder: (context, isOnline, child) {
                  return _buildStatusSection(syncData, isOnline);
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Configurações
          _buildSettingsSection(),

          const SizedBox(height: 24),

          // Ações
          ValueListenableBuilder<SyncData>(
            valueListenable: syncService.syncData,
            builder: (context, syncData, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: syncService.isOnline,
                builder: (context, isOnline, child) {
                  return _buildActionButtons(
                      context, syncData.status, isOnline);
                },
              );
            },
          ),

          // Espaço para o safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildStatusSection(SyncData syncData, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SyncIconBuilder.buildDetailedIcon(syncData.status, isOnline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isOnline
                            ? SyncThemeProvider.current.success
                            : SyncThemeProvider.current.error,
                      ),
                    ),
                    Text(
                      SyncStatusHelpers.getStatusText(
                          syncData.status, isOnline),
                      style: TextStyle(
                        color: SyncStatusHelpers.getStatusColor(
                            syncData.status, isOnline),
                        fontSize:
                            16, // Aumentado para melhor visibilidade em campo
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (syncData.lastSync != null) ...[
            const SizedBox(height: 12),
            Text(
              'Última sincronização: ${SyncStatusHelpers.formatDateTime(syncData.lastSync!)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14, // Aumentado para melhor visibilidade em campo
              ),
            ),
          ],
          if (syncData.pendingItems != null && syncData.pendingItems! > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${syncData.pendingItems} itens pendentes',
              style: TextStyle(
                color: SyncThemeProvider.current.warning,
                fontSize: 14, // Aumentado para melhor visibilidade em campo
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configurações',
          style: TextStyle(
            fontSize: 18, // Aumentado para melhor visibilidade em campo
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Sincronização em background
        _buildBackgroundSyncToggle(),
      ],
    );
  }

  Widget _buildBackgroundSyncToggle() {
    return FutureBuilder<bool>(
      future: _getBackgroundSyncState(),
      builder: (context, snapshot) {
        final isActive = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.sync : Icons.sync_disabled,
                color: isActive
                    ? SyncThemeProvider.current.success
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sincronização em Background',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isActive
                          ? 'Sincronização automática ativa'
                          : 'Sincronização automática desativada',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize:
                            14, // Aumentado para melhor visibilidade em campo
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: isActive,
                  onChanged: (value) => _toggleBackgroundSync(value),
                  activeColor: SyncThemeProvider.current.primary,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
      BuildContext context, SyncStatus status, bool isOnline) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showResetConfirmationDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SyncThemeProvider.current.error,
                  side: BorderSide(color: SyncThemeProvider.current.error),
                ),
                child: Text(
                  'Resetar',
                  style: SyncThemeProvider.current.buttonStyle.copyWith(
                      height: 0, color: SyncThemeProvider.current.error),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  syncService.forceSync();
                  Navigator.of(context).pop();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync),
                    const SizedBox(width: 8),
                    Text(
                      'Sincronizar',
                      style: SyncThemeProvider.current.buttonStyle
                          .copyWith(height: 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _getBackgroundSyncState() async {
    if (_backgroundSyncState != null) {
      return _backgroundSyncState!;
    }

    try {
      // Primeiro verifica a preferência salva pelo usuário
      final savedPreference =
          await SyncInitializer.getBackgroundSyncPreference();
      _backgroundSyncState = savedPreference;
      return savedPreference;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleBackgroundSync(bool value) async {
    try {
      if (value) {
        await syncService.startBackgroundSync();
      } else {
        await syncService.stopBackgroundSync();
      }

      // Salvar a preferência do usuário
      await SyncInitializer.saveBackgroundSyncPreference(value);

      setState(() {
        _backgroundSyncState = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar sincronização em background: $e'),
            backgroundColor: SyncThemeProvider.current.error,
          ),
        );
      }
    }
  }

  Future<void> _showResetConfirmationDialog(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await SyncDialogs.choiceDialog(
      buildContext: context,
      title: 'Confirmar Reset',
      subtitle:
          'Tem certeza que deseja resetar a sincronização?\n\nEsta ação irá apagar todas as alterações feitas localmente e é irreversível.',
      confirmationText: 'Resetar',
      cancelText: 'Cancelar',
      barrierDismissible: true,
    );

    if (confirmed && mounted) {
      syncService.resetSyncState();
      navigator.pop();
    }
  }
}
