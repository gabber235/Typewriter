# I: coverage per requirement on a long lived Paper

## Answer

- **Yes, and it is free.** The JaCoCo agent on Paper with `includes=probe.plugin.*`, plus one in process call at the end of each requirement (`RT.getAgent().getExecutionData(true)`, read and reset), costs **21 to 53 µs on the main thread** per requirement. That is below the noise of the requirement itself: on the runner R4 direct gated stays at **5.0 to 5.1 ms** and R4 tick at rate 200 at **10.0 ms**, agent on or off.
- **Attribution is exact for synchronous work**: 3000 of 3000 requirements held their own path and no neighbour's, on the Mac and the runner.
- **Late work is the trap, and a cheap barrier fixes most of it.** A tail one tick later or on a Bukkit async task lands in the next requirement **62 to 92 times out of 100** with a naive dump. Dumping only when the plugin's scheduler is quiet (no one shot task pending, no async worker running) gave **0 wrong in 2100**, at 0.1 to 0.5 ms per requirement. It does not see work on a raw thread pool: **94 of 100** wrong with a 20 ms raw tail.
- **Recommended: I3, the in process API at the requirement's end, behind a quiet barrier.** Typewriter's own async work must run through something the barrier can count. Reject I1 over TCP (40 ms per requirement on Linux) and I2 (nothing to save).
- Downstream is cheap too: 155 bytes of exec data per requirement, about 0.5 KB of lines as JSON, 2.1 to 2.8 s to turn 1000 dumps into lines, and **under 6 ms to intersect 1000 requirements with a diff**.

Machines. Mac: M1 Max, 10 cores, JBR 25.0.3, OpenGL on Metal, heavily loaded by other work (1 minute load 18 to 178, stated per row). Runner: run [42162248604](https://github.com/gabber235/Typewriter/actions/runs/42162248604), `ubuntu-24.04`, AMD EPYC 7763, 4 vCPU, Temurin 25.0.5, Vulkan through lavapipe, load 2 to 5. JaCoCo 0.8.14 from Maven Central through Gradle. Every requirement is spike C's R4: act, observe through the barrier, reset, clear chat, state check. n = 1000 unless stated. Every number is measured unless marked inferred.

## Candidates

| Id | What | Per requirement cost | Verdict |
|---|---|---|---|
| I1 | Agent `output=tcpserver`, orchestrator sends dump with reset over JaCoCo's socket protocol | **40.8 ms** on the runner, 0.3 to 0.8 ms on the Mac | Rejected for CI |
| I2 | In process dump every 10 requirements, rerun a group that touches the diff | Same as I3 within noise | Nothing to save |
| **I3** | In process `RT.getAgent().getExecutionData(true)` from the plugin, on the main thread, folded into the cleanup command | **21 to 53 µs** | **Recommended** |

Precedent: Teamscale's Java profiler has a "testwise" mode that does exactly this, a JaCoCo dump and reset between `/test/start` and `/test/end` HTTP calls ([docs](https://docs.teamscale.com/reference/coverage-profilers/teamscale-java-profiler/testwise-coverage-recording/)). Android ships a JVMTI agent that does JaCoCo reset, run, dump on a live process ([dump coverage](https://android.googlesource.com/platform/frameworks/base/+/e6bf1d16cb10/tools/dump-coverage/README.md)). Neither says how to handle work that outlives the test; that part is measured here.

## Evidence

### Overhead per requirement

Seconds per requirement, median and p95. "agent" loads the agent and never dumps; "rt" is I3; "grp10" is I2's dump cost.

**Runner**, load 2 to 5:

| Recipe | off | agent | rt (I3) | tcp (I1) | rt grp10 (I2) |
|---|---|---|---|---|---|
| R4 direct gated | 0.0050, 0.0051 (p95 0.0072, 0.0076) | 0.0050 | 0.0051, 0.0051 (p95 0.0069, 0.0073) | **0.0459** | 0.0052 |
| R4 tick rate 200 gated | 0.0100, 0.0100 (p95 0.0117, 0.0122) | 0.0100 | 0.0100, 0.0100 (p95 0.0124) | **0.0500** | 0.0100 |

**Mac**, two rounds, load in brackets:

| Recipe | off | agent | rt (I3) | tcp (I1) | rt grp10 (I2) |
|---|---|---|---|---|---|
| R4 direct gated, round 1 | 0.0077 (69) | 0.0073 (57) | 0.0074 (58) | 0.0070 (46) | 0.0070 (41) |
| R4 direct gated, round 2 | 0.0061 (38) | 0.0064 (31) | 0.0070 (23) | 0.0072 (23) | 0.0065 (21) |
| R4 tick rate 200 gated, round 1 | 0.0111 (41) | 0.0109 (38) | 0.0108 (57) | 0.0119 (57) | 0.0105 (42) |
| R4 tick rate 200 gated, round 2 | 0.0108 (19) | 0.0114 (18) | 0.0115, 0.0116 (22) | 0.0134 (23) | 0.0108 (18) |

| What the dump itself costs | Runner | Mac |
|---|---|---|
| `getExecutionData(true)` on the main thread, median | 21 to 34 µs | 44 to 53 µs |
| Same, p95 | not kept | 99 to 366 µs |
| TCP dump round trip, median | **40.8 ms** (min 0.8) | 0.29 to 0.77 ms |
| Server CPU, off against rt | 44 to 56 percent, same | 34 to 56 percent, same |
| Server RSS, off against rt | 880 to 919 MB against 897 to 935 MB | no difference |

- The Mac spread between rounds (6.1 to 7.7 ms for the same "off") is larger than any difference between columns. The runner is the clean measurement: **no measurable overhead for I3**.
- TCP costs exactly the Linux delayed ACK time on every dump. Inference: JaCoCo's agent writes the reply in several small writes without `TCP_NODELAY`, so Nagle waits for the client's delayed ACK. Not fixable from the client side. Mac TCP uses a different delayed ACK, hence 0.3 ms.
- Group dumps (I2) cost 80 to 110 µs each instead of 21 to 53 µs: fewer calls, so less warm. Either way it is microseconds. I2 would only add reruns.

### Paper boot

Wall seconds to `Done`, Paper alone, void world, three boots.

| Agent | Runner | Mac | Instrumented classes | Exec bytes per dump |
|---|---|---|---|---|
| none | 13.48, 13.62, 15.70 | 9.14, 11.37, 11.45 (load 23 to 25) | 0 | |
| `includes=probe.plugin.*` | 13.18, 13.68, 14.03 | 9.41, 10.29, 12.38 (load 22 to 23) | 4 at boot, 7 after the loop | **155** |
| `includes=*` | **19.87** | **15.06, 17.86** (load 24 to 26) | **12931 to 12944** | **22146 to 22287** |

### What the include filter changes

| `includes` | Boot | R4 direct gated | R4 tick rate 200 gated | Dump on main thread |
|---|---|---|---|---|
| `probe.plugin.*` | no change | 5.1 ms runner, 7.0 ms Mac | 10.0 ms runner, 11.5 ms Mac | 21 to 53 µs |
| `*` (all of Paper and Minecraft) | **+6.2 s** runner, about +5 s Mac | **7.6 ms** runner (n 200), 9.8 ms Mac | 15.2 ms Mac (n 200) | **1.9 ms** runner, 2.4 ms Mac (p95 4.0) |

- The agent sees every class load either way; the filter decides what gets probes. With the plugin's own packages only, the agent is invisible. Instrumenting the server costs boot time, about 50 percent per requirement, and 140 times the dump size.
- So `includes` must name Typewriter's packages only, and must exclude the verification framework's own code, see "Surprises".

### Attribution

Each requirement kind runs its own code. `title`, `chat`, `block`, `entity` are the four cases of `Speed.act` (1, 1, 4 and 13 lines with instructions). The trap kinds show a chat line at once and then run a tail of 3 lines in `Coverage.java`: `tailTick` one tick later through the Bukkit scheduler, `tailAsync` on a Bukkit async task, `tailRaw` on `CompletableFuture.runAsync` (the common pool). Async tails sleep 2 ms (or 20 ms) before their lines. A requirement is wrong when its own lines are missing from its dump; the same lines then appear in a later requirement's dump.

**Synchronous kinds, naive dump at cleanup:**

| Run | Requirements | Own path missing | Neighbour's path present |
|---|---|---|---|
| Runner, R4 tick rate 200, I3 | 1000 | 0 | 0 |
| Mac, R4 tick rate 200, I3, load 22 | 1000 | 0 | 0 |
| Mac, R4 direct, I1 over TCP, load 26 | 1000 | 0 | 0 |

**Trap kinds**, 700 requirements per row, 100 per kind. Wrong out of 100:

| Dump barrier | Recipe | Machine, load | tailTick | tailAsync | tailRaw 2 ms | tailRaw 20 ms | Wait added per requirement |
|---|---|---|---|---|---|---|---|
| Naive, at cleanup | direct 20 TPS | Mac, 67 | **80** | **86** | 18 | | 0 |
| Naive | direct 20 TPS | Runner, 4.5 | **92** | **89** | 4 | | 0 |
| Naive | tick rate 200 | Mac, 178 | **68** | **62** | 2 | | 0 |
| Naive | direct 20 TPS | Mac, 87 | 82 | 89 | | **99** | 0 |
| Wait 1 tick | direct 20 TPS | Mac, 68 | 0 | **100** | 0 | | 42 ms |
| Wait 1 tick | tick rate 200 | Mac, 88 | 0 | 0 | 0 | | 1.7 ms |
| Wait 2 ticks | direct 20 TPS | Mac, 61 | 0 | 0 | 0 | | **92 ms** |
| Wait 2 ticks | tick rate 200 | Mac, 75 | 0 | 0 | 0 | | 6.8 ms |
| **Quiet scheduler** | direct 20 TPS | Mac, 53 | **0** | **0** | 0 | | 0.5 ms median |
| **Quiet scheduler** | direct 20 TPS | Runner, 4.7 | **0** | **0** | 0 | | 0.09 ms median |
| **Quiet scheduler** | tick rate 200 | Mac, 76 | **0** | **0** | 0 | | 0.3 ms median |
| Quiet scheduler | direct 20 TPS | Mac, 96 | 0 | 0 | | **94** | 0.3 ms median |

- **Where late work lands**: in whichever requirement runs when it finishes, 1 to 3 requirements later at 20 TPS direct (a requirement takes 6 ms, a tick 50 ms). Wrong lines are both missing from the right requirement and present in the wrong one: a diff in a tail would select the wrong clip, and miss the right one.
- **Bukkit async tasks start at the next tick**, not when scheduled. That is why one tick of waiting misses every `tailAsync` at 20 TPS: the async task and the waiting dump start on the same tick, and the dump wins.
- **The quiet barrier** (`Coverage.busy`): this plugin's pending tasks with no repeat period, plus its active async workers, polled with `MinecraftServer.execute` every 0.2 ms; dump in the same main thread runnable that saw zero. Requirements without a tail pay 0.1 to 0.5 ms; a requirement with a tail pays until its tail ends (at 20 TPS on the runner: `tailTick` 28 ms, `tailAsync` 46 ms; Mac 31 and 63 ms). It is correct by construction for anything that goes through the Bukkit scheduler.
- **A fixed window is fragile**: it is right only when the window is longer than the tail, and at 20 TPS each tick of window costs 50 ms for every requirement. The quiet barrier waits only when there is something to wait for.
- **Raw threads are invisible** to any scheduler barrier. A 2 ms raw tail mostly finished before cleanup by luck (2 to 18 wrong); a 20 ms one was wrong 94 to 99 times. Repeating tasks are also excluded by design (a timer never ends), so a timer started by a requirement is attributed to whoever runs when it fires. Not measured: Kotlin coroutines. Inference: a Typewriter dispatcher on its own executor is as invisible as `tailRaw` unless the barrier can count its jobs.

### Report size and the intersect

| What | Runner | Mac |
|---|---|---|
| Exec bytes per requirement (I3, 7 plugin classes) | 155 | 155 |
| Exec bytes per requirement over TCP | 124 | 130 |
| Covered lines per requirement, base kinds | 78 to 92 | 72 to 92 |
| Lines as JSON per requirement | 438 to 508 bytes | 388 to 508 bytes |
| Dumps to lines, whole run (one JVM, JaCoCo core, 7 classes) | 2.18 s for 1000; 2.47 s for 700 | 2.75 s for 1000 |
| Same, per dump median, p95 | 1.7, 3.4 ms | 2.0, 4.6 ms |

Intersect, in Python, sets per file, on the runner's line files. Measured on the Mac.

| Fake diff | Requirements | Touched | Time |
|---|---|---|---|
| `case "block"` in `Speed.act` | 1000 base | 250 (all block requirements, nothing else) | 0.9 ms |
| `tailTick` body | 1000 base | 0 | 0.5 ms |
| `reset` method (shared by every requirement) | 1000 base | 1000 | 5.9 ms |
| `tailTick` body, naive dump | 700 trap | **72, several of them the wrong ones** | 0.3 ms |
| `tailTick` body, quiet barrier | 700 trap | **100, exactly the `tailTick` requirements** | 0.4 ms |
| Building the sets once | 1000 | | 9 ms |

## Surprises

1. **Paper hands the agent different bytes than the plugin jar.** `Speed.class` is 30635 bytes in both, with 2770 bytes changed; `ProbeAccess`, which touches no Bukkit API, is identical. Inference: Paper's plugin bytecode rewriting. JaCoCo matches classes by a CRC of their bytes, so a report built from the jar would find no matches. The reader uses the agent's `classdumpdir` instead; any real setup must too.
2. **TCP dump costs 40 ms on Linux and 0.3 ms on the Mac.** The same code on the Mac would have recommended I1.
3. **Bukkit async tasks start at the next tick**, which defeats a one tick window.
4. **The harness's own code is covered.** The quiet barrier's 30 lines, the line socket, and every dispatcher a command passes through show up in every requirement: a fake diff to `Golden.java`, a file no requirement uses, touched 300 of 700 trap requirements because the command chain falls through `Golden.run`. The framework must live outside `includes`, and shared plumbing inside Typewriter selects every requirement it serves.
5. A diff in shared code (`reset`) touches every requirement. Correct, but the clip rule needs a cap or a "too many" summary.

## What this means for the search (for the README keeper)

- **The clip rule is affordable.** Coverage per requirement adds nothing measurable to the 5 to 10 ms loop on the runner, a few seconds of offline reading per 1000 requirements, and milliseconds to intersect. It can run on every pull request and in the gated suite, not only in a demo rerun.
- **The design: agent with `includes` limited to Typewriter's packages and `classdumpdir`; one in process read and reset at the end of each requirement; the dump waits for a quiet barrier.** No TCP, no groups, no reruns.
- **The barrier is the same problem spike C found for verdicts.** C: "the framework needs to know a behaviour has finished". Coverage makes it concrete and measurable: everything Typewriter starts must be countable by the barrier. The scheduler is countable today; Typewriter's coroutine dispatchers and any raw executors must be wrapped or replaced so their running jobs can be counted. That is a requirement on v1's runtime design, worth stating before it is built.
- **E** (when is a step done): the quiet barrier is a candidate for E as well. A requirement ends when the plugin is quiet, not after a fixed window. Same signal for "no late effects" and for "coverage closed".
- **D** (several clients): the agent's probes are global to the JVM. Two requirements running at once on one Paper cannot be told apart by coverage. Parallel requirements need one Paper each (D3), or coverage only in a sequential run. Inference, not measured.
- **Timers**: a repeating task started by a requirement is never quiet. Requirements that start one must stop it in cleanup, or the barrier must treat it as part of the requirement until cancelled.

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar :coverage-tool:writeCoverageTool'
```

Then, with `C=prototypes/game-verification/orchestrator/coverage.py` and `SDL_MAC_BACKGROUND_APP=1`:

```
python3 $C loop --cov off --n 1000 --dispatch direct                      # baseline, R4 direct gated
python3 $C loop --cov rt  --n 1000 --dispatch tick --rate 200 --analyze   # I3, plus lines and attribution
python3 $C loop --cov tcp --n 1000 --dispatch direct                      # I1
python3 $C loop --cov rt  --n 1000 --group 10                             # I2 dump cost
python3 $C loop --cov rt  --n 200 --includes '*'                          # everything instrumented
python3 $C loop --cov rt  --n 700 --kinds trap --analyze --barrier naive|wait:1|wait:2|quiet [--tail-ms 20]
python3 $C boot --cov off|agent --repeat 3 [--includes '*']
python3 $C intersect prototypes/game-verification/runs/i-coverage/<run>-lines.jsonl
```

`loop` flags: `--cov off|agent|rt|tcp`, `--dispatch direct|tick`, `--rate`, `--gate` (default 2), `--group`, `--barrier`, `--kinds base|trap`, `--includes`, `--tail-ms`, `--analyze`. Results append to `runs/i-coverage.jsonl`; exec dumps, class dumps and line files go to `runs/i-coverage/`. A run with `--includes '*'` leaves about 100 MB of class dumps there.

CI: the matrix row `{ plan: coverage, backend: vulkan, runner: ubuntu-24.04, repeat: 0 }` runs boots, both recipes with off, agent, rt, tcp, off, rt, group 10, the trap with naive and quiet, an analysed run and `includes=*`. 17 min. The workflow is left with one `smoke` row.

## Reuse

- `probe-plugin/.../Coverage.java`: `dump(id)` (reflection on `org.jacoco.agent.rt.RT` from the system class loader), `cov=ID` on any line command, `covDump?id=&wait=K|quiet=1` handled on the socket thread, `busy()` (this plugin's one shot tasks plus async workers), `covSave?dir=`, trap command `tail?kind=tailTick|tailAsync|tailRaw&tailMs=`.
- `coverage-tool/`: Gradle fetches the agent jar and JaCoCo core; `writeCoverageTool` writes `build/coverage-tool.json` (agent path, reader classpath). `probe.cov.Lines classDumpDir execDir out.jsonl` reads one exec per requirement and writes covered lines keyed `package/SourceFile.java`, the key xtask's JaCoCo reader uses (`xtask/src/review/coverage.rs`, `read_jacoco`), with the same rule: a line ran when any of its instructions ran.
- `orchestrator/coverage.py`: `JacocoTcp` (JaCoCo's remote dump protocol in 50 lines of Python), `agent_jvm`, `paths()` (each kind's own lines from the source), `analyze` (own path missing, foreign path present), `cmd_intersect`. `ci.py` has `run_cov` and `cmd_coverage`.
- Not done: reading probes to lines without a JVM. A probe to line map built once per class would make the reader trivial; JaCoCo has no public API for it.
