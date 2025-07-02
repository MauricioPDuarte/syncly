import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'app_module.dart';
import 'app_widget.dart';
import 'core/services/sync/syncly/config/syncly_config.dart';
import 'package:syncly/sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o SyncInitializer com o SynclyConfig
  final syncConfig = SynclyConfig();
  await SyncInitializer.initialize(syncConfig);
  
  runApp(ModularApp(
    module: AppModule(),
    child: const AppWidget(),
  ));
}