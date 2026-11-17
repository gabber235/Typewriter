# P6: The warm game pool as its own process

## Answer

- **It works: the warm pool and scheduler run as their own process and every test JVM (module, extension, IDE run)
  submits to it.** Two test JVMs shared one pool of 4 fake slots, and the pool needs no lock in the client:
  - **Find or start:** the pool owns one lock (`pool.lock`). Both test JVMs of a cold `--parallel` run found no pool
    and each spawned one; the second lost the lock and exited, both sessions joined the winner. A stale `pool.port`
    after a crash costs nothing (connect refused, the next test JVM starts a pool).
  - **A warm single requirement takes 2 s of Gradle time against 20 s cold** (pool side 39 to 48 ms against 16 010 ms
    boot). The idle limit decides how often a developer pays the boot.
  - **The pool must rotate between test JVMs.** A single requirement arriving 1.5 s into a 100 requirement run waited
    **325 ms with rotation against 4 071 ms with one FIFO queue.**
  - **Attempts: the pool owns the count, the test JVM owns the throwables.** A Failed mirror still rethrows the body's
    own throwable (first frame `BankRequirements.kt:13`); flaky still fails the mirror.
  - **One TestRun per run across both modules works** with a run id from outside (`gv.run`), 200 cases in one file.
  - **Failure modes all end clearly, none hung:** a killed test JVM, a killed pool and a version mismatch each fail
    with a message naming the cause. Not covered: a pool that is alive but stuck.
  - **About 590 lines against 217** for the single JVM shape (2.5 times).
- Open (recorded in the Surprises): detach the pool on purpose (it survives only by process group luck), replace a
  stale idle pool automatically, a heartbeat or lease deadline for a stuck pool, and keep the report safe from a pool
  crash.

Machine and evidence: a developer machine, no Minecraft. The pool is a plain JVM main with 4 fake client slots (16 s
fake boot), the scheduler (claims, retries at the end of the queue up to 4 attempts, Passed, Flaky, Failed) and the
TestRun writer. Two test compilations (`alpha`, `beta`, 100 requirements each, the fake bodies of P2) and one baseline
compilation over both (`combined`, 200) submit over a loopback TCP socket. **The body stays in the test JVM**: the
pool only leases players and counts attempts. Per experiment folders `evidence/<nn-name>/` hold `outcome.txt`,
`report.txt`, `test_run.json`, `pool-log.txt` and `gradle.txt`. Measured.

## Shape

```
test JVM (one per gameTest task)              pool process (one per pool dir)
  mirror test ── SUBMIT id players ──────────▶  queue per test JVM
              ◀─ LEASE id attempt players ───   claim slots (fair rotation)
  body runs here, in the mirror's coroutine
              ── RESULT id attempt PASS|FAIL ─▶  release; retry at queue end or settle
              ◀─ VERDICT id kind attempts ────
  aroundAll end ─ END ───────────────────────▶  write runs/<run>/test_run.json
```

Find or start: read `pool.port`, connect, `HELLO version run module pid`. Nothing answers: copy the pool's jars to
`versions/<hash>/` and spawn `java -cp versions/<hash>/* PoolKt <dir> <hash>` (stdout to `pool.log`, stdin from
`/dev/null`), then retry the connect for up to 30 s. The pool's first act is `tryLock` on `pool.lock`; a pool that
loses exits. The version is a SHA-256 over the pool's classpath jars. Copying the jars into a version folder keeps a
rebuild from changing a running pool's classes.

## Lifetime

- `STOP` runs the pool's exit path: every fake client logs that it quits, `pool.port` is removed, the process ends
  (`03-explicit-stop`: 0 pool processes after, no port file).
- The idle stop does the same: with an 8 s limit the pool stopped 8 s after the last test JVM left (`17-idle-stop`),
  and the next single requirement paid the full boot again: 18 s Gradle, 16 007 ms pool side
  (`18-after-idle-single`).
- While it lives, any later run reuses it, also one with `--no-daemon` (`19-no-daemon`, 10 s Gradle): single
  requirement 20 s Gradle time cold against 2 s warm (`07-single-cold`, `08-single-warm`, `08b-single-warm-repeat`).
- `cargo xtask heavy` kills its whole process group when the command ends (`xtask/src/process.rs` `Group`), yet the
  pool survives, because it inherits the group of the Gradle daemon, which Gradle starts in a group of its own. That
  held without a daemon too: with `--no-daemon` (how CI runs, `GRADLE_OPTS=-Dorg.gradle.daemon=false`) the spawned
  pool sat in the single use daemon's own group 49436 and outlived the build (`20-no-daemon-spawn`). In CI a pool
  that outlives the build is wasted; it needs a short idle limit or an explicit stop at the end of the run.

## Fairness and total time

- Started together, both modules got the same share: 128 and 128 leases cold (`04-cold-both`), 126 and 128 with
  bodies times 10 (`10b-together-fair`).
- Arriving later is where it differs. Single requirement (IDE run) at 1.5 s into a 100 requirement run: **325 ms with
  rotation against 4 071 ms with one FIFO queue** (`09-ide-during-run-fair`, `12-ide-during-run-fifo`). A module
  starting 1.5 s late finished at 14.6 s next to the other's 15.0 s with rotation; with FIFO its first attempts waited
  a median 7.0 s against 2.9 s for the early module (`10-stagger-fair`, `13-stagger-fifo`).
- **Total time:** two JVMs with 100 each, 1 970 ms pool side, against one JVM with 200, 1 922 ms, both 4 s Gradle
  (`05-warm-both`, `06-warm-combined`); the single JVM prototype took 1 613 ms in process. The socket adds about 5 ms
  per attempt of slot time (7 546 ms slot time for 256 attempts against about 6 000 ms in process): irrelevant for
  real bodies of seconds, visible at 1 to 30 ms.

## Attempts

The mirror test loops on its inbox: each `LEASE` runs the body again in the same mirror coroutine and reports
`RESULT`; the pool decides retry or verdict. The failure objects never leave the test JVM, so a Failed mirror rethrows
the body's own throwable and the TestRun gets the message and that frame as `first_broken`. **Flaky still fails the
mirror** (13 flaky and 5 failed per module, `100 tests completed, 18 failed`), with the same stack shape as P2: first
frame `Requirement.kt:61`, the body line in `Caused by`. A retry re-runs the body in the test JVM, so anything the body
keeps in the test JVM (captured state, a static) survives into the next attempt; bodies must not rely on that.

## One TestRun per run

Both tasks of one Gradle invocation pass the same `gv.run` (a root extra property; xtask would pass its own with
`-Pgv.run`), and the pool keeps one `RunRecord` per run id, rewriting `runs/<run>/test_run.json` whenever a test JVM
ends. Both modules' 200 cases land in one file with ids `alpha:BANK-1` and `beta:QUEST-1` (`05-warm-both`). Without a
run id (an IDE run) each test JVM is its own run. xtask needs:

- the file under `.xtask/results` (or a copy there), since `read_all` reads every `*.json` below it at any depth, so
  per run or per JVM files both work without merging;
- a `game` variant in `Runner` (the prototype writes `junit` for lack of one);
- `attempt_policy` `rerun_failures: 4`, which makes `verdict()` call a pass after a failure Flaky, matching the pool.

The JSON was written by hand in Skir's readable shape and was not read back by xtask (its generated sources were
absent in that worktree).

## Failure modes

| Run | Fault | What happened |
|---|---|---|
| `14-kill-test-jvm` | `Runtime.halt` in CHAT-5 with beta running (exit 1, 13 s Gradle) | Gradle fails alpha with `Process 'Gradle Test Executor 52' finished with non-zero exit value 137`; the pool sees the socket close, fails the 4 leased attempts (`test JVM alpha (pid 60472) disconnected during this attempt`) and the 84 queued attempts (`before this attempt ran`), holds the 4 slots for a 2 s reset, writes the run, and beta finishes its 100 normally. A real pool cannot trust a client a dead body was driving, so the reset is required |
| `15-kill-pool` | halt after 100 leases (exit 1, 19 s Gradle) | Every mirror without a verdict fails at once with `the game pool (pid 91114, no longer running) broke the connection (java.net.SocketException: Connection reset) before this requirement's verdict; see .../pool.log`. Verdicts already given stand. **No TestRun is written**: the run lived in the pool's memory and the stale port file was left behind |
| `16-after-pool-crash` | the next run after the crash | Found the stale `pool.port`, was refused, started a new pool (the start race repeated, one loser), paid the boot again; all 200 cases ran |
| `02-version-mismatch` | pool code changed under a running pool | The pool refuses the HELLO and every mirror fails with `the game pool (pid 48315) ... runs version 561b7ef2724b, this test JVM needs 9a1b4c88c807; 0 test JVMs use it now. Stop it ...`. 2 s Gradle |
| `00-start-failure` (by accident) | pool dies while starting (its classpath copy was empty, `ClassNotFoundException`) | Both test JVMs failed every mirror with `the game pool exited with 1 while starting; see .../pool.log`; about 40 s wall for the whole run, no hang |

Not covered: a pool that is alive but stuck (SIGSTOP, deadlock) would hang every mirror; it needs a heartbeat or a per
lease deadline.

## Selection and single runs

`--tests` and single runs work unchanged. Selection still happens in testBalloon before submission;
`--tests '|com.typewritermc.proto.gvpool.alpha.BankRequirements|BANK-3*'` submitted exactly 1 case. Warm: 2 s Gradle,
under 50 ms in the pool, no boot (`08`, `08b`). Cold: 20 s. An IDE run delegating to Gradle is this same command; it
was not run from an IDE here.

## Evidence folders

| Folder | Outcome |
|---|---|
| `00-start-failure` | pool dies at start, every mirror fails clearly (about 40 s) |
| `01-cold-both`, `04-cold-both` | two cold test JVMs, two spawned pools, one lock winner; 23.9 s wall; 128 and 128 leases |
| `02-version-mismatch` | refused with the version message, 92 s wall for the experiment, 2 s Gradle |
| `03-explicit-stop` | `STOP` over the port ends the pool, 0 processes, no port file |
| `05-warm-both`, `06-warm-combined` | warm both modules against one combined JVM: 1 970 ms against 1 922 ms pool side; one TestRun for both |
| `07-single-cold`, `08-single-warm`, `08b-single-warm-repeat` | one requirement: 20 s cold, 2 s warm |
| `09-ide-during-run-fair`, `12-ide-during-run-fifo` | late single requirement: 325 ms against 4 071 ms |
| `10-stagger-fair`, `10b-together-fair`, `13-stagger-fifo` | staggered and simultaneous modules under rotation and FIFO |
| `11-warmup-fifo` | FIFO warm up (18 s Gradle) before the FIFO comparisons |
| `14-kill-test-jvm`, `15-kill-pool`, `16-after-pool-crash` | the failure modes above |
| `17-idle-start`, `17-idle-stop`, `18-after-idle-single` | 8 s idle limit: pool gone 8 s after the run, no processes left; next single paid 18 s |
| `19-no-daemon`, `20-no-daemon-spawn` | `--no-daemon` reuses a live pool (10 s Gradle); a spawned pool outlives the build in the daemon's own group |

## Size

Framework (rule: non blank, non comment lines, imports included; the single JVM prototype measures 240 by this rule,
reported there as 217):

| File | Lines | Holds |
|---|---|---|
| `pool/Pool.kt` | 258 | main, lock, server, sessions, scheduler, boot, idle, disconnect |
| `pool/RunRecord.kt` | 85 | TestRun JSON (about 30) and the experiment report (about 30) |
| `pool/Wire.kt` | 10 | line format, file names |
| `client/PoolSession.kt` | 107 | connection, inboxes, HELLO, gone handling |
| `client/PoolLauncher.kt` | 56 | find or start, version hash, jar copy |
| `client/Requirement.kt` | 74 | compartment, `requirement()`, body runner |
| **Total** | **590** | about 2.5 times the single JVM prototype |

About 40 of those lines are experiment switches (FIFO mode, `dieAfterLeases`, `gv.delay.*`, the fairness report).
Gradle: one shared `game-test.gradle.kts` of 31 lines, 4 lines per module.

New concepts against the single JVM prototype: the pool process and its directory (`pool.lock`, `pool.port`,
`pool.log`, `versions/<hash>/`, `runs/<run>/`), the line protocol (HELLO, WELCOME, MISMATCH, SUBMIT, LEASE, RESULT,
VERDICT, END, ENDED, STOP), session (one per test JVM), run id, pool version, fair rotation across sessions, slot
reset after an abandoned lease, idle stop, `PoolGone`. Gone from the single JVM shape: nothing; `Requirement`,
`RequirementScope`, verdicts and the compartment remain, but the compartment now only opens and ends a session, so the
finish outcome check in Gradle is no longer needed for the report (an `END` failure still vanishes the same way).

## Surprises

- **The pool's life depends on whose process group it lands in.** Spawned from a test worker it inherits the group
  Gradle gives its daemon (also the single use one), which survives `xtask heavy`; the real design should detach on
  purpose (own session) instead of relying on Gradle's choice.
- **A version check is easy, a version policy is not.** A content hash refuses a stale pool reliably, but refusing
  means a code change to the pool makes every run fail until someone stops it. Replacing an idle pool automatically
  is the obvious next step and costs the 16 s boot. In the real framework the warm clients do not depend on the code
  under test, only the Paper side does, so the version that must match is the pool's protocol and client side, not
  the plugin under test.
- **FIFO looked fair until something arrived late.** Cold runs hide unfairness (everything queues during the boot);
  only a staggered or single requirement run shows it.
- **The run belongs to the pool, so a pool crash loses the report.** Writing the TestRun after every verdict, or
  keeping it in the test JVMs too, would keep a partial report.

## What this means for the search

- Test JVMs share a separate pool process (decided `pool-process`): modules and extensions share warm clients, and a
  single run takes 2 s, not 20 s. It replaces the root compilation of P2, which only worked inside one Gradle build.
- The real design needs: a deliberate detach, automatic replacement of a stale idle pool, a heartbeat or lease
  deadline, a report that survives a pool crash, and a short idle limit or explicit stop in CI.

## Rerun

The code lived on branch `proto/gv-pool-process` at commit `968f7babb` (`services/prototypes/gv-pool-process/` with
`pool`, `client`, `alpha`, `beta` and `combined` projects and a shared `game-test.gradle.kts`) and this branch is
deleted, so the commands are kept only as a record: from `services`, `./gradlew --parallel --continue
:gv-pool-alpha:gameTest :gv-pool-beta:gameTest` for the cold and warm runs, `:gv-pool-alpha:gameTest --tests
'|com.typewritermc.proto.gvpool.alpha.BankRequirements|BANK-3*'` for the single run, `-Pgv.pool.order=fifo`,
`-Pgv.bodyScale=10`, `-Pgv.delay.beta=1500`, `-Pgv.haltAt=CHAT-5`, `-Pgv.pool.dieAfterLeases=100` for the
experiments, `--no-daemon` for the CI shape, and `printf 'STOP\n' | nc 127.0.0.1 $(cat pool.port)` to stop the pool.

## Reuse

- `Pool.kt`: lock, server, sessions, fair scheduler, idle stop and disconnect handling.
- `PoolLauncher.kt` and `PoolSession.kt`: find or start, version hash, jar copy, the connection and its inboxes.
- `RunRecord.kt`: one TestRun record per run id.
- `Wire.kt`: the line protocol.
