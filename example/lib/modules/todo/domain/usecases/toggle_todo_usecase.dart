import '../repositories/todo_repository.dart';

class ToggleTodoUsecase {
  final TodoRepository _repository;

  ToggleTodoUsecase(this._repository);

  Future<void> call(String id, bool isCompleted) async {
    if (isCompleted) {
      await _repository.markAsCompleted(id);
    } else {
      await _repository.markAsIncomplete(id);
    }
  }
}