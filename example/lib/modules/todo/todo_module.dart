import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly/sync.dart';
import '../../core/services/storage/storage.dart';
import 'data/datasources/todo_local_datasource.dart';
import 'data/repositories/todo_repository_impl.dart';
import 'presentation/pages/todo_page.dart';
import 'domain/repositories/todo_repository.dart';
import 'domain/usecases/get_all_todos_usecase.dart';
import 'domain/usecases/create_todo_usecase.dart';
import 'domain/usecases/toggle_todo_usecase.dart';
import 'domain/usecases/delete_todo_usecase.dart';
import 'presentation/controllers/todo_controller.dart';

class TodoModule extends Module {
  @override
  void binds(Injector i) {
    // Datasources
    i.addLazySingleton<TodoLocalDatasource>(
      () => TodoLocalDatasource(
        i.get<StorageService>(),
        i.get<ISyncService>(),
      ),
    );

    // Repositories
    i.addLazySingleton<TodoRepository>(
      () => TodoRepositoryImpl(
        i.get<TodoLocalDatasource>()
      ),
    );

    // Use cases
    i.addLazySingleton<GetAllTodosUsecase>(
      () => GetAllTodosUsecase(i.get<TodoRepository>()),
    );

    i.addLazySingleton<CreateTodoUsecase>(
      () => CreateTodoUsecase(i.get<TodoRepository>()),
    );

    i.addLazySingleton<ToggleTodoUsecase>(
      () => ToggleTodoUsecase(i.get<TodoRepository>()),
    );

    i.addLazySingleton<DeleteTodoUsecase>(
      () => DeleteTodoUsecase(i.get<TodoRepository>()),
    );

    // Controllers
    i.addLazySingleton<TodoController>(
      () => TodoController(
        i.get<GetAllTodosUsecase>(),
        i.get<CreateTodoUsecase>(),
        i.get<ToggleTodoUsecase>(),
        i.get<DeleteTodoUsecase>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const TodoPage());
  }
}
