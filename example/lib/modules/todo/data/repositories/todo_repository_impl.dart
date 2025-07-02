import 'dart:async';
import 'package:syncly/sync.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_local_datasource.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDatasource _localDatasource;
  final StreamController<List<Todo>> _todosController =
      StreamController<List<Todo>>.broadcast();

  TodoRepositoryImpl(this._localDatasource);

  @override
  Future<List<Todo>> getAllTodos() async {
    final todos = await _localDatasource.getAllTodos();
    _todosController.add(todos);
    return todos;
  }

  @override
  Future<Todo?> getTodoById(String id) async {
    return await _localDatasource.getTodoById(id);
  }

  @override
  Future<void> saveTodo(Todo todo) async {
    await _localDatasource.saveTodo(todo);

    // Notify listeners
    final todos = await _localDatasource.getAllTodos();
    _todosController.add(todos);
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final updatedTodo = todo.copyWith(
      updatedAt: DateTime.now(),
      needsSync: true,
      pendingOperation: SyncOperation.update,
    );

    await _localDatasource.updateTodo(updatedTodo);

    // Notify listeners
    final todos = await _localDatasource.getAllTodos();
    _todosController.add(todos);
  }

  @override
  Future<void> deleteTodo(String id) async {
    final todo = await _localDatasource.getTodoById(id);
    if (todo != null) {
      final deleteTodo = todo.copyWith(
        needsSync: true,
        pendingOperation: SyncOperation.delete,
      );

      // Update the todo with delete flag before removing
      await _localDatasource.updateTodo(deleteTodo);
    }

    await _localDatasource.deleteTodo(id);

    // Notify listeners
    final todos = await _localDatasource.getAllTodos();
    _todosController.add(todos);
  }

  @override
  Future<void> markAsCompleted(String id) async {
    final todo = await _localDatasource.getTodoById(id);
    if (todo != null && !todo.isCompleted) {
      final updatedTodo = todo.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
        needsSync: true,
        pendingOperation: SyncOperation.update,
      );
      await updateTodo(updatedTodo);
    }
  }

  @override
  Future<void> markAsIncomplete(String id) async {
    final todo = await _localDatasource.getTodoById(id);
    if (todo != null && todo.isCompleted) {
      final updatedTodo = todo.copyWith(
        isCompleted: false,
        updatedAt: DateTime.now(),
        needsSync: true,
        pendingOperation: SyncOperation.update,
      );
      await updateTodo(updatedTodo);
    }
  }

  @override
  Stream<List<Todo>> watchTodos() {
    // Initialize with current data
    getAllTodos();
    return _todosController.stream;
  }

  void dispose() {
    _todosController.close();
  }
}
