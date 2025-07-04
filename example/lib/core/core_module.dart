import 'package:flutter_modular/flutter_modular.dart';
import 'services/storage/storage.dart';
import 'services/rest_client/rest_client.dart';
import 'services/rest_client/dio/dio_rest_client.dart';
import 'services/sync/sync.dart';
class CoreModule extends Module {
  @override
  void exportedBinds(Injector i) {
    // Storage service (usando implementação mock para simplificar)
    i.addSingleton<StorageService>(SharedPreferencesService.new);
    
    // Rest client
    i.addSingleton<RestClient>(DioRestClient.new);
    
    // App sync service (lazy para evitar inicialização prematura)
    i.addLazySingleton<AppSyncService>(SynclyService.new);

  }
}