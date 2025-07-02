/// Interface abstrata para serviços de armazenamento
abstract class StorageService {
  // Métodos básicos para strings
  Future<bool> setString(String key, String value);
  Future<String?> getString(String key);
  
  // Métodos básicos para booleanos
  Future<bool> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  
  // Métodos básicos para inteiros
  Future<bool> setInt(String key, int value);
  Future<int?> getInt(String key);
  
  // Métodos para listas de strings
  Future<bool> setStringList(String key, List<String> value);
  Future<List<String>?> getStringList(String key);
  
  // Métodos para objetos JSON
  Future<bool> setJson(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getJson(String key);
  
  // Métodos para listas de objetos JSON
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value);
  Future<List<Map<String, dynamic>>?> getJsonList(String key);
  
  // Métodos de controle
  Future<bool> remove(String key);
  Future<bool> clear();
  Future<bool> containsKey(String key);
  Future<Set<String>> getKeys();
}