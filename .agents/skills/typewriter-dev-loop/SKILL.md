---
name: typewriter-dev-loop
description: Run Typewriter locally: builds, the agent stack, Paper, the panel, service artifacts, deploy, and what to do when the harness misbehaves.
---

# Typewriter Dev Loop

## Builds
- One heavy build at a time (Gradle, Cargo, `build_runner`, `flutter run`); `cargo xtask` steps
  queue on a machine wide lock.
- `cargo xtask check --print` shows the plain command behind every step; run `cargo xtask doctor`
  first when the harness itself misbehaves.

## Agent stack
- `cargo xtask stack run -- <command>` starts this worktree's stack, runs the command and stops
  it. `--spec panel` (default) adds the provisioned organization and a bound Realm host;
  `--spec backend` stops at the backend components.
- Addresses: `.xtask/state/stack/panel.json`, `realm.properties`, the command's `STACK_*`
  environment. Logs: `.xtask/state/stack/logs/`.
- A killed run can leave processes: `cargo xtask stack gc` (doctor reports them).

## Main checkout only
- Backend deploy: `cargo xtask deploy local`; builds, pushes, restarts on `k3d-seamlezz-local`.
- Paper starts from the IntelliJ run configurations in `.run/` (`Paper Embedded`,
  `Paper Kubernetes`), never from the command line.
- Service artifacts without a Paper restart: `./gradlew :engine-paper:stagePaperArtifacts` from
  `services/`; the loader imports from `plugins/Typewriter/artifacts/inbox/manual`.
- Run only one Realm locally.
- Panel: from `panel/`, `flutter run -d chrome --web-port=2350
  --dart-define-from-file=config/local.json`, then `http://localhost:2350` (port required by the
  auth redirect URIs).
