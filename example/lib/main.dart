import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly/sync.dart';
import 'app_module.dart';
import 'app_widget.dart';
import 'core/services/sync/syncly/config/syncly_config.dart';
import 'modules/todo/data/sync/todo_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar o sistema de sincronização
    await SyncInitializer.initialize(
      SynclyConfig(),
      strategyResolver: () => [Modular.get<TodoDownloader>()],
    );
    
    debugPrint('-- SyncInitializer INITIALIZED');
  } catch (e) {
    debugPrint('Erro ao inicializar SyncInitializer: $e');
  }

  runApp(ModularApp(
    module: AppModule(),
    child: const AppWidget(),
  ));
}
