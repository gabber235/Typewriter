# AGENT Instructions – Engine

The engine is written in Kotlin and built with Gradle. To work on this module:

## Building & Testing

From this folder run:

```bash
./gradlew build
./gradlew check
```

`build` compiles the engine and `check` executes the unit tests found in
`engine-paper/src/test`.

## Submodules

- `engine-core` – platform-agnostic logic and API definitions.
- `engine-loader` – bootstraps the core and loads extensions.
- `engine-paper` – Paper-specific implementation and test harness.

## Code Style

- Use 4 spaces for indentation and wrap lines at 120 characters.
- Keep functions short and focused; prefer guard clauses to nested conditionals.
- Favor composition over inheritance where possible.
- Document public APIs with KDoc, explaining when to use them rather than what
  each method does.
- Avoid inline comments. If the code is unclear, refactor it instead of adding
  explanations.

