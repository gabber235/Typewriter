# Typewriter

Minecraft Paper plugin for interactive quests, NPC dialogues and cinematics: Kotlin services,
a Rust and wasmCloud backend, a Flutter panel, and Skir contracts shared between them.

## Rules

- Pre-release: change the design and every consumer together. No migrations, compatibility
  shims, deprecated paths, or contract version bumps, and do not ask whether to add one.
- Work in `services/`, `backend/`, `panel/` and `skir-src/`. `engine/`, `extensions/`,
  `module-plugin/` and `app/` are legacy references; never modify them.
- When a design record is created or updated, keep it in `docs/design/`; commit design records
  only when asked or when a design topic is finished. Worktrees read the matching record before
  building.
- Ask before destructive operations, ugly hacks, or build system changes.
- devenv provides every tool; `cargo xtask` is the only command surface (`cargo xtask --help`).
  A heavy command xtask has no command for (`flutter test`, `./gradlew`, `cargo test`) runs
  through `cargo xtask heavy -- <command>`, which queues behind other heavy builds.
- When a heavy command reports that it is waiting for the lock, let it wait: run it in the
  background and wait for its exit. Never stop the holder or build your own lock.
- Generated sources are build output and never committed; `cargo xtask generate` rebuilds them,
  and `.ignore` keeps them visible to `rg` and `fd`.
- Agent worktrees never deploy, never touch k3d or `kubectl`, and never start Paper or another
  server by hand; leave servers stopped.

## Done

- Run `cargo xtask check <area>` for every area touched and always `cargo xtask check quality`;
  `cargo xtask check --list` names the areas a change affects.
- Before reporting planned work done, run the `typewriter-review` skill and raise every mismatch.

## Git

- Branches are `features/<topic>`. Sibling repositories (`AGENTS.local.md`) push to their default
  branch and are referenced by pinned git revision, never by local path.
