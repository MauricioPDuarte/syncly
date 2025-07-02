import 'package:flutter/material.dart';
import '../../interfaces/i_storage_provider.dart';
import '../utils/sync_dialogs.dart';

class SyncIndicatorController extends ChangeNotifier {
  static const String _compactModeKey = 'sync_indicator_compact_mode';

  final IStorageProvider storageService;
  BuildContext? _context;

  bool? _compactMode;
  bool get compactMode => _compactMode ?? true;

  SyncIndicatorController(this.storageService) {
    _loadCompactMode();
  }

  /// Define o contexto para exibição de diálogos
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Carrega a preferência de modo compacto do storage
  Future<void> _loadCompactMode() async {
    try {
      final compactMode = await storageService.getBool(_compactModeKey);
      _compactMode = compactMode ?? true;
      notifyListeners();
    } catch (e) {
      // Em caso de erro, usa o valor padrão (modo compacto ativado)
      _compactMode = true;
      notifyListeners();
    }
  }

  /// Define o modo compacto e persiste no storage
  Future<void> setCompactMode(bool value) async {
    try {
      await storageService.setBool(_compactModeKey, value);
      _compactMode = value;
      notifyListeners();
      if (_context != null) {
        SyncDialogs.showSnackBar(
          context: _context!,
          message: value ? 'Modo compacto ativado' : 'Modo compacto desativado',
        );
      }
    } catch (e) {
      if (_context != null) {
        SyncDialogs.showSnackBar(
          context: _context!,
          message: 'Erro ao salvar preferências do aplicativo',
          isError: true,
        );
      }
      rethrow;
    }
  }

  /// Alterna entre modo compacto e normal
  Future<void> toggleCompactMode() async {
    await setCompactMode(!compactMode);
  }

  /// Força o recarregamento da preferência do storage
  Future<void> reload() async {
    await _loadCompactMode();
  }
}
