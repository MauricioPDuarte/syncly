abstract class IStorageProvider {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> setInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> setDouble(String key, double value);
  Future<double?> getDouble(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<List<String>?> getStringList(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
  Future<Set<String>> getKeys();

  // Métodos de conveniência para armazenamento genérico
  Future<void> store(String key, String value) => setString(key, value);
  Future<String?> retrieve(String key) => getString(key);
  Future<Set<String>> getAllKeys() => getKeys();
}
