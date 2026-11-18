# P2: Runner C on testBalloon, and the dropped root compilation

## Answer

- **Runner C works: requirements declared in testBalloon with a needs header (players, frames, Paper need), a
  framework scheduler that runs, retries and reports them.** Each testBalloon test only mirrors the final verdict.
  Fake pool of 4 slots, fake bodies of 1 to 30 ms, 200 requirements, testBalloon 1.1.0.
  - **No throttling.** All 200 mirror tests were submitted 12 to 35 ms after scheduler start and all 200 were
    awaited at once. `all()` returned at 1613 ms against an ideal of 1500 ms (sum of body time times players over 4
    slots): **ratio 1.08**; per module runs 1.08 to 1.11. The cause is that `TestSuite.execute` launches every child
    under `Invocation.Concurrent` (`TestSuite.kt:274`).
  - **Flaky shows as failed** in Gradle events and XML. The scheduler must therefore keep the body's own frame first
    in the rethrown error.
  - **Selection happens before submission**: the scheduler saw exactly the selected ids, with testBalloon path
    syntax, not class and method names.
  - **`finish` runs after every mirror test** (200 of 200), but **a failure inside `finish` is silent**
    (BUILD SUCCESSFUL, no message). Only a Gradle `doLast` that checks the outcome `finish` writes makes it visible.
  - **One JVM holds one test compilation only.** Each compilation emits a `JvmEntryPoint` class with a fixed name, so
    every module's requirements must compile together.
- **Dropped try, root compilation** (`root-compilation` in the record): one root compilation reads every module's
  `gameTest` folder. **It works: 200 tests, one JVM, one scheduler instance**, at the cost of one dependency set and no
  `internal` access per module. It works only inside one Gradle build, so it cannot serve extensions built elsewhere.
  The pool process (P6) replaced it.

Machine and evidence: a developer machine, no Minecraft; Gradle 9.8.1, testBalloon 1.1.0, JVM per Gradle test worker.
The prototype lived under `services/prototypes/gv-testballoon/` (alpha and beta modules with 100 fake requirements
each in `gameTest` source sets, a framework module, a root module). Fake setup: every 20th requirement from the 7th
always fails, every 10th from the 3rd fails its first attempt, every 7th claims two players. Per run evidence is a
folder of `exit.txt`, `gradle-outcome.txt`, `gradle-test-events.txt`, `report.txt` and sometimes the JUnit XML.
Measured unless marked otherwise.

## Per module and root runs

| Run | Tests | Wall | Outcome | What it showed |
|---|---|---|---|---|
| `alpha` | 100 | 3954 ms | 18 failed (5 Failed, 13 Flaky, 82 Passed) | ratio 1.08, all 100 submitted within 16 to 42 ms, peak 4 slots, 128 attempts |
| `beta` | 100 | 3622 ms | 18 failed (same split) | ratio 1.11, 129 attempts |
| `root` | 200 | 6023 ms | 36 failed (10 Failed, 26 Flaky, 164 Passed) | one root compilation over both modules' sources: one scheduler instance, 200 awaited at once, ratio 1.08, 257 attempts, `all()` at 1613 ms |
| `root-classpath` | 100 | 3410 ms | 18 failed, task `gameTestClasspath` | a root Test task over both modules' compiled classes ran only alpha's 100 tests |

`report.txt` in each run also records: scheduler instances started in the JVM (always 1), submitting threads (one per
requirement), the sum of body time times players, the ideal on 4 slots, and "mirror tests finished before finish()"
(always all of them).

## Selection before submission

Patterns are testBalloon paths. `com...BankRequirements` or `com...BankRequirements.BANK-2` find nothing ("No tests
found"). A requirement needs `|<suite>|<id> *`.

| Run | Selected | Submitted | Notes |
|---|---|---|---|
| `sel-suite` | suite pattern `com...BankRequirements*` | 3 (BANK) | 2 failed (1 Failed, 1 Flaky, 1 Passed), ratio 1.54 |
| `sel-req` | one requirement by pattern | 1 | 1 Flaky (2 attempts) |
| `sel-req-full` | one requirement, a second pattern form | 1 | 1 Flaky (2 attempts) |
| `sel-two-modules` | two `--tests` across both modules | 2 (BANK 1, QUEST 1) | root runner, 2 failed |
| `sel-prefix-clash` | `SHOP-2*` | 7 (SHOP) | also selects SHOP-20 to SHOP-25 |
| `select-wild` | a wildcard prefix | 11 (SHOP) | 1 Flaky, 10 Passed |

The scheduler's own count of submitted ids matched the selection every time, so retries and the pool never see
unselected tests.

## Reporting facts

- **Ordinary tests in Gradle events and XML.** `classname=suite_com...BankRequirements`,
  `name=BANK-2 a deposit survives a killed Paper`. The reported time is queue wait plus every attempt (BANK-1: 1494 ms
  for a 12 ms body), not body time.
- **Flaky versus failed stack.** A Failed verdict rethrows the body's own throwable, whose first frame is the body
  line (`BankRequirements.kt:13`). A Flaky verdict's first frame is the mirror (`Requirement.kt:61`); the body line
  only appears in the `Caused by` chain. kotlinx.coroutines debug mode (on because Gradle enables `-ea`) adds a copied
  `Caused by` of the flaky error. A `junit.rs` rule "first `com.typewritermc` frame" would point at the framework for
  flaky.
- **IDE single runs were not verifiable.** `@TestElementName id` while the element is named `"$id $sentence"` means
  static analysis derives `BANK-2`, which no exact pattern matches.

## The finish check

| Run | Setup | Outcome |
|---|---|---|
| `pass-checked` | `finish` ok, Gradle `doLast` checks the last report line is `finish: ok` | exit 0, BUILD SUCCESSFUL |
| `fail-finish` | `finish` throws on purpose (`gv.failFinish=true`), no check | **exit 0, BUILD SUCCESSFUL**, no message; the error vanished |
| `fail-finish-checked` | same, with the check | exit 1, BUILD FAILED: "the game scheduler did not finish cleanly: finish: FAILED finish failed on purpose" |

The JUnit adapter drops session and compartment events (`TestBalloonJUnitPlatformTestEngine.kt:162`), which is why a
`finish` failure cannot reach Gradle on its own.

## Size

Framework: 217 code lines (Requirement 53, Scheduler 134 of which about 45 are the report, FakePool 30). Gradle: 21
lines per module (`gameTest` source set and task), 29 for the root. New concepts: `Requirement`, `RequirementScope`,
`Verdict` (Passed, Flaky, Failed), `GameCompartment` with its one object, `requirement()`, `Scheduler` (`start`,
`submit`, `finish`, `current`), `FakePool` and `Lease`, plus the finish outcome check in Gradle.

## Surprises

- `Invocation.Concurrent` already disables the test scope (`TestConfig.kt:498`), so `testScope(false)` is redundant,
  and there is no timeout at all.
- The element tree stayed out of the way: no testBalloon internals were needed.
- `requirement()` outside the compartment only fails at run time ("no scheduler").
- A root Test task over compiled classes silently runs half the suite: the second module's suites are never listed.

## What this means for the search

- Runner C stands. The planning draft's 50 ms debounce for planning order is not needed to start: submission is
  instant, so the scheduler can plan from what has arrived.
- The flaky error must carry the body's frame first, and xtask must gate on the TestRun being written, since a
  failure in `finish` is invisible to Gradle.
- Per module compilations cannot share one JVM. The root compilation proved the alternative but ties every module to
  one Gradle build; the separate pool process (P6) keeps per module compilations and shares the warm clients.

## Rerun

The code lived on branch `proto/gv-testballoon` at commit `7a77e7ba3` and this branch is deleted, so the commands are
kept only as a record. From `services`, through `cargo xtask heavy -- ./gradlew ...`: `:gv-proto-alpha:gameTest`,
`:gv-proto-beta:gameTest`, `:gv-proto:gameTest` (root compilation), `:gv-proto:gameTestClasspath` (root classpath
variant), with `--tests '<testBalloon path pattern>'` for the selection runs and `-Pgv.failFinish=true` for the
finish failure runs.

## Reuse

- `Requirement.kt`: the compartment, `requirement()` and the mirror test that awaits the verdict.
- `Scheduler.kt`: submit, claim, retry at the queue's end, verdicts, finish and the report.
- `FakePool.kt`: the fake slots and leases.
- `game-test-events.gradle.kts` and the module `build.gradle.kts` files: the `gameTest` source set and the finish
  outcome check.
