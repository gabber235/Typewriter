# PROJECT KNOWLEDGE BASE

**Project:** Typewriter
**Branch:** features/v1

Minecraft Paper plugin for interactive quests, NPC dialogues, and cinematics. Polyglot monorepo: Kotlin engine + extensions, Flutter panel, Rust/wasmCloud backend, shared Skir contracts.

## HARD RULES

- **Ask permission** before destructive operations, ugly hacks, or changing build system
- **Use current code only**: Work in `services/`, `backend/`, `panel/`, and `skir-src/`. The `engine/`, `extensions/`, `module-plugin/`, and `app/` directories are legacy references and must not be modified.
