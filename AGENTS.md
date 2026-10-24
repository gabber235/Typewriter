# PROJECT KNOWLEDGE BASE

**Project:** Typewriter
**Branch:** features/v1

Minecraft Paper plugin for interactive quests, NPC dialogues, and cinematics. Polyglot monorepo: Kotlin engine + extensions, Flutter panel, Rust/wasmCloud backend, shared Skir contracts.

## PRE-RELEASE DEVELOPMENT

Typewriter has not been released. Use this period to establish coherent systems and contracts, including substantial refactors and breaking changes while they are still easy to make. Keep the codebase clean by updating the current design and all affected consumers together. Migration machinery for unreleased behavior adds bloat: do not add migrations, compatibility shims, deprecated paths, or parallel contract versions. Keep project-owned contracts and APIs on `v1` wherever possible; do not increment their versions or revisions to accommodate breaking changes. Do not ask whether to add a migration, compatibility layer, or version bump; the answer is always no.

Skir declaration and method numbers are derived and written by `bun run generate:protocol` (skir-src/AGENTS.md, Contract boundary); field and variant numbers stay contiguous and ascending. Renumber when contracts change instead of leaving historical gaps.

## HARD RULES

- **Ask permission** before destructive operations, ugly hacks, or changing build system
- **Use current code only**: Work in `services/`, `backend/`, `panel/`, and `skir-src/`. The `engine/`, `extensions/`, `module-plugin/`, and `app/` directories are legacy references and must not be modified.

## DEFINITION OF DONE

- Run `dagger check --no-generate` from the repository root before reporting done. It runs every annotated `+check` function and skips generate-as-checks.
- While iterating, run one check by name, for example `dagger check panel-analysis` or `dagger check services-check`.
- Panel: run `flutter analyze`, not `dart analyze`, in `panel/`, `panel/testkit/`, and `panel/widgetbook/`. This matches `panel-analysis` in `.dagger/panel.go`. Leave zero issues, including infos.
- Services: `./gradlew check ktlintCheck` from `services/` (see `services/DEVELOPMENT.md`).
- CI: ignore `database-rollout-lint` failures while pre-release. There are no rollouts yet.

## LOCAL DEV LOOP

- Run one heavy build at a time (Gradle, Dagger, `build_runner`, `flutter run`). Parallel builds have overloaded the CPU.
- Leave servers stopped when done. Gabber starts them.
- Backend deploy, from the repository root:
  1. `dagger call wash publish-components` (registry and credentials come from `.env`, `WASH_PUBLISHCOMPONENTS_*`).
  2. `kubectl delete workloadreplicasets -A --all` so the runtime operator recreates workloads and pulls the new `:latest` images. Only against the local context `k3d-seamlezz-local`.
- Paper: Gabber restarts Paper through the IntelliJ run configurations in `.run/` (`Paper Embedded` runs `engine-paper:runServer`, `Paper Kubernetes` runs `engine-paper:runServerKubernetes`). Do not start Paper from the CLI.
- Service artifacts without a Paper restart: run `./gradlew :engine-paper:stagePaperArtifacts` from `services/`. The loader watches `plugins/Typewriter/artifacts/inbox/manual` and imports changed JARs automatically.
- Run only one Realm locally.
- Panel: from `panel/`, run `flutter run -d chrome --web-port=2350 --dart-define-from-file=config/local.json` (same as `Panel web local` in `panel/.fdemon/launch.toml`). Then open `http://localhost:2350` in the preview browser. The auth redirect URIs in `config/local.json` require port 2350.

## GIT

- Name branches `features/<topic>`.
- Push changes in sibling repositories (see `AGENTS.local.md`) to their default branch. Reference them from this repository by pinned git revision, as `backend/Cargo.toml` and `dagger.json` do. Never use local path links.
