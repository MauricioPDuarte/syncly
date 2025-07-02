import '../../enums/sync_status.dart';
import '../../theme/sync_theme.dart';
import 'package:flutter/material.dart';

/// Classe utilitária para helpers relacionados ao status de sincronização
class SyncStatusHelpers {
  /// Retorna o texto do status baseado no SyncStatus e conectividade
  static String getStatusText(SyncStatus status, bool isOnline) {
    if (!isOnline) {
      return 'Sem conexão';
    }

    switch (status) {
      case SyncStatus.idle:
        return 'Aguardando';
      case SyncStatus.syncing:
        return 'Sincronizando dados...';
      case SyncStatus.success:
        return 'Sincronizado com sucesso';
      case SyncStatus.error:
        return 'Erro na sincronização';
      case SyncStatus.offline:
        return 'Modo offline';
      case SyncStatus.degraded:
        return 'Funcionando com limitações';
      case SyncStatus.recovery:
        return 'Tentando recuperar...';
    }
  }

  /// Retorna a cor de fundo baseada no SyncStatus e conectividade
  static Color getBackgroundColor(SyncStatus status, bool isOnline) {
    final theme = SyncThemeProvider.current;
    
    if (!isOnline) {
      return theme.error.withValues(alpha: 0.1);
    }

    switch (status) {
      case SyncStatus.idle:
      case SyncStatus.success:
        return theme.success.withValues(alpha: 0.1);
      case SyncStatus.syncing:
        return theme.primary.withValues(alpha: 0.1);
      case SyncStatus.error:
      case SyncStatus.offline:
        return theme.error.withValues(alpha: 0.1);
      case SyncStatus.degraded:
      case SyncStatus.recovery:
        return theme.warning.withValues(alpha: 0.1);
    }
  }

  /// Retorna a cor da borda baseada no SyncStatus e conectividade
  static Color getBorderColor(SyncStatus status, bool isOnline) {
    final theme = SyncThemeProvider.current;
    
    if (!isOnline) {
      return theme.error.withValues(alpha: 0.3);
    }

    switch (status) {
      case SyncStatus.idle:
      case SyncStatus.success:
        return theme.success.withValues(alpha: 0.3);
      case SyncStatus.syncing:
        return theme.primary.withValues(alpha: 0.3);
      case SyncStatus.error:
      case SyncStatus.offline:
        return theme.error.withValues(alpha: 0.3);
      case SyncStatus.degraded:
      case SyncStatus.recovery:
        return theme.warning.withValues(alpha: 0.3);
    }
  }

  /// Retorna a cor do texto baseada no SyncStatus e conectividade
  static Color getTextColor(SyncStatus status, bool isOnline) {
    final theme = SyncThemeProvider.current;
    
    if (!isOnline) {
      return theme.error;
    }

    switch (status) {
      case SyncStatus.idle:
      case SyncStatus.success:
        return theme.success;
      case SyncStatus.syncing:
        return theme.primary;
      case SyncStatus.error:
      case SyncStatus.offline:
        return theme.error;
      case SyncStatus.degraded:
      case SyncStatus.recovery:
        return theme.warning;
    }
  }

  /// Retorna a cor do status para uso em detalhes
  static Color getStatusColor(SyncStatus status, bool isOnline) {
    final theme = SyncThemeProvider.current;
    
    if (!isOnline) {
      return theme.error;
    }

    switch (status) {
      case SyncStatus.idle:
        return theme.textSecondary;
      case SyncStatus.syncing:
        return theme.primary;
      case SyncStatus.success:
        return theme.success;
      case SyncStatus.error:
      case SyncStatus.offline:
        return theme.error;
      case SyncStatus.degraded:
      case SyncStatus.recovery:
        return theme.warning;
    }
  }

  /// Formata data e hora para exibição amigável
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${dateTime.day}/${dateTime.month} às ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
