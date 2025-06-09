# AGENT Instructions – Extensions

Extensions are modular Kotlin projects that add features on top of the engine.

## Validate Changes

Run from this folder:

```bash
./gradlew build
```

This validates that all existing extensions compile successfully.

## Adding a New Extension

1. Create a directory ending with `Extension` (e.g. `MyPluginExtension`).
2. Provide a `build.gradle.kts` using the `typewriter` plugin.

## Code Style

- Use 4 spaces for indentation and wrap lines at 120 characters.
- Keep functions short and focused; prefer guard clauses to nested conditionals.
- Favor composition over inheritance where possible.
- Document public APIs with KDoc, explaining when to use them rather than what
  each method does.
- Avoid inline comments. If the code is unclear, refactor it instead of adding
  explanations.

