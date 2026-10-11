# PROJECT KNOWLEDGE BASE

**Project:** Typewriter
**Branch:** features/v1

Minecraft Paper plugin for interactive quests, NPC dialogues, and cinematics. Polyglot monorepo: Kotlin engine + extensions, Flutter panel, Rust/wasmCloud backend, shared Skir contracts.

## PRE-RELEASE DEVELOPMENT

Typewriter has not been released. Use this period to establish coherent systems and contracts, including substantial refactors and breaking changes while they are still easy to make. Keep the codebase clean by updating the current design and all affected consumers together. Migration machinery for unreleased behavior adds bloat: do not add migrations, compatibility shims, deprecated paths, or parallel contract versions. Keep project-owned contracts and APIs on `v1` wherever possible; do not increment their versions or revisions to accommodate breaking changes.

Keep Skir declaration IDs and field or variant numbers contiguous and ascending within their respective sequences. Renumber them when contracts change instead of leaving historical gaps.

## HARD RULES

- **Ask permission** before destructive operations, ugly hacks, or changing build system
- **Use current code only**: Work in `services/`, `backend/`, `panel/`, and `skir-src/`. The `engine/`, `extensions/`, `module-plugin/`, and `app/` directories are legacy references and must not be modified.
