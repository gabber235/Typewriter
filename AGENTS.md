# PROJECT KNOWLEDGE BASE

**Project:** Typewriter
**Branch:** features/v1

Minecraft Paper plugin for interactive quests, NPC dialogues, and cinematics. Polyglot monorepo: Kotlin engine + extensions, Flutter panel, Rust/wasmCloud backend, shared Skir contracts.

## PRE-RELEASE DEVELOPMENT

Typewriter has not been released. Use this period to establish coherent systems and contracts, including substantial refactors and breaking changes while they are still easy to make. Keep the codebase clean by updating the current design and all affected consumers together. Migration machinery for unreleased behavior adds bloat: do not add migrations, compatibility shims, deprecated paths, or parallel contract versions. Keep project-owned contracts and APIs on `v1` wherever possible; do not increment their versions or revisions to accommodate breaking changes. Do not ask whether to add a migration, compatibility layer, or version bump; the answer is always no.

Skir declaration and method numbers are derived and written by `cargo xtask generate` (skir-src/AGENTS.md, Contract boundary); field and variant numbers stay contiguous and ascending. Renumber when contracts change instead of leaving historical gaps.

## HARD RULES

- **Ask permission** before destructive operations, ugly hacks, or changing build system
- **Use current code only**: Work in `services/`, `backend/`, `panel/`, and `skir-src/`. The `engine/`, `extensions/`, `module-plugin/`, and `app/` directories are legacy references and must not be modified.

## DEFINITION OF DONE

- devenv provides every tool (`devenv.nix`); run commands inside `devenv shell` or prefix them with `devenv shell --`. `cargo xtask` is the only command surface; `cargo xtask --help` lists it.
- Before reporting done, run `cargo xtask check <area>` for every area you touched (`services`, `backend`, `components`, `protocol`, `panel`, `gitops`, `docs`, `xtask`), and always `cargo xtask check quality`, which applies the project rules to every changed line. `cargo xtask check --list --base <ref>` names the areas a change affects; CI runs exactly those, and none for a change of only Markdown outside `documentation/`.
- Generated sources (Skir `skirout/` directories, build_runner `.g.dart`, `.freezed.dart` and `.gr.dart` parts) are build output: Git ignores them and they are never committed. Every `cargo xtask check` regenerates what changed first; after editing Skir contracts or annotated Dart outside a check, run `cargo xtask generate`. `.ignore` keeps them visible to `rg` and `fd`.
- When the harness itself misbehaves, run `cargo xtask doctor` first. `cargo xtask check --print` shows the plain command behind every step.
- Panel: `cargo xtask check panel` runs `flutter analyze` (not `dart analyze`) and `flutter test` in `panel/`, `panel/testkit/`, and `panel/widgetbook/`. Leave zero issues, including infos.

## REVIEW

- Before reporting planned work done, run the `typewriter-review` skill on your change and raise every mismatch it finds.

## LOCAL DEV LOOP

- Run one heavy build at a time (Gradle, Cargo, `build_runner`, `flutter run`). Parallel builds have overloaded the CPU. Steps run through `cargo xtask` queue on a machine wide lock automatically.
- Leave servers stopped when done. Gabber starts them.
- Backend deploy, main checkout only: `cargo xtask deploy local`. It builds and pushes every component and the database image, then restarts the workloads on `k3d-seamlezz-local`. Agent worktrees never deploy.
- Paper: Gabber restarts Paper through the IntelliJ run configurations in `.run/` (`Paper Embedded` runs `engine-paper:runServer`, `Paper Kubernetes` runs `engine-paper:runServerKubernetes`). Do not start Paper from the CLI.
- Service artifacts without a Paper restart: run `./gradlew :engine-paper:stagePaperArtifacts` from `services/`. The loader watches `plugins/Typewriter/artifacts/inbox/manual` and imports changed JARs automatically.
- Run only one Realm locally.
- Panel: from `panel/`, run `flutter run -d chrome --web-port=2350 --dart-define-from-file=config/local.json` (same as `Panel web local` in `panel/.fdemon/launch.toml`). Then open `http://localhost:2350` in the preview browser. The auth redirect URIs in `config/local.json` require port 2350.

## AGENT STACK

- Never start the stack by hand; `cargo xtask stack run -- <command>` starts this worktree's stack, runs the command and stops it. `--spec panel` (the default) adds the provisioned organization and a standalone Realm host bound to it; `--spec backend` stops at the backend components.
- During a run, addresses are in `.xtask/state/stack/panel.json`, `realm.properties` and the command's `STACK_*` environment; service logs are in `.xtask/state/stack/logs/`.
- A killed run can leave processes behind: `cargo xtask stack gc` removes them (`cargo xtask doctor` reports them).
- Agent worktrees never touch k3d or `kubectl`.

## GIT

- Name branches `features/<topic>`.
- Push changes in sibling repositories (see `AGENTS.local.md`) to their default branch. Reference them from this repository by pinned git revision, as `backend/Cargo.toml` does. Never use local path links.
