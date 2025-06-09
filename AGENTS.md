# AGENT Instructions

Welcome to the **Typewriter** repository. This project is organised into several modules:

- `engine/` – the Kotlin engine powering the plugin.
- `extensions/` – optional modules built on top of the engine.
- `documentation/` – website and developer docs built with Docusaurus.
- `app/` – the Flutter-based web UI.
- `module-plugin/` – Gradle plugin for building Typewriter modules.

Each folder contains its own `AGENTS.md` with more details:

- [documentation/AGENTS.md](documentation/AGENTS.md)
- [engine/AGENTS.md](engine/AGENTS.md)
- [extensions/AGENTS.md](extensions/AGENTS.md)
- [app/AGENTS.md](app/AGENTS.md)
- [module-plugin/AGENTS.md](module-plugin/AGENTS.md)

## General Guidelines

1. Use descriptive branch names and keep commit messages short (<72 characters for the subject).
2. Validate that the code builds before submitting a PR. Each module has build instructions in its own `AGENTS.md` file.
3. Follow the code style conventions described in the folder-specific `AGENTS.md` files.

