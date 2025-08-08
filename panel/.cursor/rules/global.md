TypeWriter Panel — Global Agent Rule

Scope: Always apply when working in this repository.

Project tech/context
- Flutter + Dart
- Riverpod (hooks + annotations) for state
- auto_route for navigation
- freezed + json_serializable for models
- Widgetbook workspace for component catalog (separate Flutter app under widgetbook/)

Primary commands
- Codegen (run whenever annotations or model schemas change):
  - dart run build_runner build -d
  - If issues persist: dart run build_runner clean && dart run build_runner build -d
- Analyze & lints:
  - dart analyze
- Run (web):
  - flutter run -d chrome
- Run (desktop):
  - macOS: flutter run -d macos
  - Windows/Linux: flutter run -d windows | flutter run -d linux
- Run (mobile):
  - iOS: flutter run -d ios
  - Android: flutter run -d android
- Run Widgetbook (component catalog, from the repo root):
  - flutter run -t widgetbook/lib/main.dart -d macos
- Tests:
  - flutter test

Project layout expectations
- lib/
  - routes/            → simulated file-based routing (index pages named route.dart)
  - logic/             → providers/state, backend calls, domain logic
  - widgets/
    - app/components/  → app chrome and app-level components
    - generic/components/ → reusable UI building blocks
    - generic/screens/ → generic loading/error, etc.
  - hooks/             → custom flutter hooks
  - utils/             → helpers, formatters, extensions
- widgetbook/
  - lib/stories/       → stories mirroring component structure
  - lib/logic/*.mock.dart → mocks for providers when needed

Global conventions
- Always use package: imports.
- Prefer immutable data; use freezed with copyWith for state.
- Keep widgets small and composable; extract reusable pieces.
- Use trailing commas for better diffs; prefer double quotes (as enforced by lints).
- Keep providers focused and testable; avoid unintended side effects in build().
- Keep navigation typed (auto_route). Co-locate pages under lib/routes/ by feature.
- Do not hard-code imports to files outside the expected folders.

When to run codegen
- After adding/updating:
  - @freezed models
  - @riverpod/@Riverpod providers
  - auto_route annotations
  - widgetbook @widgetbook.UseCase or @App changes
- Commands:
  - dart run build_runner build -d
  - If issues persist: dart run build_runner clean && dart run build_runner build -d

Minimal checklists
- New component: widget under widgets/... + story under widgetbook/lib/stories/... + regenerate widgetbook + run Widgetbook
- New route: page under routes/... + add to router config + codegen
- New model: freezed class + json helpers + part files + codegen
- New provider: annotated provider + tests (if applicable) + codegen

Agent behavior
- Preserve and follow the directory structure above; colocate by feature.
- Prefer pure UI widgets that accept data via parameters. If a widget depends on providers, consider a pure UI variant for testing and stories.
- Surface AsyncValue states (loading/error/data) explicitly in UI.
- Decode/encode JSON in the provider layer; avoid passing Map<String, dynamic> to widgets when avoidable.
- For auth-required routes, ensure router guards are applied in configuration.
- After route/provider/model changes, immediately run codegen and then analyze.
- Keep examples and scaffolds idiomatic to this project’s patterns.

