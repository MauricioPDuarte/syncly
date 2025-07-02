import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage_service.dart';

class SharedPreferencesService implements StorageService {
  SharedPreferences? _prefs;

  SharedPreferencesService();

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Generic methods for storing and retrieving data
  @override
  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs!.getBool(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs!.getInt(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    return await _prefs!.setStringList(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    await _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  // JSON methods for complex objects
  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> remove(String key) async {
    await _ensureInitialized();
    return await _prefs!.remove(key);
  }

  @override
  Future<bool> clear() async {
    await _ensureInitialized();
    return await _prefs!.clear();
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
}
