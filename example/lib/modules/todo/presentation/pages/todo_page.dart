import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:syncly/sync.dart';
import '../controllers/todo_controller.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_todo_dialog.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late final TodoController controller;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<TodoController>();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncly Todo Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Indicador de sincronização
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SyncIndicator(
              showText: false,
              onTap: () => SyncDetailsBottomSheet.show(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTodos,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder(
              valueListenable: controller.todos,
              builder: (context, todos, child) {
                final completed = todos.where((t) => t.isCompleted).length;
                final total = todos.length;
                
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Todo Statistics',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        // Indicador de sincronização com texto
                        SyncIndicator(
                          showText: true,
                          onTap: () => SyncDetailsBottomSheet.show(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem('Total', total.toString()),
                        _StatItem('Completed', completed.toString()),
                        _StatItem('Pending', (total - completed).toString()),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Error Display
          ValueListenableBuilder(
            valueListenable: controller.error,
            builder: (context, error, child) {
              if (error == null) return const SizedBox.shrink();
              
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => controller.error.value = null,
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Todo List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: controller.isLoading,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                return ValueListenableBuilder(
                  valueListenable: controller.todos,
                  builder: (context, todos, child) {
                    if (todos.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checklist,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No todos yet!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first todo',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return TodoItemWidget(
                          todo: todo,
                          onToggle: (isCompleted) => controller.toggleTodo(
                            todo.id,
                            isCompleted,
                          ),
                          onDelete: () => controller.deleteTodo(todo.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        onAdd: (title, description) {
          controller.createTodo(title, description);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}