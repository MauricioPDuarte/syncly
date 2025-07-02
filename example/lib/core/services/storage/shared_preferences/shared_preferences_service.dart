import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage_service.dart';

class SharedPreferencesService implements StorageService {
  final SharedPreferences? _prefs;
  final Map<String, dynamic> _mockStorage = {}; // Storage mock para exemplo

  SharedPreferencesService(this._prefs);

  // Generic methods for storing and retrieving data
  @override
  Future<bool> setString(String key, String value) async {
    if (_prefs != null) {
      return await _prefs!.setString(key, value);
    } else {
      _mockStorage[key] = value;
      return true;
    }
  }

  @override
  String? getString(String key) {
    if (_prefs != null) {
      return _prefs!.getString(key);
    } else {
      return _mockStorage[key] as String?;
    }
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    if (_prefs != null) {
      return await _prefs!.setBool(key, value);
    } else {
      _mockStorage[key] = value;
      return true;
    }
  }

  @override
  bool? getBool(String key) {
    if (_prefs != null) {
      return _prefs!.getBool(key);
    } else {
      return _mockStorage[key] as bool?;
    }
  }

  @override
  Future<bool> setInt(String key, int value) async {
    if (_prefs != null) {
      return await _prefs!.setInt(key, value);
    } else {
      _mockStorage[key] = value;
      return true;
    }
  }

  @override
  int? getInt(String key) {
    if (_prefs != null) {
      return _prefs!.getInt(key);
    } else {
      return _mockStorage[key] as int?;
    }
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    if (_prefs != null) {
      return await _prefs!.setStringList(key, value);
    } else {
      _mockStorage[key] = value;
      return true;
    }
  }

  @override
  List<String>? getStringList(String key) {
    if (_prefs != null) {
      return _prefs!.getStringList(key);
    } else {
      return _mockStorage[key] as List<String>?;
    }
  }

  // JSON methods for complex objects
  @override
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }

  @override
  Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
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
  List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = getString(key);
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
    if (_prefs != null) {
      return await _prefs!.remove(key);
    } else {
      _mockStorage.remove(key);
      return true;
    }
  }

  @override
  Future<bool> clear() async {
    if (_prefs != null) {
      return await _prefs!.clear();
    } else {
      _mockStorage.clear();
      return true;
    }
  }

  @override
  bool containsKey(String key) {
    if (_prefs != null) {
      return _prefs!.containsKey(key);
    } else {
      return _mockStorage.containsKey(key);
    }
  }

  @override
  Set<String> getKeys() {
    if (_prefs != null) {
      return _prefs!.getKeys();
    } else {
      return _mockStorage.keys.toSet();
    }
  }
}
