# AGENT Instructions – Module Plugin

This Gradle plugin is used to build Typewriter modules.

## Validate Changes

Run from this folder:

```bash
./gradlew build
```

This ensures the plugin and processors compile and tests pass.

## Code Style

- Use 4 spaces for indentation and wrap lines at 120 characters.
- Keep functions short and focused; prefer guard clauses to nested conditionals.
- Favor composition over inheritance where possible.
- Document public APIs with KDoc, explaining when to use them rather than what
  each method does.
- Avoid inline comments. If the code is unclear, refactor it instead of adding
  explanations.

