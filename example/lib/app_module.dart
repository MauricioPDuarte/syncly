import 'package:flutter_modular/flutter_modular.dart';
import 'modules/todo/todo_module.dart';

class AppModule extends Module {
  @override
  List<Module> get imports => [TodoModule()];

  @override
  void routes(RouteManager r) {
    r.module('/', module: TodoModule());
  }
}
