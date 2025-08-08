# AGENTS.md


Tech overview (for context only)
- Flutter + Dart
- Riverpod (hooks + annotations) for state
- auto_route for navigation
- freezed + json_serializable for models
- Widgetbook for component catalog


Build / Run / Test
- Codegen (run whenever annotations or model schemas change):
  - dart run build_runner build -d

- Analyze & lints:
  - dart analyze

- Run (web):
  - flutter run -d chrome

- Run (desktop):
  - macOS: flutter run -d macos
  - Windows/Linux as configured: flutter run -d windows | flutter run -d linux

- Run (mobile):
  - iOS: flutter run -d ios
  - Android: flutter run -d android

- Run Widgetbook (component catalog):
  - flutter run -t widgetbook/lib/main.dart -d macos
  - Or choose another device with -d <device>

- Tests:
  - flutter test


Project layout (high-level expectations)
- lib/
  - routes/            → simulated file based routing (index pages are namde `route.dart`)
  - logic/             → providers/state, backend calls, domain logic
  - widgets/
    - app/components/  → app chrome and larger app-level components
    - generic/components/ → reusable UI building blocks
    - generic/screens/ → generic screens like loading/error
  - hooks/             → custom flutter hooks
  - utils/             → helpers formatters, extension methods
- widgetbook/
  - lib/stories/       → stories mirroring component structure
  - lib/logic/*.mock.dart → mocks for providers when needed

Keep new code consistent with this structure. Do not hard-code imports to specific files outside these folders.


Recipes

1) Add a new UI component
- Place the widget in widgets/generic/components/ (reusable between this project and possibly others) or widgets/app/components/ (app-specific to typewriter).
- Prefer composable, stateless widgets; use hooks_riverpod if local provider reads are needed.
- Keep public APIs (constructors/params) small and typed.
- If it depends on providers, consider exposing a pure UI version that accepts data via parameters for easier testing and stories.

2) Add a Widgetbook story for a component
- Create a story under widgetbook/lib/stories/... mirroring the component’s folder structure.
- Provide simple knobs/controls via Widgetbook where useful.
- If the component reads providers, either:
  - Wrap with minimal ProviderScope and supply overrides/mocks, or
  - Prefer a pure UI constructor variant that accepts data directly.
- Launch Widgetbook with the command above to iterate.

3) Add a route (page)
- Create a page widget under routes/ based on the path.
- Annotate the page class with @RoutePage() (auto_route convention) to enable typed routing.
- Register the route in the central router configuration (auto_route list) as a child of the appropriate parent route.
- If route requires authentication, ensure it’s guarded by the auth guard in the router configuration.
- Rebuild codegen after modifying routes:
  - dart run build_runner build -d

4) Add or change a provider (Riverpod)
- Place provider code under logic/ grouped by feature or domain.
- Use @riverpod (function/class-based) or @Riverpod(keepAlive: true) as needed.
- If a provider consumes other providers, wire via Ref and specify dependencies when appropriate (custom_lint rules may enforce this).
- For async providers, surface AsyncValue in the UI and handle loading/error states explicitly.
- Run codegen after adding/updating annotated providers.

5) Add or change a model (freezed + json_serializable)
- Define an immutable data class using @freezed and factory constructors.
- Include JSON helpers with json_serializable annotations (e.g., factory fromJson(Map<String,dynamic>)).
- Add part files for generated outputs (e.g., part 'model.freezed.dart'; part 'model.g.dart';).
- Keep fields explicitly typed; prefer non-dynamic JSON APIs.
- Run codegen after changes.

6) Call a backend operation (pattern)
- Access backend clients through providers under logic/.
- For request/response flows, expose a method on a provider that performs the call and returns strongly typed data.
- Decode/encode JSON at the provider layer; do not leak Map<String, dynamic> into widgets when avoidable.
- Propagate errors upward; let UI render generic loading/error widgets.


Conventions
- Always use package: imports.
- Prefer immutable data and copy-with patterns (freezed) for state.
- Keep widgets small; extract components for reuse.
- Use trailing commas for better diffs; prefer double quotes (as enforced by lints).
- Keep providers focused and testable; avoid side effects in build() beyond reading other providers and constructing values.
- Keep navigation typed (auto_route) and colocate pages with their feature folders in routes/.


When to run codegen
- After: adding/updating @freezed models, @riverpod/@Riverpod providers, auto_route annotations, creating new widgetbook stories.
- Commands:
  - dart run build_runner build -d
  - For persistent issues: dart run build_runner clean && dart run build_runner build -d


Minimal checklists
- New component: file under widgets/... + (optional) story under widgetbook/lib/stories/... + run Widgetbook
- New route: page under routes/... + add to router config + codegen
- New model: freezed class + json helpers + part files + codegen
- New provider: annotated provider + tests (if applicable) + codegen


Testing guidance (brief)
- Prefer testing logic/providers with unit tests.
- For widgets, use golden tests for stable components and verify basic interactions.
- Keep tests deterministic; mock providers where needed.
