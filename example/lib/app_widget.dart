import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly/sync.dart';
import 'core/services/sync/syncly/config/syncly_config.dart';
import 'modules/todo/data/sync/todo_downloader.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    // Aguardar um frame para garantir que o Modular esteja inicializado
    await Future.delayed(Duration.zero);
    
    try {
      // Obter o TodoDownloader do container
      final todoDownloader = Modular.get<TodoDownloader>();
      
      // Inicializar o SyncInitializer
      final syncConfig = SynclyConfig();
      await SyncInitializer.initialize(
        syncConfig,
        downloadStrategies: [todoDownloader],
      );
    } catch (e) {
      debugPrint('Erro ao inicializar Sync: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Syncly Todo Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: Modular.routerConfig,
    );
  }
}
