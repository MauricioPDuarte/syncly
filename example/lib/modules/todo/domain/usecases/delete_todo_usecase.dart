import '../repositories/todo_repository.dart';

class DeleteTodoUsecase {
  final TodoRepository _repository;

  DeleteTodoUsecase(this._repository);

  Future<void> call(String id) async {
    await _repository.deleteTodo(id);
  }
}