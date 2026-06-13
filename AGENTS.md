# PROJECT KNOWLEDGE BASE

**Project:** Typewriter
**Branch:** features/v1

Minecraft Paper plugin for interactive quests, NPC dialogues, and cinematics. Polyglot monorepo: Kotlin engine + extensions, Flutter panel, Rust/wasmCloud backend, shared Protobuf contracts.

## HARD RULES

- **Plan required** for multi-file changes, new patterns, or architecture changes
- **Resubmit plan** when current plan is not working. Research first, then resubmit. No decision changes without a new approved plan.
- **Research first** before making structural changes
- **Ask permission** before destructive operations, ugly hacks, or changing build system
- **Never touch `app/`**: legacy, outdated, do not modify
- **Never edit `docs/adapters/`**: auto-generated

## ANTI-PATTERNS

| Pattern | Why Bad |
|---------|---------|
| Single quotes in Dart | Linter fails. Use double quotes |
| Relative imports in Dart | Breaks tooling. Use package imports |
| Code snippets in docs directly | Breaks snippet system. Use `_DocsExtension` |
| Manual `snippets.json` edits | Auto-generated from code blocks |
| Proto enum without TYPE_UNSPECIFIED=0 | Protocol requires it first |

## CONVENTIONS

**Kotlin** (engine, extensions, services, module-plugin):
4 spaces, 120 char lines, no inline comments, guard clauses, composition over inheritance

**Dart** (panel):
Double quotes required, trailing commas on multiline args, package imports only (no relative), files under 300 lines

**Protobuf**:
snake_case fields, PascalCase messages. Enums: prefix with type name, `_UNSPECIFIED = 0` first

## COMMANDS

### Panel (run from `panel/`)
```bash
task panel:run:web:local     # Run panel in browser
task proto                   # Regenerate Dart from proto
task generate                # Run build_runner (freezed, riverpod)
flutter test test/path.dart  # Test single file
dart analyze lib/path.dart   # Analyze single file
```

### Kotlin (engine, extensions, services)
```bash
./gradlew build              # Build all
./gradlew test               # Test all
./gradlew :module:test       # Test single module
```

### Backend (run from `backend/`)

Root tasks run across ALL components:
```bash
task build:all               # Build all wasmCloud components
task test:all                # Run all integration tests in single binary (fastest)
```

Component-specific tasks run from each subdirectory:
```bash
cd backend/auth/auth-callout && task build   # Build one component
cd backend/auth/auth-callout && task test    # Test one component
```

Targeted testing:
```bash
task test FILTER=test_name   # Run specific test by name
```

### Documentation (run from `documentation/`)
```bash
bun run validate             # Biome (format + lint) + astro check — the gate
bun run fix                  # Auto-apply Biome fixes, then re-check types
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add entry type | `extensions/BasicExtension/` |
| Add entity support | `extensions/EntityExtension/` |
| Modify panel UI | `panel/lib/` |
| Add API endpoint | `backend/` + `proto/api/` |
| Update shared models | `proto/models/` |
| Code snippets for docs | `extensions/_DocsExtension/` |

## CRITICAL PATTERNS

### Documentation Code Snippets
Code lives in `extensions/_DocsExtension/`, NOT in docs:
```kotlin
//<code-block:my-tag>
// code here
//</code-block>
```
Reference in docs: `<CodeSnippet tag="my-tag" />`

### Panel Testing
Use `testApp()` and `pumpTestApp()` from `test/test_utils.dart`.
Widgetbook components: wrap with `FakeApp`.

### Proto Changes
After editing `.proto` files:
- Panel: run `task proto` in panel/
- Backend: automatic via build.rs
- Services: automatic via protokt
