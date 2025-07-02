import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class GetAllTodosUsecase {
  final TodoRepository _repository;

  GetAllTodosUsecase(this._repository);

  Future<List<Todo>> call() async {
    return await _repository.getAllTodos();
  }

  Stream<List<Todo>> watch() {
    return _repository.watchTodos();
  }
}