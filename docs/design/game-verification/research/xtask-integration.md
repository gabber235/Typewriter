# Plugging the game suite into xtask

Condensed from a read only research draft for the framework plan, written 2026-11-07. **Line numbers are as of commit
`24d058176` and will have moved.** The decisions were in the design record; this names the change points and where the
code of that day fought them.

## Answer

- **Letting xtask rerun failed requirements was dropped.** `results::attempts` overwrites the run's policy with its own
  (`results.rs:174`) and reruns every case whose last attempt failed (`results.rs:178`). With `RerunFailures(4)` a case
  that failed all 4 attempts inside the JVM would have its last attempt failed, so the loop calls `run(2, ..)` again:
  a second Gradle launch and **a client reboot for each rerun**. **Retries run inside the test JVM on warm clients**,
  and xtask needs a second entry point (`self_attempted`) that keeps the selection check (`results.rs:161`) and the
  run's own policy and never calls the runner again. `verdict` already reads a self attempted run correctly
  (`results.rs:85`).
- **Artifacts from a CI job to the evidence branch**: the e2e job writes `.xtask/results/<suite>/`, then
  `evidence stage` projects it into `.xtask/public` (published kinds only), and the job uploads that as
  `results-e2e-<suite>`; the report job downloads every `results-*` into `.xtask/results/inputs`, `evidence publish`
  stages again, uploads each file per `Store` (PNG and webp to branch `evidence` under `pr/<n>/<sha7>/<runner>/...`,
  mp4 to the docs site branch under `evidence/pr/...`), then rewrites the PR body.
- **`check --list` picks areas**: `review::changed_paths` (git diff from the merge base to the working tree, with
  moved from paths) feeds `graph::affected`, which keeps a step when any path starts with an `EVERY_AREA` prefix or its
  area's prefixes; `graph::list` sums budgets per area. The e2e job ignores areas: it runs whenever the list is not
  empty.
- **PR body per case**: `recording()` (`publish.rs:570`) walks every artifact of every attempt; a clip becomes a
  preview image plus a "full video" link, a screenshot an image, everything else is skipped; a case that did not pass
  gets its failure message. Failing cases show open under "Needs attention"; every case with a requirement shows in
  the collapsed "Recordings" table.

## 1. `game` runner in `TestRun`

`skir-src/harness/v1/test_run.skir:66` has `enum Runner` with `components`, `schema`, `panel`, `panel_web`, `step`,
`junit`. Add `game;`. The Kotlin type comes for free: `skir-kotlin-gen` writes every module into
`services/protocol/src/main/kotlin/skirout` (`skir.yml:8`), so the framework in the test JVM writes the same `TestRun`
the Rust side reads.

`xtask/src/results.rs:364` `runner_name` is the one exhaustive match (quarantine ids and media folders use it): add
`Runner::Game => "game"`. Quarantine ids become `game/<case id>` (`results.rs:51`). No other exhaustive match on
`Runner` exists outside tests (`e2e.rs:125`, `junit.rs:33` only construct).

## 2. Artifact kinds: golden, new frame, golden diff, clip, still frame

`test_run.skir:98`: `ArtifactKind` has `clip`, `screenshot`, `log_excerpt`, `spans`; `Artifact` is `kind` plus `path`.
Change points per kind:

- `clip` exists. A game clip comes from the client (`Video.java`), not from xtask's ffmpeg (`record.rs:406 cut`), so
  the framework must also write the preview `<clip>.webp` beside it: stage looks for it (`stage.rs:115`) and publish
  renders it unconditionally.
- `still_frame` overlaps `screenshot` (an image of a failed attempt, dropped for passed attempts at `stage.rs:62`):
  settle one kind.
- `new_frame`, `golden_diff` are new kinds, files in the attempt folder, both published.
- `golden`: the PNG lives on the evidence branch, not in the attempt folder, and stage refuses a listed file that is
  missing on disk (`stage.rs:66`). Either the framework copies the golden into the attempt folder after fetching it for
  the diff (simple, uploaded twice), or it is not a file artifact: a hash the publisher turns into
  `raw.githubusercontent.com/<repo>/evidence/goldens/<sha256>.png`.
- Approve needs to know which repo file a new frame replaces and its hash, which `Artifact` does not carry. A small
  record on `Attempt` carries it: `FrameCheck { golden_file, expected_sha256?, actual_sha256, tick }`, as
  `frames: [FrameCheck]`.

Public kinds are `ArtifactKind::published()` at `results.rs:126` (only `Clip | Screenshot`): add `NewFrame | GoldenDiff
| StillFrame` (and `Golden` when it is a file). `stage.rs:59` filters artifacts per attempt and bails when a listed
file is missing. `publish.rs:585` renders per kind: add arms for still frame and golden diff as images, new frame as an
image labelled "new", golden as an image from `goldens/`. `Store::of` (`evidence/mod.rs:182`) sends every non mp4 to
the images store, so PNGs land on branch `evidence` with no store change.

## 3. Tick on steps

`test_run.skir:50` `Step` has `at_millis`, `actor`, `says`. Add `tick: int64?` (engine ticks since the attempt began,
`StepClock`). Keep `at_millis`: the captions place steps on the clip by it (`captions.rs:100`) and a game clip is
still a wall clock video. `FrameCheck.tick` uses the same clock. `Failure.first_broken` (`test_run.skir:90`) can name
the window and tick as text, so no schema change is needed there.

## 4. `rerun_failures(4)` inside the JVM, reported through `results`

`results.rs:146` `attempts(policy, selection, quarantine, run)` runs `run(1, selection)`, bails on unmatched selection
ids, folds the policy, then loops `for n in 2..=limit` calling `run(n, ids)` for failed, not quarantined cases. Why it
cannot be reused unchanged:

- With `RerunFailures(4)` a case that failed all 4 JVM attempts has a failed last attempt, so the loop calls `run(2,
  ..)` again: a second Gradle launch, a client reboot.
- With `RerunFailures(1)` the loop never runs, but `folded` replaces the JVM's `RerunFailures(4)` with `(1)`, so the
  run file lies about its policy.

Proposed (one function, the selection check shared):

```rust
/// A run whose runner made every attempt itself under the policy it states.
pub fn self_attempted(run: TestRun, expected: &AttemptPolicy, selection: &[String]) -> Result<TestRun> {
    unmatched(&run, selection)?;            // extracted from attempts()
    ensure!(run.attempt_policy == *expected, "...");
    // every case: 1..=limit attempts, nothing after a pass under RerunFailures
    Ok(run)
}
```

The suite then calls `results::report` (`results.rs:283`) as every suite does. Flaky gating stays untouched:
`verdict` (`results.rs:85`) makes a case flaky when it failed, the last attempt passed and the policy is
`RerunFailures`, whoever made the attempts.

The JVM must mirror two things `attempts` does: skip retries of quarantined cases (`results.rs:188`,
`harness/quarantine.toml`, id `game/<case>`), and give a case it lost a failed attempt saying so (`results.rs:213`).
`--repeat n` maps to `Exactly(n)` (`e2e.rs:79`) and is passed into the JVM, which runs each requirement n times. The
policy the suite asks for is `e2e.rs:79` (`1 => RerunFailures(2)`, otherwise `Exactly(n)`); the game suite needs its
own default of `RerunFailures(4)`, because today the default is per `E2eArgs`, not per suite.

## 5. Flaky gates as today

No change in `results.rs:61` (`Verdict::Flaky`), `report` (`results.rs:352`, bails on flaky) or the change report's
health (`review/report.rs:724`, `results::read_all` then `verdict`). Two things can break it:

- **JUnit double count.** `junit::run` (`junit.rs:17`) reads every `TEST-*.xml` under a `test-results` folder written
  since the step started (`junit.rs:59`), always as `Exactly(1)`. If `gameTest` ran inside the services step
  (`graph.rs:213`, `./gradlew check coverageReport`) its testBalloon mirror tests would appear a second time as `junit`
  cases, with no flaky verdict. Keep `gameTest` out of `check`, or skip `test-results/gameTest` in `reports`
  (`junit.rs:56`).
- **`read_all` parses every `.json`.** `read_all` (`results.rs:244`) reads any `.json` below the results folder as a
  `TestRun` and fails otherwise; it skips only `RUN_EVIDENCE` (`results.rs:240`: `attempts`, `failures`, `screenshots`,
  `logs`). Per requirement coverage or frame indexes written as JSON must live below `attempts/` or in a folder added
  to `RUN_EVIDENCE`.

The JVM should use the same layout as the panel suites: run file at `.xtask/results/game/test_run.json`, evidence in
`attempts/<n>/` with `Attempt.folder` set (`e2e.rs:466`).

## 6. Clips only for failing and touched requirements

Where touched comes from today: `review/coverage.rs:40` reads whole files per area, summed over every test; nothing is
per test. `Coverage::read` (`coverage.rs:113`) intersects line hits with `Change.files[].added`. Reusable pieces:
`Change::load(ctx, base)` (`change.rs:55`, working tree against the merge base, added lines per file,
`FileChange.added` at `change.rs:43`), `touches_range` (`change.rs:121`), `kotlin_sources` (`coverage.rs:316`, maps a
JaCoCo `package/File.kt` to the repo path through the `/kotlin/` segment), `read_jacoco` (`coverage.rs:375`), `find`
(`coverage.rs:253`) and `stamp` (`coverage.rs:276`).

Who decides, and when: retries are never recorded; clips come from a demo rerun on the side Paper for failed, flaky and
touched requirements after the queue drains. That rerun happens inside the same JVM, so **touched must be known in the
JVM during the run**: xtask cannot rerun afterwards without rebooting clients. So:

1. xtask writes the change's added lines (`Change::load`, Kotlin files only) to a file the Gradle task reads, for
   example `.xtask/state/game/changed-lines.json` (outside results, so `read_all` never sees it).
2. The framework intersects each requirement's Paper side coverage with it and demo reruns touched requirements.
3. **The demo rerun must not be an `Attempt`.** `verdict` counts every attempt (`results.rs:75`): a passing demo after
   a failed attempt 4 would turn `Failed` into `Flaky`, and a demo that fails after a pass would make a pass `Flaky`.
   The demo needs its own place, for example `TestCase.demo: Demo?` (span, artifacts, folder, steps, whether touched);
   then `results::artifacts` (`results.rs:104`), stage and publish read it beside the attempts.

Optional: the game run also writes one merged `game.xml` JaCoCo file into `COVERAGE_DIR` (`coverage.rs:21`) with a
`SOURCES` entry for area `services`, so the PR's coverage table counts lines only the game suite ran.

`published_files` (`stage.rs:115`) keeps every clip with its `<clip>.webp` preview, walking `results::artifacts`; since
only demo reruns record, no clip filter is needed, but `artifacts` must also walk the demo. The recordings table
(`publish.rs:406`) lists every case with a requirement, so hundreds of game requirements each get a row. GitHub caps a
description at 65536 characters; the change map has a cap (`CHANGE_MAP_LIMIT`, `publish.rs:33`), and game rows likely
need one too, or only failing, flaky and touched rows.

## 7. Goldens: sha256 in the repo, PNG on `evidence` under `goldens/`, kept by prune

Stores (`evidence/mod.rs:166`): `Images` (branch `evidence`, root `pr`) and `Videos` (docs site branch, root
`evidence/pr`). `goldens/` is a sibling of `pr/` on branch `evidence` (`BRANCH`, `mod.rs:26`) and needs no new store,
only a path helper next to `Store::url` (`mod.rs:208`) for
`https://raw.githubusercontent.com/{REPOSITORY}/evidence/goldens/<sha256>.png`, used by the framework to fetch a
golden on a hash mismatch and by publish to show it.

`evidence/prune.rs:48` touches only `pr/<n>` folders. `goldens/` already survives: no branch removes it, and `squash`
(`branch.rs:143`) keeps the whole tree in one commit. "Kept by prune" holds today; what is missing is collecting
goldens no repo file references any more (add it only when size matters). A test pinning that prune never touches
`goldens/` is the change worth making now. `replace_media` (`publish.rs:90`) removes the whole `pr/<n>` folder on every
publish, so new frames published there exist only until the next CI run, which fits "the PR's last CI run".

## 8. `cargo xtask game approve --pr <n>`

`main.rs:44` has the CLI enum with no `game` command; add `Game(game::GameCommand)` with `Approve { pr: u64 }` and its
arm in the match at `main.rs:102`. Where approve gets the new frames:

| Source | Has the case to golden file mapping | Lifetime | Fork PRs |
|---|---|---|---|
| Actions artifact `results-e2e-game` of the PR head's last CI run (`gh run list`, `gh run download`) | yes: the staged `test_run.json` with its new frames | Actions retention (90 days default) | yes |
| Branch `evidence`, `pr/<n>/<sha7>/game/...` | no: only media is uploaded (`publish.rs:631 media`), never the run file | until the next publish | no (fork runs never publish) |

Recommendation: the Actions artifact. Approve then checks the run's `commit` is the PR head, for each `FrameCheck`
whose hashes differ writes `actual_sha256` into `golden_file` in the working tree, and pushes each new frame to
`goldens/<sha256>.png` through `BranchCheckout::clone_shallow` plus `commit_and_push` (`branch.rs:32`, `:108`,
credentials through `gh auth git-credential`). This needs `new_frame` in `published()` so the staged artifact carries
the PNGs.

## 9. Running the suite: e2e suite or check area

e2e today (`e2e.rs:89`, `:132`): `Suite` is `Panel`, `PanelWeb`, `Full` with a 30 minute budget. `scenarios`
(`e2e.rs:218`) is panel shaped: it starts a stack (`stack::run_keeping_evidence`, `e2e.rs:249`), runs `flutter drive`
per `Drive`, collects failure folders from stack logs (`e2e.rs:271`). Reusable for game: `take_turn` (`e2e.rs:208`,
heavy lock then clear the results folder), `evidence::record_with` with `video: false` for Xvfb only (the
`--display-only` flag already exists, "the Minecraft client records itself", `evidence/mod.rs:41`), and `verdict`
(`e2e.rs:633`, refuses an empty run, then `results::report`). A `Suite::Game` arm would call a new `game::run` that
generates, writes the changed lines, takes the heavy lock, runs the Gradle `gameTest` task in `services` inside
`record_with`, reads the JVM's run, applies `results::self_attempted`, writes and reports it.

Check area today (`graph.rs:35` `Area`, `:72` `paths`, `:99` `EVERY_AREA`, `:144` `program`): the services step is
`./gradlew check coverageReport`, heavy, with `services.xml` coverage and JUnit. `run_step` (`graph.rs:610`) records a
step as one `Exactly(1)` case and its JUnit as a second run; it never calls `results::report`, so the step's verdict
is Gradle's exit code.

| | e2e suite `game` | check area `game` |
|---|---|---|
| Display, Mesa, lavapipe | e2e job enters `--profile e2e` (`ci.yml:118`) | check job uses the default profile (`ci.yml:67`); needs a per area profile |
| Runs on | every PR with any area (`ci.yml:106`) | only when `services/` or `EVERY_AREA` changed (`graph.rs:490`) |
| Budget | job `timeout-minutes: 60`, shared by suites (`ci.yml:108`) | per area in `--list`, becomes the job timeout (`ci.yml:74`) |
| Verdict and report | `results::report`, flaky named | Gradle exit only; flaky only if testBalloon fails it |
| Recording wrapper | `record_with` already wired | none |

Recommendation: e2e suite. Requirement 3 asks for the full suite on every PR, and only the e2e job has the display.
`cargo xtask heavy -- ./gradlew ...` stays the local shortcut for one requirement; inside xtask the same lock is
`HeavyLock::acquire` (`heavy.rs:20`), since `heavy` refuses to wrap an xtask command (`heavy.rs:16`).

How `--list` picks areas (reference): `main.rs:110` to `:113`, `review/mod.rs:88`, `graph.rs:490`. Markdown outside
`documentation/` is dropped first (`graph.rs:493`). `graph::list` (`graph.rs:519`) prints `[{"area",
"budget_minutes"}]`, the sum of the area's step budgets plus `GENERATE` (20 min) when a step needs generated sources.

## 10. CI: e2e and report jobs

`.github/workflows/ci.yml:103` is the e2e job: matrix `suite: [panel, panel-web]`, `timeout-minutes: 60`, runs when
`needs.plan.outputs.areas != '[]'`, enters `devenv --profile e2e`, runs `cargo xtask e2e <suite>`, then `cargo xtask
evidence stage`, then uploads `.xtask/public/` as `results-e2e-<suite>`. Changes for `game`:

- Add `game` to the matrix (`ci.yml:112`).
- The checkout has no `fetch-depth: 0` (`ci.yml:114`), so `Change::load` against `BASE_SHA` cannot run there; touched
  needs full history and the base passed in (`cargo xtask e2e game --base "$BASE_SHA"`), as the check job does
  (`ci.yml:62`, `:79`).
- Caches: Paper jar, Minecraft client assets and the mod build have no cache key in the devenv action
  (`.github/actions/devenv/action.yml:14` knows `gradle`, `gradle-outputs`, `flutter`, `frame-vectors`).

The report job (`ci.yml:134`) needs no change: it downloads `results-*` (`ci.yml:148`), runs `review report`
(`ci.yml:153`) and `evidence publish` (`ci.yml:160`); `--jobs-failed` and the gate (`ci.yml:168`) already cover every
e2e matrix entry.

## Conflicts with the decisions

1. **`results::attempts` reruns from xtask** (`results.rs:178`) and rewrites the policy (`results.rs:174`). Decided:
   the JVM retries. Needs `self_attempted` (section 4).
2. **JUnit sees the mirror tests** if `gameTest` joins `check` (`junit.rs:59`, `graph.rs:219`): flaky game cases would
   also show as plain `junit` passes or failures.
3. **`read_all` reads every `.json`** below results (`results.rs:257`): per requirement coverage or indexes in JSON
   break every reader unless under `attempts/`.
4. **Stage refuses a listed, missing file** (`stage.rs:66`): a `golden` artifact that points at the evidence branch
   instead of a local file fails staging.
5. **Publish always links a clip preview** (`publish.rs:589`): client clips need a `<clip>.webp` written by the
   framework, or the PR shows a broken image. Captions are burned in only by xtask's `cut` (`record.rs:406`), so client
   clips have none unless the framework or xtask adds them.
6. **Touched cannot be computed after the run** for recording purposes: it must reach the JVM before the run (section
   6), and the e2e job lacks the history for it (`ci.yml:114`).
7. **A demo rerun reported as an attempt changes the verdict** (`results.rs:75`): it needs its own field on `TestCase`
   (section 6), and `recording()` (`publish.rs:573`) must render it.
8. **PR body size** with hundreds of requirement rows (`publish.rs:406`), no cap today.
9. **Clips go to the docs site branch**, not `evidence` (`Store::of`, `mod.rs:182`), sharing the site's 1 GB. Fine for
   failing and touched clips only.
10. **`still_frame` and `screenshot`** describe the same thing today; settle one kind.
11. **Quarantine** is applied to reruns in xtask (`results.rs:188`); the JVM must read `harness/quarantine.toml` itself
    or spend retries on quarantined cases.
12. **Approve from the evidence branch is not enough**: the run file is never uploaded there (`publish.rs:631`), and
    fork PRs never publish. Use the Actions artifact (section 8).
