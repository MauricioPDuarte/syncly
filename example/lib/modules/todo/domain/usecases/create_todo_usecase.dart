import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class CreateTodoUsecase {
  final TodoRepository _repository;

  CreateTodoUsecase(this._repository);

  Future<void> call({
    required String title,
    required String description,
  }) async {
    final todo = Todo(
      title: title,
      description: description,
    );
    
    await _repository.saveTodo(todo);
  }
}