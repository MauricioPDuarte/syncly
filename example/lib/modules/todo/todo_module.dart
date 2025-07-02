import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly_example/core/core_module.dart';
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
      List<Module> get imports =>  [
      CoreModule(),
    ];

  @override
  void binds(Injector i) {
    // Datasources
    i.addLazySingleton<TodoLocalDatasource>(TodoLocalDatasource.new);

    // Repositories
    i.addLazySingleton<TodoRepository>(TodoRepositoryImpl.new);


    // Use cases
    i.addLazySingleton<GetAllTodosUsecase>(GetAllTodosUsecase.new);
    i.addLazySingleton<CreateTodoUsecase>(CreateTodoUsecase.new);
    i.addLazySingleton<ToggleTodoUsecase>(ToggleTodoUsecase.new);
    i.addLazySingleton<DeleteTodoUsecase>(DeleteTodoUsecase.new);


    // Controllers
    i.addLazySingleton<TodoController>(TodoController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const TodoPage());
  }
}
