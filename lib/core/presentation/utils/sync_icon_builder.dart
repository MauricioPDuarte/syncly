import '../../enums/sync_status.dart';
import '../../theme/sync_theme.dart';
import 'package:flutter/material.dart';

/// Classe responsável por construir ícones para o indicador de sincronização
class SyncIconBuilder {
  /// Constrói o ícone apropriado baseado no status e conectividade
  static Widget buildIcon(SyncStatus status, bool isOnline, bool isCompact) {
    final theme = SyncThemeProvider.current;
    
    if (!isOnline) {
      return Icon(
        Icons.cloud_off,
        size: isCompact ? 14 : 16,
        color: theme.error,
      );
    }

    switch (status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_done,
          size: isCompact ? 14 : 16,
          color: theme.success,
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: isCompact ? 14 : 16,
          height: isCompact ? 14 : 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        );
      case SyncStatus.success:
        return Icon(
          Icons.cloud_done,
          size: isCompact ? 14 : 16,
          color: theme.success,
        );
      case SyncStatus.error:
        return Icon(
          Icons.cloud_off,
          size: isCompact ? 14 : 16,
          color: theme.error,
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: isCompact ? 14 : 16,
          color: theme.error,
        );
      case SyncStatus.degraded:
        return Icon(
          Icons.cloud_queue,
          size: isCompact ? 14 : 16,
          color: theme.warning,
        );
      case SyncStatus.recovery:
        return Icon(
          Icons.refresh,
          size: isCompact ? 14 : 16,
          color: theme.warning,
        );
    }
  }

  /// Constrói ícone para o status detalhado no bottom sheet
  static Widget buildDetailedIcon(SyncStatus status, bool isOnline) {
    final theme = SyncThemeProvider.current;
    
    if (!isOnline) {
      return Icon(
        Icons.cloud_off,
        size: 24,
        color: theme.error,
      );
    }

    switch (status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_done,
          size: 24,
          color: theme.success,
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        );
      case SyncStatus.success:
        return Icon(
          Icons.check_circle,
          size: 24,
          color: theme.success,
        );
      case SyncStatus.error:
        return Icon(
          Icons.error,
          size: 24,
          color: theme.error,
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: 24,
          color: theme.error,
        );
      case SyncStatus.degraded:
        return Icon(
          Icons.warning,
          size: 24,
          color: theme.warning,
        );
      case SyncStatus.recovery:
        return Icon(
          Icons.refresh,
          size: 24,
          color: theme.warning,
        );
    }
  }
}
