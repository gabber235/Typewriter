TypeWriter Panel — Recipe: Providers (Riverpod)

Intent: Define and evolve providers for state and logic using Riverpod code generation, aligned with this project.

Folder placement
- lib/logic/<feature>/

Key guidance: @Riverpod vs @riverpod and class vs function
- @Riverpod (PascalCase) vs @riverpod (camelCase):
  - Use keepAlive: true only when state must persist even with zero listeners. This is rare.
  - Example: @Riverpod(keepAlive: true) for long-lived caches/background state needed before any UI mounts.
- Class vs function:
  - Prefer class providers for anything that fetches/owns state or exposes actions (refresh, add/remove, retry, etc.). Fetching almost always implies actions.
  - Use function providers only for pure derivations/transformations without actions. These recompute from inputs and do not mutate state.

Decision checklist
- Pure derived value, no actions → function provider
- Owns state and needs actions (incl. async) → class provider
- Must persist without listeners → consider keepAlive: true (sparingly)

Self-contained async example: Todo list with actions (no external APIs)
```dart
// lib/logic/todos/todos.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'todos.g.dart';

class Todo {
  const Todo({required this.id, required this.text, this.done = false});
  final String id;
  final String text;
  final bool done;
  Todo copyWith({String? id, String? text, bool? done}) =>
      Todo(id: id ?? this.id, text: text ?? this.text, done: done ?? this.done);
}

@Riverpod()
class Todos extends _$Todos {
  @override
  Future<List<Todo>> build() async {
    // Simulate initial async load. Avoid side-effects beyond data fetch here.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [
      Todo(id: '1', text: 'Explore Widgetbook'),
      Todo(id: '2', text: 'Write a new component story'),
    ];
  }

  // Actions (imperative methods) that update state safely
  void add(String text) {
    state = state.whenData((list) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      return [...list, Todo(id: id, text: text)];
    });
  }

  void remove(String id) {
    state = state.whenData((list) => list.where((t) => t.id != id).toList());
  }

  void toggle(String id) {
    state = state.whenData((list) => [
          for (final t in list) t.id == id ? t.copyWith(done: !t.done) : t,
        ]);
  }
}
```

Derived function providers (pure transforms, no actions)
```dart
// Count derived from Todos (pure)
@riverpod
int todosCount(TodosCountRef ref) {
  final todos = ref.watch(todosProvider);
  return todos.maybeWhen(data: (list) => list.length, orElse: () => 0);
}

// Completed filter (pure)
@riverpod
List<Todo> completedTodos(CompletedTodosRef ref) {
  final todos = ref.watch(todosProvider);
  return todos.maybeWhen(
    data: (list) => list.where((t) => t.done).toList(),
    orElse: () => const [],
  );
}
```

UI usage patterns
```dart
import "package:typewriter_panel/utils/riverpod.dart";

// Async class provider with actions
final todos = ref.watch(todosProvider);
return todos(
  name: "todos",
  builder: (items) => ListView(
    children: [
      for (final t in items)
        ListTile(
          title: Text(t.text),
          leading: Checkbox(
            value: t.done,
            onChanged: (_) => ref.read(todosProvider.notifier).toggle(t.id),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => ref.read(todosProvider.notifier).remove(t.id),
          ),
        ),
    ],
  ),
);

// Trigger actions
ref.read(todosProvider.notifier).add('New item');
await ref.read(todosProvider.notifier).refresh();
// Or force a rebuild on next read from outside the widget:
// ref.invalidate(todosProvider);

// Function providers (derived)
final count = ref.watch(todosCountProvider);
final completed = ref.watch(completedTodosProvider);
```

Commands
- dart run build_runner build -d
- dart analyze
- flutter test (provider and widget tests; prefer testApp/pumpTestApp and captureScreenshot from panel/test/test_utils.dart where applicable)

Notes
- Keep providers small and composable; avoid side effects in build() beyond reading other providers and constructing values.
- For side-effects (logging, navigation, toasts), use ref.listen in the UI layer instead of side-effects in build().
- Prefer passing typed models to widgets; avoid Map< String, dynamic > in UI.
- Use keepAlive: true sparingly for state that must persist without listeners.
- Testing utilities:
  - Wrap test widgets with testApp(...) or use WidgetTesterAppX.pumpTestApp(...) to get ProviderScope, Responsive, and a Material scaffold (see panel/test/test_utils.dart).
  - Override providers in tests via ProviderScope(overrides: [...]) to inject fakes/mocks. Prefer using overrides from the testkit package (`package:typewriter_testkit/typewriter_testkit.dart`) for common app providers (e.g., appearanceProviderOverrides(...), authProviderOverrides(...), booksProviderOverrides(...), manualsProviderOverrides(...), modulesProviderOverrides(...), organizationsProviderOverrides(...)).
  - Call setupMocks() in your test main() or setUpAll to register mocktail fallback values used by the testkit.
  - Capture screenshots in widget tests with WidgetTesterScreenshotsX.captureScreenshot("name") for visual verification.

