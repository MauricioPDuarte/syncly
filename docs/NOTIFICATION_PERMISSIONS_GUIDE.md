# Guia de Permissões de Notificação - Syncly

Este guia explica como configurar as permissões de notificação para que o Syncly funcione corretamente em Android e iOS.

## 📱 Android

### Android 13+ (API 33+)

Para Android 13 e versões superiores, é necessário adicionar a permissão `POST_NOTIFICATIONS` no arquivo `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissão para notificações (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <!-- Outras permissões... -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <application
        android:label="Seu App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Configurações do app... -->
    </application>
</manifest>
```

### Android 12 e anteriores

Para versões anteriores ao Android 13, as notificações são habilitadas por padrão, mas você pode adicionar permissões adicionais se necessário:

```xml
<!-- Opcional: Para notificações com vibração -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Opcional: Para notificações que acordam o dispositivo -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## 🍎 iOS

### Configuração no Info.plist

No iOS, as permissões de notificação são solicitadas automaticamente quando a primeira notificação é enviada. No entanto, você pode configurar o comportamento no arquivo `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Outras configurações... -->
    
    <!-- Configurações de notificação (opcional) -->
    <key>UIBackgroundModes</key>
    <array>
        <string>background-processing</string>
        <string>background-fetch</string>
    </array>
</dict>
```

### Capabilities no Xcode

1. Abra o projeto iOS no Xcode
2. Selecione o target do seu app
3. Vá para a aba "Signing & Capabilities"
4. Adicione "Background Modes" se necessário
5. Marque "Background processing" e "Background fetch"

## 🔧 Implementação no Código

### Verificação Automática

O Syncly verifica e solicita automaticamente as permissões durante a inicialização quando `enableNotifications` está habilitado:

```dart
import 'package:syncly/sync_initializer.dart';

// As permissões são verificadas e solicitadas automaticamente
// se enableNotifications for true
await SyncInitializer.initialize(meuSyncConfig);
```

### Verificação Manual

Você pode verificar o status das permissões manualmente a qualquer momento:

```dart
// Verificar se as permissões estão concedidas
bool hasPermission = await SyncInitializer.checkNotificationPermission();

if (!hasPermission) {
  // Solicitar permissão manualmente
  bool granted = await SyncInitializer.requestNotificationPermission();
  
  if (granted) {
    print('Permissão de notificação concedida');
  } else {
    print('Usuário negou a permissão de notificação');
  }
}
```

### Estados de Permissão

O Syncly utiliza o `permission_handler` para gerenciar diferentes estados de permissão:

```dart
// Exemplo de tratamento completo de permissões
Future<void> handleNotificationPermissions() async {
  bool hasPermission = await SyncInitializer.checkNotificationPermission();
  
  if (!hasPermission) {
    bool granted = await SyncInitializer.requestNotificationPermission();
    
    if (!granted) {
      // Permissão negada - verificar se foi negada permanentemente
      // O Syncly já loga automaticamente esses casos
      showPermissionDeniedDialog();
    }
  }
}

void showPermissionDeniedDialog() {
  // Mostrar dialog explicando como habilitar manualmente
  // nas configurações do dispositivo
}
```

### Tratamento de Permissões Negadas

```dart
class MeuSyncConfig extends SyncConfig {
  @override
  bool get enableNotifications => true;
  
  // Método para lidar com permissões negadas
  Future<void> handleNotificationPermissionDenied() async {
    // Mostrar dialog explicando a importância das notificações
    // Redirecionar para configurações do sistema se necessário
  }
}
```

## 🔍 Debugging

### Logs de Permissão

O Syncly registra automaticamente informações detalhadas sobre permissões nos logs:

```dart
// Os logs são habilitados automaticamente e incluem:
// - Status atual da permissão
// - Resultado da solicitação
// - Avisos sobre permissões negadas permanentemente
// - Erros durante o processo
```

Exemplos de logs que você verá:

```
[SyncInitializer] Verificando permissões de notificação...
[SyncInitializer] Status atual da permissão de notificação: PermissionStatus.denied
[SyncInitializer] Solicitando permissão de notificação...
[SyncInitializer] Resultado da solicitação de permissão: PermissionStatus.granted
[SyncInitializer] Permissão de notificação concedida com sucesso
```

Procure por logs com a categoria `SyncInitializer` para informações sobre permissões.

### Testando Permissões

1. **Android**: Use `adb shell dumpsys notification` para verificar o status das notificações
2. **iOS**: Verifique as configurações do app em Configurações > Notificações

## 📚 Dependências Incluídas

O Syncly já inclui as dependências necessárias para gerenciamento de permissões:

```yaml
dependencies:
  # Já incluído no Syncly
  permission_handler: ^11.3.1
```

### Dependências Opcionais

Para funcionalidades avançadas de notificação, você pode adicionar:

```yaml
dependencies:
  # Para notificações locais personalizadas
  flutter_local_notifications: ^17.2.3
```

## ⚠️ Notas Importantes

1. **Android 13+**: A permissão `POST_NOTIFICATIONS` é obrigatória
2. **iOS**: As permissões são solicitadas na primeira notificação
3. **Background Sync**: Certifique-se de que as permissões de background estão configuradas
4. **Testes**: Sempre teste em dispositivos reais, especialmente para Android 13+

## 🆘 Solução de Problemas

### Notificações não aparecem no Android

1. Verifique se a permissão `POST_NOTIFICATIONS` está no AndroidManifest.xml
2. Confirme que o usuário concedeu a permissão nas configurações do app
3. Verifique se as notificações não estão bloqueadas para o app

### Notificações não aparecem no iOS

1. Verifique se o usuário concedeu permissão quando solicitado
2. Confirme que as notificações estão habilitadas nas configurações do app
3. Verifique se o modo "Não Perturbe" não está ativo

### Background Sync não funciona

**Nota**: A sincronização em background vem **ativada por padrão** no Syncly.

1. Verifique as permissões de background
2. Confirme que a otimização de bateria não está bloqueando o app
3. Verifique se `enableBackgroundSync` não foi desabilitado manualmente
4. Teste em dispositivos diferentes (alguns fabricantes têm restrições específicas)

## 📞 Suporte

Se você encontrar problemas com permissões de notificação:

1. Verifique os logs de debug do Syncly
2. Consulte a documentação oficial do Flutter para notificações
3. Abra uma issue no [repositório do Syncly](https://github.com/MauricioPDuarte/syncly/issues)