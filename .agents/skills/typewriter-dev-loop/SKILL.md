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
- When the command needs the panel's or another non protocol generated source, run
  `cargo xtask generate` first: `stack run` brings only the protocol up to date.
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

## Game suite
- `cargo xtask e2e game` runs every `src/gameTest` requirement against real Minecraft clients on a
  stepped Paper, inside the stack's `game` spec (evidence in `.xtask/state/e2e/game`). It builds
  first, then boots its own pool, Papers and clients; never start them by hand. The pool lives exactly as long as the Gradle build. When a stuck pool still holds
  `pool.lock`, the next run fails with `GameUnavailable` naming `pool.log`; read that log.
- `--only GROUP-1,WINDOW-1` runs those requirements; `--repeat <n>` runs exactly n attempts of each,
  to hunt a flaky one.
- A smaller pool: `cargo xtask e2e game --clients 1` (default 4 clients). Every game Paper loads
  Typewriter, which needs the stack's environment, so a direct `./gradlew gameTest` fails naming the
  missing variable.
- Results: `.xtask/results/game/` holds `test_run.json`, one evidence folder per attempt (frames,
  golden candidates, clips) and `logs/<n>/` with `pool.log`, `paper.log` and `client-gv-<i>.log` for
  the newest 3 runs. Read them before rerunning.
- A golden that fails with the approve command: `cargo xtask goldens approve` records the frames in
  `.xtask/results/game` (or a folder given), and `cargo xtask goldens approve --pr <n>` the frames
  CI captured on pull request n. Approve refuses frames the pinned renderer (Linux, Vulkan through
  llvmpipe, devenv's Mesa) did not draw, so a Mac run reports goldens as not checked and approves
  nothing.

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
