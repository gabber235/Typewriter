# AGENTS.md

Project tech/context
- Flutter + Dart
- Riverpod (hooks + annotations) for state
- auto_route for navigation
- protobuf for domain models; freezed for UI state
- Taskfile.yml for code generation (proto + build_runner)
- Widgetbook workspace for component catalog (separate Flutter app under widgetbook/)
  - Use FakeApp (widgetbook/lib/widgetbook_utils.dart) as the standard shell for stories. It wraps MaterialApp, ProviderScope (supports overrides), AppRequiredWidgets, Responsive breakpoints, and propagates app-wide shortcuts/actions.
  - Prefer wrapping each @widgetbook.UseCase content with FakeApp for consistent theming, scroll behavior, and padding.

Primary commands
- Proto generation (run after adding/updating .proto files):
  - task proto
- Dart codegen (run after annotations change):
  - task generate
  - If issues persist: dart run build_runner clean && dart run build_runner build -d
- Analyze & lints:
  - dart analyze
- Tests:
  - flutter test
  - Test utilities (test/test_utils.dart):
    - testApp(child: ...) to wrap widgets with ProviderScope, Responsive, AppRequiredWidgets, and MaterialApp.
    - WidgetTesterAppX.pumpTestApp(...) and pumpUntil(...) extensions for common setups.
    - WidgetTesterScreenshotsX.captureScreenshot(name, directory: "test_screenshots") to export PNG screenshots.
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

When to run proto generation
- After adding/updating .proto files in ../proto/
- Command: task proto

When to run dart codegen
- After adding/updating:
  - @riverpod/@Riverpod providers
  - auto_route annotations
  - widgetbook @widgetbook.UseCase or @App changes
- Command: task generate

Minimal checklists
- New component: widget under widgets/... + story under widgetbook/lib/stories/... + regenerate widgetbook + run Widgetbook
- New route: page under routes/... + add to router config + task generate
- New domain model: add .proto file in ../proto/models/ + task proto (or use existing proto message)
- New UI state class: freezed class (if needed for local component state) + task generate
- New provider: annotated provider + tests (if applicable) + task generate

Agent behavior
- Preserve and follow the directory structure above; colocate by feature.
- Prefer pure UI widgets that accept data via parameters. If a widget depends on providers, consider a pure UI variant for testing and stories.
- Surface AsyncValue states (loading/error/data) explicitly in UI.
- Use proto messages for domain models; decode from wire formats in the provider layer.
- Add extension methods on proto messages (lib/logic/proto/extensions.dart or colocated) for domain logic, conversions, and computed properties.
- For auth-required routes, ensure router guards are applied in configuration.
- After route/provider/model changes, immediately run task generate and then analyze.
- Keep examples and scaffolds idiomatic to this project's patterns.
- ALWAYS use dot notation for duration. So not `Duration(seconds: 2)` but `2.seconds`. Or `Duration(milliseconds: 200)` but `200.ms`
