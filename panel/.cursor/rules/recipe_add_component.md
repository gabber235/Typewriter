Typewriter Panel: Recipe: Add a new UI component (with Widgetbook story)

Intent: Create a reusable or app-specific widget and its Widgetbook story, following this project’s structure and story patterns.

When to use: You need a new UI building block or app-level component and want it visible in Widgetbook immediately.

Folder placement
- Reusable: lib/widgets/generic/components/
- App-specific: lib/widgets/app/components/
- Story (mirror structure): widgetbook/lib/stories/generic/components/ or widgetbook/lib/stories/app/components/

Checklist
1) Implement the widget in the correct lib/widgets/... folder.
2) Keep it small, composable, and typed. Prefer pure-UI props; only read providers in a dedicated provider-aware variant when necessary.
3) Create a Widgetbook story under widgetbook/lib/stories/... using @widgetbook.UseCase that mirrors the component’s folder and name. Wrap stories with FakeApp; use its overrides for provider-aware cases.
4) Regenerate Widgetbook directories and any annotations in the widgetbook workspace with build_runner.
5) Launch Widgetbook and verify the story.
6) Run analysis.

Scaffold (pure UI widget: HookWidget)
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
import "package:typewriter_panel/utils/riverpod.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class MyWidgetWithProvider extends HookConsumerWidget {
  const MyWidgetWithProvider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return state(
      name: "state"
      builder: (value) => Text("$value"),
    );
  }
}
```

Story (pure UI, using FakeApp shell with knobs)
```dart
// widgetbook/lib/stories/generic/components/my_widget.stories.dart
import "package:flutter/material.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:typewriter_panel/widgets/generic/components/my_widget.dart";
import "package:your_widgetbook_package/widgetbook_utils.dart";

@widgetbook.UseCase(name: "Default", type: MyWidget)
Widget myWidgetDefaultUseCase(BuildContext context) {
  final title = context.knobs.string(label: "Title", initialValue: "Click me");
  return FakeApp(
    child: MyWidget(title: title, onPressed: () {}),
  );
}
```

Story (provider-aware, using FakeApp with overrides)
```dart
// widgetbook/lib/stories/app/components/my_widget_with_provider.stories.dart
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:typewriter_panel/widgets/app/components/my_widget_with_provider.dart";
import "package:your_widgetbook_package/widgetbook_utils.dart";
// For provider-aware stories, prefer using overrides from the testkit package:
// import "package:typewriter_testkit/typewriter_testkit.dart";

@widgetbook.UseCase(name: "Loaded", type: MyWidgetWithProvider)
Widget myWidgetWithProviderLoadedUseCase(BuildContext context) {
  return FakeApp(
    overrides: [
      // ...authProviderOverrides(),
    ],
    child: const MyWidgetWithProvider(),
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
- Prefer pure UI constructors; wrap stories with FakeApp and use its overrides when a provider-aware story is required.
- For provider-aware stories, import package:typewriter_testkit/typewriter_testkit.dart and reuse its override helpers (e.g., appearanceProviderOverrides(...), authProviderOverrides(...), booksProviderOverrides(...), manualsProviderOverrides(...), modulesProviderOverrides(...), organizationsProviderOverrides(...)).
- Keep stories focused: one behavior per @widgetbook.UseCase.

Multi-constructor widgets (composition rules)
- Prefer composition for multi-constructor widgets: expose an abstract public widget with factory constructors that delegate to private StatelessWidget subclasses (one per variant). Avoid runtime “kind” switches and large switch/case blocks in a single class.
- Keep shared layout/positioning in a small private base class or helpers. Each concrete subclass should only render its variant-specific UI and accept only the parameters it needs.
- Make factory names semantic and focused (e.g., .filled, .outlined, .icon; or .dot, .count, .custom). Keep constructor API surfaces small and strongly typed per variant.
- Do not use underscored named params in public factories. Wire values through to fields on the private subclasses via normal parameters and initializer lists.
- Keep cross-variant props consistent and documented (e.g., anchor, overlap, show, semanticsLabel). Provide theme-aware defaults (use Theme.of(context).colorScheme.*) rather than hard-coded colors.
- Prefer guard clauses inside variants to short-circuit behavior (e.g., hideWhenZero) instead of sprinkling checks across shared code.
- Stories: create a separate @UseCase per variant. For animating visibility or transitions, use HookBuilder + local state rather than a knob so Widgetbook doesn’t hard refresh and interrupt animations.
- Provider-aware variants: keep pure-UI variants separate; if needed, add a dedicated provider-aware widget and wrap stories with FakeApp overrides.

