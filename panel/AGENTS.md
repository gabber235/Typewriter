# AGENTS.md

Project tech/context
- Flutter + Dart
- Riverpod (hooks + annotations) for state
- auto_route for navigation
- freezed + json_serializable for models
- Widgetbook workspace for component catalog (separate Flutter app under widgetbook/)
  - Use FakeApp (widgetbook/lib/widgetbook_utils.dart) as the standard shell for stories. It wraps MaterialApp, ProviderScope (supports overrides), AppRequiredWidgets, Responsive breakpoints, and propagates app-wide shortcuts/actions.
  - Prefer wrapping each @widgetbook.UseCase content with FakeApp for consistent theming, scroll behavior, and padding.

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
  - Test utilities (test/test_utils.dart):
    - testApp(child: ...) to wrap widgets with ProviderScope, Responsive, AppRequiredWidgets, and MaterialApp.
    - WidgetTesterAppX.pumpTestApp(...) and pumpUntil(...) extensions for common setups.
    - WidgetTesterScreenshotsX.captureScreenshot(name, directory: "test_screenshots") to export PNG screenshots.
    - Call setupMocks() in test main() to register mocktail fallback values when needed.
    - Editor helpers (test/widgets/utils/editor_utils.dart): use WidgetTester.pumpEditor(...) to mount Inspector editors with blueprints and initial data.

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
- testkit/
  - lib/src/mocks/       → reusable provider mocks and overrides for tests and Widgetbook (import via package:typewriter_testkit)

Global conventions
- Always use package: imports.
- Prefer immutable data; use freezed with copyWith for state.
- Keep widgets small and composable; extract reusable pieces.
- Use trailing commas for better diffs; prefer double quotes (as enforced by lints).
- Keep providers focused and testable; avoid unintended side effects in build().
- Keep navigation typed (auto_route). Co-locate pages under lib/routes/ by feature.
- Do not hard-code imports to files outside the expected folders.
- Widgetbook stories should wrap content with FakeApp when possible to inherit app theming, shortcuts, scroll behavior, and Responsive padding.
- In widget tests, prefer testApp/pumpTestApp and captureScreenshot utilities over bespoke scaffolds.

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

