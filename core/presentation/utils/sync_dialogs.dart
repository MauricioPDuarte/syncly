import 'package:flutter/material.dart';
import '../../theme/sync_theme.dart';

/// Utilitário para exibir diálogos específicos do módulo de sincronização
///
/// Esta classe fornece métodos para exibir diálogos padronizados
/// usando o sistema de tema do sync, mantendo independência do projeto base.
class SyncDialogs {
  /// Exibe um diálogo de confirmação com duas opções
  ///
  /// Parâmetros:
  /// - [buildContext]: Contexto do widget
  /// - [title]: Título do diálogo
  /// - [subtitle]: Texto de descrição/conteúdo
  /// - [confirmationText]: Texto do botão de confirmação
  /// - [cancelText]: Texto do botão de cancelamento
  /// - [barrierDismissible]: Se o diálogo pode ser fechado tocando fora dele
  ///
  /// Retorna [true] se o usuário confirmou, [false] caso contrário
  static Future<bool> choiceDialog({
    required BuildContext buildContext,
    required String title,
    required String subtitle,
    required String confirmationText,
    required String cancelText,
    bool barrierDismissible = true,
  }) async {
    final theme = SyncThemeProvider.current;

    final result = await showDialog<bool>(
      context: buildContext,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        title: Text(
          title,
          style: theme.titleStyle,
        ),
        content: Text(
          subtitle,
          style: theme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: theme.buttonStyle.copyWith(
                color: theme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
            ),
            child: Text(
              confirmationText,
              style: theme.buttonStyle,
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Exibe um diálogo de informação simples
  ///
  /// Parâmetros:
  /// - [buildContext]: Contexto do widget
  /// - [title]: Título do diálogo
  /// - [message]: Mensagem a ser exibida
  /// - [buttonText]: Texto do botão (padrão: "OK")
  static Future<void> infoDialog({
    required BuildContext buildContext,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    final theme = SyncThemeProvider.current;

    await showDialog(
      context: buildContext,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        title: Text(
          title,
          style: theme.titleStyle,
        ),
        content: Text(
          message,
          style: theme.bodyStyle,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
            ),
            child: Text(
              buttonText,
              style: theme.buttonStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe um diálogo de erro
  ///
  /// Parâmetros:
  /// - [buildContext]: Contexto do widget
  /// - [title]: Título do diálogo (padrão: "Erro")
  /// - [message]: Mensagem de erro
  /// - [buttonText]: Texto do botão (padrão: "OK")
  static Future<void> errorDialog({
    required BuildContext buildContext,
    String title = 'Erro',
    required String message,
    String buttonText = 'OK',
  }) async {
    final theme = SyncThemeProvider.current;

    await showDialog(
      context: buildContext,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.error,
              size: 24,
            ),
            SizedBox(width: theme.spacingSmall),
            Text(
              title,
              style: theme.titleStyle.copyWith(color: theme.error),
            ),
          ],
        ),
        content: Text(
          message,
          style: theme.bodyStyle,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
            ),
            child: Text(
              buttonText,
              style: theme.buttonStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe um diálogo de sucesso
  ///
  /// Parâmetros:
  /// - [buildContext]: Contexto do widget
  /// - [title]: Título do diálogo (padrão: "Sucesso")
  /// - [message]: Mensagem de sucesso
  /// - [buttonText]: Texto do botão (padrão: "OK")
  static Future<void> successDialog({
    required BuildContext buildContext,
    String title = 'Sucesso',
    required String message,
    String buttonText = 'OK',
  }) async {
    final theme = SyncThemeProvider.current;

    await showDialog(
      context: buildContext,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: theme.success,
              size: 24,
            ),
            SizedBox(width: theme.spacingSmall),
            Text(
              title,
              style: theme.titleStyle.copyWith(color: theme.success),
            ),
          ],
        ),
        content: Text(
          message,
          style: theme.bodyStyle,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
            ),
            child: Text(
              buttonText,
              style: theme.buttonStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe uma mensagem de feedback rápido (SnackBar)
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
  }) {
    final theme = SyncThemeProvider.current;
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.bodyStyle.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? theme.error : theme.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
