# Game harness structure: two suites, demos off the verdict, one verdict per lost part, steady ticks

## Why

The structural review of the game test harness found four ways a run could pass or fail for a reason
the change under test never caused:

- the framework's own tests and the product's tests ran as one suite inside the stack, so a framework
  change waited for the stack and a stack problem failed framework cases;
- a demo (the clip pass) ran inside the verdict and could change it;
- a lost shared Paper, pool or client failed every attempt it held, one by one, instead of naming
  the one part that broke;
- a window could hold at a tick that depended on wall clock, so a slower machine passed or failed
  the same requirement differently.

## What changes

**Two suites.** `playtest` (modules under `services/playtest`, no stack) and `game` (the product,
inside the stack). `cargo xtask e2e playtest` and `cargo xtask e2e game`; `-Pplaytest.suite` selects
one in Gradle, and each suite builds only its own modules. `cargo xtask check --list --suites` names
the suites a change affects, for the CI plan.

**Demos as a separate run.** `cargo xtask e2e <suite> --demos` reads the verdict run's file and reruns,
once each with clips, every requirement that failed, was flaky, is quarantined, is unsteady, or the
change touched. It writes `results/<suite>-demos` with `evidence_only = true`; it never gates, and a
broken demo run is reported, not failed. The evidence pages show its clips beside the case they show.

**One verdict per lost part.** The run file lists its parts (pool, shared Paper, own Papers,
clients) with how each ended: ran to the end, or lost with a typed cause (`exited`, `left`, `stalled`,
`never_ready`, `broke`). Attempts a lost part held are `interrupted`, not failed, and xtask prints
one verdict naming the part. A memory limit cause fits in as one more `LossCause` case.

**Steady ticks.** An attempt carries a pace: the minimum wall clock between granted ticks. A
requirement whose attempts passed and that the change touched (an added line in its own code or in
code its attempt covered) runs once more at 5 ms and once at 50 ms. Every window must hold at the
same tick in every passing run, retries included, or the requirement is unsteady. The shared Paper
runs one pace at a time; an own Paper takes its attempt's pace. The framework suite gates on it;
`runtimes/paper` reports it without blocking until the holding PR. The test JVM writes each case's
conclusion, unsteady with the ticks that differed included, into the run file, and xtask gates on
that conclusion instead of comparing windows a second time.

**CI runs each affected suite on its own runner.** The plan job lists the suites a change affects
(`cargo xtask check --list --suites`) beside its check areas; the e2e matrix runs one runner per
suite, the product suite with the stack and the framework suite without it; a game suite's demo run
follows its verdict run on the same runner and never gates; the gate expects e2e only when the plan
named a suite. `cargo xtask goldens approve --pr` takes the frames of both game suites, never a
demo run's.

**Memory per part, measured (change 4, report mode).** Every game part has a planned limit by kind
(`PartLimit`: shared Paper 4608 MiB, own Paper 1638 MiB, client 1946 MiB, pool 512 MiB, display
256 MiB), and a JVM part's heap is its kind's share of that limit. Where CI delegates a cgroup
(`cargo xtask cgroup delegate`), `cargo xtask e2e` makes a tree per run: a leaf per stack service,
one for Gradle, and `game`, where the pool puts itself and each part it starts in a leaf of its own
with `memory.oom.group`. The run file lists each part's peak, its planned limit, whether the planned
limits fit the game's memory budget, and the budget; the evidence shows them as a table per run. A
part the kernel kills for memory is lost to `memory_limit`. For now every leaf's `memory.max` is the
runner's total and admission only records whether a part fits: the planned limits do not fit a 16 GB
runner with four clients, so the first CI run's peaks set the enforced limits.

**The game build needs no stack.** `gameTestBuild` read `TYPEWRITER_CONFIG_FILE` and
`STACK_GAME_ENGINES` as build inputs, values the stack publishes only once its services run. A module
now takes such a value from the suite's run environment with `gamePaper.fromRun("NAME")`; the pool
fills it in as each Paper boots and fails that boot naming a variable the run does not set. `check`
builds `gameTestBuild` where no stack runs, which holds the requirement, so the game build can share
one Gradle with the stack's own builds (the overlap #584 wanted).

**Fixes the check found.**

- RESTART-2 held its after-restart window at tick 1, 4 or 3 depending on pace. The plugin answered
  a resume with the tick before its delivery, and the delivery runs a wall clock dependent number of
  ticks whose records the pool drops while the Paper restarts. A resume now answers with the tick
  its delivery ended, as `restartPaper` and `rejoin` already documented, and RESTART-2 states the
  real bound: the first tick after the restart shows the stick.
- Carried from the review branch: a rejoining player is listed to its attempt in the tick it joins
  (68dae17a5c), with QUIT-2's 1 tick bound.
- Carried: a game run that did not pass stages its Paper logs beside the pool log (bc0a7ec1ad,
  edfef27410), without the rule that a failed demo fails the run.
- TOAST-1's toast window held at a wall clock dependent tick: the client ran the GUI's update in
  every frame, and how many frames run between two ticks depends on wall clock. While the client
  steps, the update now runs once per tick, in the first frame after it.
- A verdict run's touched lines file is written after the run's results folder is cleared, so it
  never reads the last run's.

## Evidence

Local `cargo xtask e2e playtest --only TOAST-1,RESTART-2,QUIT-2`:

| Case | 0 ms | 5 ms | 50 ms |
| --- | --- | --- | --- |
| RESTART-2 before the fix (after-restart window) | tick 1 | tick 4 | tick 3 |
| RESTART-2 after the fix | tick 1 | tick 1 | tick 1 |
| QUIT-2 (every window) | tick 1 | tick 1 | tick 1 |
| TOAST-1 (toast window) | tick 10 | tick 10 | tick 10 |

## Not in this PR

- Enforcing the memory limits and refusing a part that does not fit: after one CI run gives real
  peaks.
- Failing the pinned runner when it cannot enforce limits: with enforcement.
- Sharing the stack build between jobs: a follow up.

## CI workflow changes

`.github/workflows/ci.yml`:

- **One runner per suite** (5aae01d7a6a): the plan job writes `suites` beside `areas`, and the e2e
  matrix runs one runner per suite the change affects instead of the fixed panel, panel-web and game
  list. Each suite keeps only the caches it uses; the playtest suite skips Flutter and the frame
  vectors.
- **Demos after the verdict** (5aae01d7a6a): a game suite's runner runs `cargo xtask e2e <suite>
  --demos` after its verdict run, whatever the verdict was, and that step never gates.
- **The gate follows the plan** (5aae01d7a6a): the gate and the report's `--jobs-failed` expect a
  skipped e2e job when the plan named no suite, and a successful one when it named any.
- **A cgroup for the game suites** (7ebc35942fb): before the verdict run, `cargo xtask cgroup
  delegate` remounts the runner's cgroup tree writable, moves the job's processes into
  `typewriter/job`, gives the job user `typewriter`, and names it in `TYPEWRITER_CGROUP`, so each
  game run measures every part's memory.

## Design record changes

`docs/design/game-verification/README.md`:

- **The parts:** two suites, `playtest` without the stack and `game` inside it.
- **The parts:** the game build needs no stack (`gamePaper.fromRun`).
- **Ticks:** a pace bullet.
- **Own Papers:** windows after a restart count from the tick its delivery ended.
- **Retries and verdicts:** `Unsteady` and `Interrupted` rows; bullets for steady ticks, paced
  attempts and lost parts.
- **Coverage:** what touched means; the demo run.
- **CI:** two suites, the plan's suite list, demos after the verdict, sharding declined for now.
- **Decisions:** "Every game Paper loads Typewriter" superseded; new decisions of 2026-11-24: two
  suites with demos off the verdict, one verdict per lost part, steady ticks checked.
- **Memory:** planned limits per part kind, the run's cgroup tree, report mode, peaks in the run
  file.

`docs/drive/game-harness-structure/record.yaml`: the drive record of this work (tries, decisions,
open items).
