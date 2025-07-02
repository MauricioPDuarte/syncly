import 'package:syncly/sync.dart';
import '../../../../core/services/storage/storage.dart';
import '../../domain/entities/todo.dart';

class TodoLocalDatasource {
  final StorageService _prefsService;
  final ISyncService _syncService;
  static const String _todosKey = 'todos';

  TodoLocalDatasource(this._prefsService, this._syncService);

  Future<List<Todo>> getAllTodos() async {
    final todosJson = _prefsService.getJsonList(_todosKey);
    if (todosJson == null) return [];
    
    return todosJson.map((json) => Todo.fromJson(json)).toList();
  }

  Future<Todo?> getTodoById(String id) async {
    final todos = await getAllTodos();
    try {
      return todos.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveTodo(Todo todo) async {
    final todos = await getAllTodos();
    todos.add(todo);
    await _saveTodos(todos);
    
    // Adiciona log de criação
    await _syncService.logCreate(
      entityType: 'Todo',
      entityId: todo.id,
      data: todo.toJson(),
    );
  }

  Future<void> updateTodo(Todo updatedTodo) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == updatedTodo.id);
    
    if (index != -1) {
      todos[index] = updatedTodo;
      await _saveTodos(todos);
      
      // Adiciona log de atualização
      await _syncService.logUpdate(
        entityType: 'Todo',
        entityId: updatedTodo.id,
        data: updatedTodo.toJson(),
      );
    }
  }

  Future<void> deleteTodo(String id) async {
    final todos = await getAllTodos();
    final todoToDelete = todos.firstWhere((todo) => todo.id == id, orElse: () => throw Exception('Todo not found'));
    todos.removeWhere((todo) => todo.id == id);
    await _saveTodos(todos);
    
    // Adiciona log de exclusão
    await _syncService.logDelete(
      entityType: 'Todo',
      entityId: id,
      data: todoToDelete.toJson(),
    );
  }

  Future<void> _saveTodos(List<Todo> todos) async {
    final todosJson = todos.map((todo) => todo.toJson()).toList();
    await _prefsService.setJsonList(_todosKey, todosJson);
  }

  Future<void> clearAllTodos() async {
    await _prefsService.remove(_todosKey);
  }
}