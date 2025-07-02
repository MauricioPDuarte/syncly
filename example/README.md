# Syncly Todo Example

Este é um exemplo completo de como usar a biblioteca Syncly em um projeto Flutter com arquitetura modular e Clean Architecture.

## Características

- ✅ **Arquitetura Modular**: Usando flutter_modular para injeção de dependência e navegação
- ✅ **Clean Architecture**: Separação clara entre domínio, dados e apresentação
- ✅ **Offline First**: Funciona completamente offline usando SharedPreferences
- ✅ **Sincronização**: Integração com Syncly para sincronização automática
- ✅ **ValueNotifier**: Gerenciamento de estado reativo
- ✅ **Material Design 3**: Interface moderna e responsiva

## Estrutura do Projeto

```
lib/
├── core/                          # Módulo principal com serviços compartilhados
│   ├── core_module.dart          # Configuração de dependências globais
│   └── services/
│       ├── shared_preferences_service.dart  # Serviço de persistência local
│       └── sync_service.dart     # Integração com Syncly
├── modules/
│   └── todo/                     # Módulo de todos
│       ├── data/                 # Camada de dados
│       │   ├── datasources/
│       │   └── repositories/
│       ├── domain/               # Camada de domínio
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       ├── presentation/         # Camada de apresentação
│       │   ├── controllers/
│       │   ├── pages/
│       │   └── widgets/
│       └── todo_module.dart      # Configuração do módulo
├── app_module.dart               # Módulo principal da aplicação
├── app_widget.dart               # Widget principal
└── main.dart                     # Ponto de entrada
```

## Como Executar

1. **Instalar dependências**:
   ```bash
   flutter pub get
   ```

2. **Executar a aplicação**:
   ```bash
   flutter run
   ```

## Funcionalidades

### Todo App
- Criar novos todos
- Marcar como concluído/pendente
- Excluir todos
- Visualizar estatísticas
- Sincronização automática (quando configurada)

### Integração com Syncly

O exemplo demonstra como:

1. **Configurar o Syncly**:
   ```dart
   final config = SyncConfig(
     baseUrl: 'https://api.example.com',
     enableLogging: true,
     syncIntervalMinutes: 5,
     maxRetryAttempts: 3,
   );
   ```

2. **Implementar Storage Provider**:
   ```dart
   class _SharedPreferencesStorageProvider implements IStorageProvider {
     // Implementação usando SharedPreferences
   }
   ```

3. **Registrar modelos para sincronização**:
   ```dart
   _syncConfig.registerModel<Todo>(
     'todos',
     fromJson: Todo.fromJson,
     toJson: (todo) => todo.toJson(),
   );
   ```

4. **Adicionar itens para sincronização**:
   ```dart
   await _syncConfig.addToSync(todo);
   ```

## Configuração da API

Para habilitar a sincronização com um servidor, você precisa:

1. **Configurar a URL da API** em `core/services/sync_service.dart`:
   ```dart
   final config = SyncConfig(
     baseUrl: 'https://sua-api.com', // Substitua pela sua URL
     // ...
   );
   ```

2. **Implementar os endpoints da API** que o Syncly espera:
   - `GET /todos` - Listar todos
   - `POST /todos` - Criar todo
   - `PUT /todos/{id}` - Atualizar todo
   - `DELETE /todos/{id}` - Excluir todo

## Arquitetura

### Clean Architecture

O projeto segue os princípios da Clean Architecture:

- **Domain**: Entidades, casos de uso e contratos (interfaces)
- **Data**: Implementações de repositórios e fontes de dados
- **Presentation**: Controllers, páginas e widgets

### Injeção de Dependência

Usamos flutter_modular para:
- Gerenciar dependências
- Navegação entre telas
- Modularização da aplicação

### Gerenciamento de Estado

Usamos ValueNotifier para:
- Estado reativo simples
- Baixa complexidade
- Performance otimizada

## Personalização

Você pode usar este exemplo como base para:

1. **Adicionar novos módulos**: Crie novos módulos seguindo a mesma estrutura
2. **Implementar autenticação**: Adicione um módulo de auth
3. **Adicionar mais campos**: Estenda a entidade Todo
4. **Customizar UI**: Modifique os widgets e temas
5. **Integrar com APIs reais**: Configure endpoints reais

## Dependências Principais

- `flutter_modular`: Injeção de dependência e navegação
- `shared_preferences`: Persistência local
- `syncly`: Biblioteca de sincronização (local)
- `uuid`: Geração de IDs únicos

## Próximos Passos

- [ ] Adicionar testes unitários
- [ ] Implementar autenticação
- [ ] Adicionar filtros e busca
- [ ] Implementar categorias
- [ ] Adicionar notificações
- [ ] Melhorar tratamento de erros