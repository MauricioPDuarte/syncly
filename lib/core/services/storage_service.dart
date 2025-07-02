import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/i_storage_provider.dart';

/// Implementação própria de storage para o módulo sync usando SharedPreferences
///
/// Esta implementação elimina a dependência externa do core da aplicação,
/// tornando o módulo sync completamente independente.
class SyncStorageService implements IStorageProvider {
  SharedPreferences? _prefs;

  SyncStorageService();

  /// Inicializa o SharedPreferences
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs!.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs!.getBool(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _ensureInitialized();
    await _prefs!.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs!.getInt(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _ensureInitialized();
    await _prefs!.setDouble(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    await _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    await _prefs!.setStringList(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    await _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  @override
  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs!.remove(key);
  }

  @override
  Future<void> clear() async {
    await _ensureInitialized();
    await _prefs!.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  @override
  Future<Set<String>> getKeys() async {
    await _ensureInitialized();
    return _prefs!.getKeys();
  }

  // Métodos de conveniência implementados
  @override
  Future<void> store(String key, String value) => setString(key, value);

  @override
  Future<String?> retrieve(String key) => getString(key);

  @override
  Future<Set<String>> getAllKeys() => getKeys();
}
