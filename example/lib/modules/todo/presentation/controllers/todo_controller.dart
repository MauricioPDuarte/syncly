import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/todo.dart';
import '../../domain/usecases/get_all_todos_usecase.dart';
import '../../domain/usecases/create_todo_usecase.dart';
import '../../domain/usecases/toggle_todo_usecase.dart';
import '../../domain/usecases/delete_todo_usecase.dart';

class TodoController {
  final GetAllTodosUsecase _getAllTodosUsecase;
  final CreateTodoUsecase _createTodoUsecase;
  final ToggleTodoUsecase _toggleTodoUsecase;
  final DeleteTodoUsecase _deleteTodoUsecase;

  // State management with ValueNotifier
  final ValueNotifier<List<Todo>> todos = ValueNotifier<List<Todo>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  
  StreamSubscription<List<Todo>>? _todosSubscription;

  TodoController(
    this._getAllTodosUsecase,
    this._createTodoUsecase,
    this._toggleTodoUsecase,
    this._deleteTodoUsecase,
  ) {
    _initializeController();
  }

  void _initializeController() {
    // Watch for todo changes
    _todosSubscription = _getAllTodosUsecase.watch().listen(
      (todoList) {
        todos.value = todoList;
        isLoading.value = false;
      },
      onError: (err) {
        error.value = err.toString();
        isLoading.value = false;
      },
    );
    
    // Load initial data
    loadTodos();
  }

  Future<void> loadTodos() async {
    try {
      isLoading.value = true;
      error.value = null;
      
      final todoList = await _getAllTodosUsecase();
      todos.value = todoList;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTodo(String title, String description) async {
    try {
      error.value = null;
      await _createTodoUsecase(title: title, description: description);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> toggleTodo(String id, bool isCompleted) async {
    try {
      error.value = null;
      await _toggleTodoUsecase(id, isCompleted);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      error.value = null;
      await _deleteTodoUsecase(id);
    } catch (e) {
      error.value = e.toString();
    }
  }

  // Computed properties
  ValueListenable<List<Todo>> get completedTodos => ValueNotifier(
    todos.value.where((todo) => todo.isCompleted).toList(),
  );

  ValueListenable<List<Todo>> get pendingTodos => ValueNotifier(
    todos.value.where((todo) => !todo.isCompleted).toList(),
  );

  ValueListenable<int> get totalTodos => ValueNotifier(todos.value.length);

  ValueListenable<int> get completedCount => ValueNotifier(
    todos.value.where((todo) => todo.isCompleted).length,
  );

  void dispose() {
    _todosSubscription?.cancel();
    todos.dispose();
    isLoading.dispose();
    error.dispose();
  }
}