TypeWriter Panel — Recipe: Add a new UI component (with Widgetbook story)

Intent: Create a reusable or app-specific widget and its Widgetbook story, following this project’s structure and story patterns.

When to use: You need a new UI building block or app-level component and want it visible in Widgetbook immediately.

Folder placement
- Reusable: lib/widgets/generic/components/
- App-specific: lib/widgets/app/components/
- Story (mirror structure): widgetbook/lib/stories/generic/components/ or widgetbook/lib/stories/app/components/

Checklist
1) Implement the widget in the correct lib/widgets/... folder.
2) Keep it small, composable, and typed. Prefer pure-UI props; only read providers in a dedicated provider-aware variant when necessary.
3) Create a Widgetbook story under widgetbook/lib/stories/... using @widgetbook.UseCase that mirrors the component’s folder and name.
4) Regenerate Widgetbook directories and any annotations in the widgetbook workspace with build_runner.
5) Launch Widgetbook and verify the story.
6) Run analysis.

Scaffold (pure UI widget — HookWidget)
```dart
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

class MyWidget extends HookWidget {
  const MyWidget({super.key, required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
```

Scaffold (provider-aware variant kept separate)
```dart
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class MyWidgetWithProvider extends HookConsumerWidget {
  const MyWidgetWithProvider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return state.when(
      data: (value) => Text("$value"),
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text("Error: $e"),
    );
  }
}
```

Story (pure UI, mirrors existing pattern with knobs and AppRequiredWidgets)
```dart
// widgetbook/lib/stories/generic/components/my_widget.stories.dart
import "package:flutter/material.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:typewriter_panel/widgets/generic/components/my_widget.dart";
import "package:typewriter_panel/widgets/generic/components/app_required.dart";

@widgetbook.UseCase(name: "Default", type: MyWidget)
Widget myWidgetDefaultUseCase(BuildContext context) {
  final title = context.knobs.string(label: "Title", initialValue: "Click me");
  return AppRequiredWidgets(
    child: MyWidget(title: title, onPressed: () {}),
  );
}
```

Story (provider-aware, using ProviderScope overrides when needed)
```dart
// widgetbook/lib/stories/app/components/my_widget_with_provider.stories.dart
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:typewriter_panel/widgets/app/components/my_widget_with_provider.dart";
import "package:typewriter_panel/widgets/generic/components/app_required.dart";
// import your provider and provide minimal overrides if required
// import "package:typewriter_panel/logic/feature/my_provider.dart";

@widgetbook.UseCase(name: "Loaded", type: MyWidgetWithProvider)
Widget myWidgetWithProviderLoadedUseCase(BuildContext context) {
  return ProviderScope(
    // overrides: [myProvider.overrideWith((_) async => "Hello from mock")],
    child: const AppRequiredWidgets(child: MyWidgetWithProvider()),
  );
}
```

Build & run (Widgetbook workspace)
- From widgetbook/ directory:
  - flutter pub get
  - dart run build_runner build -d
  - If glitches: dart run build_runner clean && dart run build_runner build -d
- Launch Widgetbook (macOS):
  - flutter run -t widgetbook/lib/main.dart -d macos

Analyze
- dart analyze

Notes
- Mirror lib/widgets/... inside widgetbook/lib/stories/ so the generator groups items correctly.
- Prefer pure UI constructors; use ProviderScope + overrides when a provider-aware story is required.
- Keep stories focused: one behavior per @widgetbook.UseCase.

