# PROJECT KNOWLEDGE BASE

**Project:** Typewriter
**Branch:** features/v1

Minecraft Paper plugin for interactive quests, NPC dialogues, and cinematics. Polyglot monorepo: Kotlin engine + extensions, Flutter panel, Rust/wasmCloud backend, shared Skir contracts.

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

## CONVENTIONS

**Kotlin** (engine, extensions, services, module-plugin):
4 spaces, 120 char lines, no inline comments, guard clauses, composition over inheritance

**Dart** (panel):
Double quotes required, trailing commas on multiline args, package imports only (no relative), files under 300 lines

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
