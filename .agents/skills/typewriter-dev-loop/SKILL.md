---
name: typewriter-dev-loop
description: Run Typewriter locally: builds, the agent stack, Paper, the panel, service artifacts, deploy, and what to do when the harness misbehaves.
---

# Typewriter Dev Loop

## Builds
- One heavy build at a time (Gradle, Cargo, `build_runner`, `flutter run`); `cargo xtask` steps
  queue on a machine wide lock. A heavy command without an xtask step (`flutter test`,
  `./gradlew`, `cargo test`) joins that queue as `cargo xtask heavy -- <command>`.
- `cargo xtask check --print` shows the plain command behind every step; run `cargo xtask doctor`
  first when the harness itself misbehaves.

## Agent stack
- `cargo xtask stack run -- <command>` starts this worktree's stack, runs the command and stops
  it. `--spec panel` (default) adds the provisioned organization and a bound Realm host;
  `--spec backend` stops at the backend components.
- Addresses: `.xtask/state/stack/panel.json`, `realm.properties`, the command's `STACK_*`
  environment. Logs: `.xtask/state/stack/logs/`.
- A killed run can leave processes: `cargo xtask stack gc` (doctor reports them).

## End to end failures
- `cargo xtask e2e <suite> --only CONN-1` reruns one scenario; `--repeat <n>` hunts a flaky one.
- A run's results folder is `.xtask/results/<target prefix><device>/`: `panel`, `panel-web`, or
  `full-panel-web` on the CI cluster.
- A failed attempt leaves `attempts/<n>/[<drive>/]failures/<case>/` there (a drive other than the
  scenario drive has its own folder): the failure screenshot, `panel.log` (the panel's debugPrint
  and its error), `drive.log` and every service log cut to the attempt's time window, and
  `spans.otlp.jsonl` (the panel, backend and Realm spans of the traces the scenario started). It
  stays local, since CI uploads only what `cargo xtask evidence stage` writes to `.xtask/public`;
  read it before rerunning.

## Main checkout only
- Backend deploy: `cargo xtask deploy local`; builds, pushes, restarts on `k3d-seamlezz-local`.
- Paper starts from the IntelliJ run configurations in `.run/` (`Paper Embedded`,
  `Paper Kubernetes`), never from the command line.
- Service artifacts without a Paper restart:
  `cargo xtask heavy -- ./gradlew :engine-paper:stagePaperArtifacts` from `services/`; the loader
  imports from `plugins/Typewriter/artifacts/inbox/manual`.
- Run only one Realm locally.
- Panel: from `panel/`, `flutter run -d chrome --web-port=2350
  --dart-define-from-file=config/local.json`, then `http://localhost:2350` (port required by the
  auth redirect URIs).
