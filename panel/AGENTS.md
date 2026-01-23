# Panel: Flutter Web/Desktop Configuration UI

## OVERVIEW

Flutter app for configuring Typewriter quests, dialogues, and entries. Connects to Backend via NATS/Protobuf.

## STRUCTURE

```
panel/
├── lib/
│   ├── logic/          # State management (Riverpod providers)
│   ├── models/         # Generated protobuf + freezed models
│   ├── routes/         # auto_route page definitions
│   ├── utils/          # Helpers, extensions
│   └── widgets/
│       ├── app/        # Typewriter-specific components
│       └── generic/    # Reusable UI components
├── test/               # Widget tests
├── testkit/            # Shared test utilities package
└── widgetbook/         # Component gallery
```

## COMMANDS

```bash
task proto                    # Generate Dart from proto (MUST run after proto changes)
task generate                 # Run build_runner (freezed, riverpod_generator)
task panel:run:web:local      # Dev server
flutter test                  # Run tests
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add new page | `lib/routes/` + register in `app_router.dart` |
| Add state provider | `lib/logic/` |
| Add reusable widget | `lib/widgets/generic/` |
| Add app-specific widget | `lib/widgets/app/` |
| Add inspector editor | `lib/widgets/app/components/inspector/editors/` |
| Test utilities | `testkit/` package |
| Component preview | `widgetbook/` |

## CONVENTIONS

### Code Style (CRITICAL)
- **Double quotes ONLY**: `"string"` not `'string'`
- **Trailing commas** on multiline args
- **Package imports ONLY**: `import "package:typewriter_panel/..."` never relative
- Files under 300 lines
- Run `dart run build_runner build -d` after editing files with codegen

### State Management
- Riverpod 3.0 with `hooks_riverpod`
- Use `@riverpod` annotation for providers
- Use `HookConsumerWidget` for widgets needing both hooks and providers

### Testing
- Use `testApp(...)` and `WidgetTester.pumpTestApp(...)` from `test/test_utils.dart`
- Use provider mocks from `typewriter_testkit` package
- Screenshots go in `test_screenshots/`

### Widgetbook
- Wrap stories with `FakeApp` from `widgetbook/lib/widgetbook_utils.dart`
- Pass provider overrides via `FakeApp(overrides: [...])`
- Don't create manual `MaterialApp`/`ProviderScope` stacks

## ANTI-PATTERNS

| Pattern | Alternative |
|---------|-------------|
| Single quotes `'string'` | Double quotes `"string"` |
| Relative imports | Package imports |
| `labelText` on TextField | Use `hintText` only |
| Manual test scaffolds | Use `testApp()`/`pumpTestApp()` |
| Hand-rolled `ProviderScope` in widgetbook | Use `FakeApp` wrapper |

## DEPENDENCIES

Key packages:
- `hooks_riverpod` 3.0: State management
- `auto_route` 11: Routing
- `dart_nats`: NATS messaging
- `freezed`: Immutable models
- `protobuf` 6.0: Protocol buffers

## NOTES

- Auth flow: Sentinel → OIDC → JWT → NATS connection
- Entry blueprints come from engine extensions (KSP-generated JSON)
- Inspector editors dynamically render based on blueprint field types
- Graph widget for visual entry connections
