import 'package:flutter_modular/flutter_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage/storage.dart';
import 'services/rest_client/rest_client.dart';
import 'services/rest_client/dio/dio_rest_client.dart';
import 'services/sync/sync.dart';
import 'services/sync/syncly/syncly_service.dart';

class CoreModule extends Module {
  @override
  void exportedBinds(Injector i) {
    // Storage service (usando implementação mock para simplificar)
    i.addSingleton<StorageService>(
      () => SharedPreferencesService(null), // Implementação simplificada
    );
    
    // Rest client
    i.addSingleton<RestClient>(
      () => DioRestClient(),
    );
    
    // App sync service
    i.addSingleton<AppSyncService>(
      () => SynclyService(),
    );
  }
}