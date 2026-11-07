# Topology spike: shared stepped Paper (A) against a Paper per attempt slot (B)

Question: how much slower is each Paper topology at 1,000 requirements on GitHub's free runner? Thresholds from the
developer: 10 percent slower is fine, 20 percent is rough, over 50 percent is a no go.

## Answer

- **B (a stepped Paper per attempt slot) is a no go once requirements claim groups.** Without groups B is 2.3 times
  *faster* than A. At 10 percent groups it is 4.9 times slower (+390 %), at 30 percent 8.8 times (+777 %), because every
  group claim moves clients between Papers (0.3 to 1.0 s per move, p50) and the move holds the Paper. Moving a group's
  clients at the same time did not help (moves are CPU bound on the runner).
- **With 1 percent restart requirements B is also no go at every group mix** (+41 %, +104 %, +182 % at 0, 10 and 30
  percent groups): B's restart boots compete with four stepped Papers and four clients for 4 vCPU (boot 9 to 32 s
  against 8 to 14 s in A).
- **A pays for async work globally.** One attempt's 50 to 150 ms of async work stops the tick for every attempt on the
  shared Paper: 10 to 26 s of other attempts' time per 1,000 requirements, about 100 ms each time an attempt is hit.
  That is why B wins at 0 percent groups.
- **Restarts dominate both.** 10 restart requirements (1 percent) take 82 to 89 percent of A's wall time; the other
  990 requirements are done after 20 to 27 s.
- **B-fresh (a fresh Paper per requirement) is not feasible**: a boot costs 22 to 39 CPU seconds, so 4 vCPU boot at most
  0.10 to 0.18 Papers a second; 1,000 requirements take 1.5 to 2.8 hours against A's 13 to 15 s.
- **Verdicts right**: 0 wrong in 36,000 requirements of the final run (3,600 deliberately broken, 4,776 group
  requirements, 3,600 with 50 to 150 ms async work, 180 restart requirements). Before the final run the rig had one
  false pass in 18,000 (a stale ack, see Surprises); fixed and rerun.

Machine: GitHub hosted `ubuntu-24.04`, x86, 4 vCPU, 16 GB, Vulkan on lavapipe, gated clients (render gate 2),
854x480, render distance 2, void world, Paper 26.3 build 242 with the step agent and a dynamic AppCDS archive
(159 MB, dumped and mapped with the agent). One job per repeat runs both topologies on the same runner with the same
seeds, order alternating with the repeat. Final run CPUs: jobs 0 and 1 AMD EPYC 7763, job 2 AMD EPYC 9V45. Load
average 6 to 19 on 4 vCPU during runs: the rig itself saturates the runner; nothing else ran. Measured unless marked
**inferred**.

Evidence:

| Run | What |
|---|---|
| [42345155973](https://github.com/gabber235/Typewriter/actions/runs/42345155973) | **final**: A against B with parallel moves, 3 jobs, 36 runs of 1,000, 0 wrong |
| [42339156447](https://github.com/gabber235/Typewriter/actions/runs/42339156447) | A against B with moves one after another, 3 jobs, 36 runs of 1,000, 0 wrong |
| [42342290365](https://github.com/gabber235/Typewriter/actions/runs/42342290365) | first parallel moves run: 1 false pass (stale ack) and 1 stalled client (clock switch race); superseded |
| [42336500003](https://github.com/gabber235/Typewriter/actions/runs/42336500003) | cancelled; job 1 holds the B run with 4 restarts at once and the archive not mapped |

Raw rows: artifact `h-topology-vulkan-X64-<repeat>`, file `topo.jsonl`, one summary row per run of 1,000.

## The workload

Synthetic requirements in the style of spikes D and N, generated from a seed (`topo.py generate`), the same seeds for
both topologies (seed = repeat + 1). Every requirement: full wipe of every claimed player (`k.wipe scope=full`, K's 17
kinds), the client watches a fresh token, one probe call as the stimulus (`n.att`), then the window check closed by the
E3t barrier (pass at the first step ack after the stimulus in which every member saw the token; fail once the
window's ticks have run with every member acked and quiet).

| Share | Kind |
|---|---|
| 1 percent | restart: K's reward scene (item given and saved, SIGKILL, boot, reconnect, item there exactly once) |
| 10 percent | async: Bukkit async work of 50 to 150 ms, then the chat line through a sync task, window 4 |
| rest, half | chat now, window 2 |
| rest, half | chat 1 to 8 ticks later, window late + 2 |
| 0, 10 or 30 percent of the non restart ones | group: 2 or 3 players, the token goes to every member |
| 10 percent, across all kinds | broken: the last member never gets the effect (restart: no save before the kill) |

Restarts are scheduled first (the longest work). The scheduler starts requirements in order as resources free up; a
normal requirement that cannot start holds its place (a group reserves the clients it waits for), a restart that
cannot start is passed over. Both topologies run one restart at a time (A has one extra Paper; B is capped, see
Surprises). 99 warm up requirements run on each rig before the measured runs.

## Overhead of B against A (final run)

Per job, same runner and seed; median of 3 jobs (range). Wall time for 1,000 requirements.

| Restarts | Groups | A wall s | B wall s | B against A | Verdict |
|---|---|---|---|---|---|
| 0 | 0 % | 14.0 (12.8 to 14.7) | 6.0 (4.4 to 6.1) | **−59 %** (−66 to −56) | B faster |
| 0 | 10 % | 14.9 (14.1 to 15.2) | 73.1 (40.4 to 84.3) | **+390 %** (+186 to +454) | no go |
| 0 | 30 % | 17.3 (15.3 to 17.6) | 151.6 (89.2 to 159.8) | **+777 %** (+482 to +810) | no go |
| 1 % | 0 % | 217.8 (124.8 to 222.9) | 307.2 (128.9 to 426.4) | **+41 %** (+3 to +91) | rough to no go |
| 1 % | 10 % | 197.2 (119.6 to 202.9) | 401.9 (193.9 to 532.7) | **+104 %** (+62 to +163) | no go |
| 1 % | 30 % | 200.0 (125.9 to 202.9) | 572.2 (252.2 to 580.5) | **+182 %** (+100 to +190) | no go |

The fast EPYC 9V45 job is always the low end of B's range; the overhead holds on every CPU.

### B with moves one after another (run 42339156447)

| Restarts | Groups | A wall s | B wall s | B against A |
|---|---|---|---|---|
| 0 | 0 % | 13.7 (11.9 to 13.8) | 5.1 (4.3 to 5.8) | −63 % (−64 to −58) |
| 0 | 10 % | 13.9 (12.8 to 14.8) | 70.7 (43.8 to 77.2) | +407 % (+242 to +421) |
| 0 | 30 % | 16.6 (13.8 to 16.8) | 137.0 (83.6 to 158.4) | +716 % (+506 to +853) |
| 1 % | 0 % | 187.9 (128.1 to 217.6) | 293.5 (106.2 to 368.2) | +35 % (−17 to +96) |
| 1 % | 10 % | 175.2 (115.5 to 198.1) | 396.7 (189.5 to 457.8) | +100 % (+64 to +161) |
| 1 % | 30 % | 172.8 (104.4 to 196.5) | 494.3 (228.9 to 556.9) | +186 % (+119 to +186) |

CPUs EPYC 7763, 9V74, 9V45. Parallel moves change nothing beyond the noise: a move draws the client until ready
(lavapipe, CPU) and several at once only share the same 4 vCPU.

## Requirement time (final run)

Milliseconds from the moment the requirement starts (claim) to its verdict, moves and restarts included. Median of the
3 jobs' p50 and p95.

| Restarts | Groups | A p50 | A p95 | B p50 | B p95 |
|---|---|---|---|---|---|
| 0 | 0 % | 23 | 174 | 11 | 109 |
| 0 | 10 % | 22 | 157 | 20 | 1,034 |
| 0 | 30 % | 18 | 152 | 25 | 1,306 |
| 1 % | 0 % | 46 | 196 | 31 | 137 |
| 1 % | 10 % | 35 | 173 | 28 | 1,694 |
| 1 % | 30 % | 30 | 159 | 27 | 1,462 |

- A's p95 is the async kinds (async p50 120 to 140 ms, p95 180 to 270 ms: the work itself plus waits on other
  attempts' async work). A group requirement costs the same as a single one (p50 17 to 39 ms).
- B's p95 with groups is the moves: group requirements p50 0.03 to 1.4 s, p95 0.8 to 3.0 s; singles that move away
  from a crowded Paper or wait behind a group have p95 0.3 to 0.9 s; async requirements wait behind moves too (p95 up to
  2.1 s).
- Restart requirements p50: A 11.4 to 20.8 s (boot 7.7 to 14.0 s), B 11.8 to 41.7 s (boot 9.1 to 31.8 s).

## Moves, boots and memory (final run)

| Measure | Value |
|---|---|
| Move a client between stepped Papers (B: leave like the pause menu, connect, facts ready, step again) | p50 0.33 to 0.95 s, p95 0.53 to 2.55 s |
| Move a client to the unstepped extra Paper or back (A restart) | p50 0.56 to 1.42 s, p95 0.9 to 4.6 s |
| Boot of 4 Papers in parallel (B setup) | 27.2 s (9V45), 39.4 and 39.9 s (7763); each 26 to 39 CPU s |
| Boot of 2 Papers in parallel (A setup) | 11.4 s (9V45), 18.2 and 18.6 s (7763); each 22 to 35 CPU s |
| Restart boot while the other attempts run | A 7.7 to 14.0 s, B 9.1 to 31.8 s (p50 per run) |
| Kill to ready (facts) | A 9.8 to 17.7 s, B 11.4 to 39.1 s |
| Paper RSS after boot | 0.83 to 0.86 GB |
| Client RSS | 1.35 to 1.50 GB |
| **Peak memory used, whole runner** (MemTotal − MemAvailable) | **A 8.3 to 8.5 GB, B 10.1 to 11.1 GB** of 16 |
| Busy vCPU over a run, no restarts | A 1.4 to 2.0, B 2.7 to 3.5 |
| Busy vCPU over a run with restarts | A 3.6 to 3.8, B 3.6 to 4.0 |

## A: time lost to another attempt's async work (final run)

The step policy attributes every idle pass between ticks to each running attempt: its own member lags or is busy,
or another attempt's member is busy (lost to async) or lags (lost to ack). Totals per run of 1,000.

| Run | Lost to others' async, total s | Attempts hit | Loss per attempt hit, median ms | Lost to others' acks, total s | Own async wait, total s |
|---|---|---|---|---|---|
| no restarts, 0 % groups | 24.8 to 26.2 | 240 to 253 | 95 to 105 | 2.3 to 3.9 | 9.3 to 9.9 |
| no restarts, 10 % groups | 21.2 to 22.7 | 213 to 215 | 94 to 98 | 1.9 to 2.7 | 9.3 to 9.8 |
| no restarts, 30 % groups | 13.6 to 14.6 | 131 to 147 | 93 to 100 | 1.3 to 1.9 | 9.6 to 9.9 |
| 1 % restarts, 0 % groups | 17.0 to 17.4 | 177 to 190 | 88 to 99 | 4.5 to 7.3 | 9.1 to 9.5 |
| 1 % restarts, 30 % groups | 9.5 to 10.2 | 102 to 108 | 90 to 93 | 1.8 to 2.9 | 9.3 to 9.5 |

- The totals add over attempts that run at the same time, so they exceed wall time. On wall time: the 100 async
  requirements (about 100 ms each) stop the shared Paper for about 10 s, most of A's 13 to 17 s.
- Groups lower the loss because fewer attempts run at once (a group claims 2 or 3 of the 4 clients).
- Waiting on other clients' acks costs little (1 to 7 s summed per 1,000).
- On a shared Paper this loss shrinks only by keeping async work from holding the tick, or by running async heavy
  requirements on their own Paper (**inferred**).

## B-fresh: a fresh Paper per requirement, booted ahead (computed, not built)

Inputs, final run on the runner (4 vCPU, 16 GB): boot costs 22 to 39 CPU s per Paper (22 to 27 on the 9V45, 35 to 39 on
the 7763); 2 Papers boot together in 11 to 19 s wall, 4 in 27 to 40 s; Paper RSS 0.85 GB; 4 clients 5.6 GB; joining a
new Paper 0.3 to 1.0 s per client.

Little's law: booters in flight = rate × boot wall time; boot CPU = rate × CPU seconds per boot.

| Target | Rate | CPU for boots | Booters in flight (at 12 s each) | Memory for them |
|---|---|---|---|---|
| Match A, no restarts (1,000 in 14 s) | 71 per s | 1,560 to 2,770 vCPU | about 850 | about 720 GB |
| Match A with 1 % restarts (1,000 in 200 s) | 5 per s | 110 to 195 vCPU | about 60 | about 51 GB |
| Everything the runner has | 4 vCPU / 22 to 39 CPU s | 0.10 to 0.18 boots per s | 2 to 3 | 2 to 3 GB |

On the free runner B-fresh is CPU bound at 0.10 to 0.18 requirements a second: 1,000 requirements take **1.5 to 2.8
hours** (restarts come free, since every Paper is fresh), against 13 to 15 s for A without restarts and 2 to 4 minutes
with them. Memory is not the limit (16 GB holds about 12 Papers next to 4 clients); boot CPU is. Inferred from the
measured boot cost: a Paper boot would have to get 100 to 1,000 times cheaper to matter.

## Complexity cost

Non blank, non comment lines of the throwaway rig (`orchestrator/topo.py`, `probe-plugin/.../N.java`).

| Part | Shared by both | A only | B only |
|---|---|---|---|
| Step policy widened from one subject to a set of attempts (`N.java` hook, finish, attempt registration) | about 115 (50 before) | | |
| Idle keepalive tick (a Paper with no attempt still ticks once a second) | 8 | never triggered in practice (S always runs attempts) | required: idle Papers hit Paper's 60 s watchdog |
| Requirement body, move, restart scene, Paper wrapper | 90 | | |
| Scheduler and rig base | 95 | | |
| Topology class (claims, placement, restart handling) | | 61 | 88 |

Concepts each needs:

- **A**: one tick stream for all attempts; every claimed client acks every tick; every claimed player's async work
  holds everyone; an extra unstepped Paper for restarts, with a move out and back; auto ticks while a client joins.
- **B**: everything in A's policy (a group of k players still shares one Paper's ticks), plus a client location map,
  the placement rule (free Paper with the most free clients, move the rest), clients riding along when a restart kills
  their Paper, the idle keepalive tick, a cap on restarts at once, and stepping off and on around a restart in place.

## Surprises

- **Without groups B beats A by 2.3 times.** Sharing costs little in ticks or acks; it costs async work, because one
  attempt's 100 ms stops every attempt.
- **Four restart boots at once are slower than one after another.** Uncapped, B started 4 restarts together: boot 61
  to 77 s each (run 42336500003 job 1, Xeon 8370C, archive not mapped), against 12 to 14 s for one. Boot is CPU bound
  (22 to 39 CPU s), so 4 vCPU give no gain from parallel boots. The measured B runs one restart at a time.
- **An idle stepped Paper dies after 60 s.** With no attempt nothing grants a tick, so Paper's watchdog stops the
  server and keepalives stop too. B's first CI run lost every Paper this way. Fix: one tick per second while no
  attempt runs.
- **A stale step ack passed a broken requirement** (1 in 18,000, run 42342290365): the previous attempt's last ack
  (it saw the previous token) arrived after the next attempt registered and counted for it. Rule: count only acks of
  ticks after the stimulus. Final run: 0 wrong in 36,000.
- **Switching the client's virtual clock from another thread can freeze it** (1 of 24 client step ons, run
  42342290365, and once on the Mac): the client never ticked its first step (`steps 0, queued 2`). Inferred cause: a
  frame in flight read the real clock after the virtual one was fixed, so the first step gives less than one tick and
  no further step is taken while it waits. Switching on the render thread between frames fixed it (0 stalls in the
  final run); the cause was not traced further.
- **The AppCDS archive did not map with the agent.** Dumping with a Java agent needs
  `-XX:+UnlockDiagnosticVMOptions -XX:+AllowArchivingWithJavaAgent`, and the same flags at run time, or `-Xshare:auto`
  drops the archive silently (boot 7.5 s against 5.1 s on the Mac).
- **Boot CPU is 22 to 39 s per Paper on the runner** even with the archive mapped. The fleet varies a lot: the EPYC
  9V45 ran restarts about twice as fast as the 7763, and decides the low end of most ranges.
- **Restarts are 1 percent of requirements and 82 to 89 percent of A's wall time.** Whatever topology wins, restart
  requirements decide suite time; a second extra Paper would roughly halve that part for A (**inferred**).

## Rerun

Build from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :step-agent:jar :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, `SDL_MAC_BACKGROUND_APP=1`, one at a time:

```
python3 orchestrator/run.py prepare
python3 orchestrator/topo.py prep
python3 orchestrator/topo.py run --topo A --n 1000 --mixes 0,0.1,0.3 --restart 0.01,0 --seed 1
python3 orchestrator/topo.py run --topo B --n 1000 --mixes 0,0.1,0.3 --restart 0.01,0 --seed 1 --parallel-moves 1
python3 orchestrator/topo_report.py runs/topo.jsonl
```

CI: matrix rows `{ plan: topology, backend: vulkan, runner: ubuntu-24.04, repeat: 0|1|2 }` run
`orchestrator/ci.py plan topology` (both topologies, order alternating with the repeat).

Mac development runs (M1 Max, load 9 to 15 with another worktree's spike running) only checked that both topologies
work; no Mac number is used above.
