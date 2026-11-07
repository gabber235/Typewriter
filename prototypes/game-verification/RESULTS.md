# Topology spike: shared stepped Paper (A) against a Paper per attempt slot (B)

Question: how much slower is each Paper topology at 1,000 requirements on GitHub's free runner? Thresholds from the
developer: 10 percent slower is fine, 20 percent is rough, over 50 percent is a no go.

## Answer

- **B (a stepped Paper per attempt slot) is a no go as soon as requirements claim groups.** Without groups B is
  2.7 times *faster* than A, but at 10 percent groups it is 4 to 5 times slower and at 30 percent 6 to 9 times
  slower, because every group claim moves clients between Papers (0.3 to 0.8 s per move) and the move holds the
  Paper. Parallel moves: see "B with parallel moves" below.
- **A (one shared stepped Paper) pays for async work globally.** One attempt's 50 to 150 ms async work stops the
  tick for every attempt on the Paper: 9.5 to 27 s of other attempts' time lost per 1,000 requirements, which is
  most of A's 12 to 17 s wall time. That is why B wins at 0 percent groups.
- **Restarts dominate both.** 10 restart requirements (1 percent) take 104 to 218 s of a run whose other 990
  requirements finish in 20 to 26 s (A). B's restart boots are 1.5 to 2 times slower than A's (21 to 31 s against
  12 to 14 s): four stepped Papers and four clients compete with the boot for 4 vCPU.
- **B-fresh (a fresh Paper per requirement) is not feasible**: a Paper boot costs 22 to 36 CPU seconds, so 4 vCPU boot
  at most 0.11 to 0.18 Papers a second; 1,000 requirements take 1.5 to 2.5 hours against A's 14 s (see B-fresh).
- **Verdicts stayed right everywhere**: 0 wrong in 36,000 CI requirements of run 42339156447 (3,600 deliberately
  broken, 4,776 group requirements, 3,600 with 50 to 150 ms async work, 180 restart requirements of which only 8
  broken: the broken draw is spread over all kinds, so restart verdicts lean on spike K's 0 wrong).

Machine: GitHub hosted `ubuntu-24.04`, x86, 4 vCPU, 16 GB, Vulkan on lavapipe, gated clients (render gate 2),
854x480, render distance 2, void world, Paper 26.3 build 242 with the step agent and a dynamic AppCDS archive
(159 MB, dumped with the agent). One job per repeat ran both topologies on the same runner with the same seeds,
order alternating with the repeat. CPUs: job 0 AMD EPYC 7763, job 1 AMD EPYC 9V74, job 2 AMD EPYC 9V45. Load
average during runs 6.6 to 13.4 (4 vCPU, so the runner was saturated by the rig itself; nothing else ran).
Measured unless marked **inferred**.

Evidence: run [42339156447](https://github.com/gabber235/Typewriter/actions/runs/42339156447) (main, 36 runs of
1,000), run [42342290365](https://github.com/gabber235/Typewriter/actions/runs/42342290365) (B with parallel moves),
run [42336500003](https://github.com/gabber235/Typewriter/actions/runs/42336500003) (cancelled; job 1 holds the
uncapped B restart run). Raw rows: artifact `h-topology-vulkan-X64-<repeat>`, file `topo.jsonl`.

## The workload

Synthetic requirements in the style of spikes D and N, generated from a seed (`topo.py generate`), same seeds for
both topologies. Every requirement: full wipe of every claimed player (`k.wipe scope=full`, K's 17 kinds), the
client watches a fresh token, one probe call as the stimulus, then the window check closed by the E3t barrier (pass at
the first step ack in which every member saw the token; fail once the window's ticks have run with every member
acked and quiet).

| Share | Kind |
|---|---|
| 1 percent | restart: K's reward scene (item given and saved, SIGKILL, boot, reconnect, item there exactly once) |
| 10 percent | async: Bukkit async work of 50 to 150 ms, then the chat line through a sync task, window 4 |
| rest, half | chat now, window 2 |
| rest, half | chat 1 to 8 ticks later, window late + 2 |
| 0, 10 or 30 percent of the non restart ones | group: 2 or 3 players, the token goes to every member |
| 10 percent, across all kinds | broken: the last member never gets the effect (restart: no save before the kill) |

Restarts are scheduled first (the longest work). The scheduler starts requirements in order as resources free up; a
normal requirement that cannot start holds its place, a restart that cannot start is passed over. A warm up of 99
requirements ran before the measured runs on each rig.

## Overhead of B against A

Per job, same runner and seed; median of 3 jobs (range). Wall time for 1,000 requirements.

| Restarts | Groups | A wall s, median (range) | B wall s, median (range) | B against A, median (range) | Verdict |
|---|---|---|---|---|---|
| 0 | 0 percent | 13.7 (11.9 to 13.8) | 5.1 (4.3 to 5.8) | **−63 %** (−64 to −58) | B faster |
| 0 | 10 percent | 13.9 (12.8 to 14.8) | 70.7 (43.8 to 77.2) | **+407 %** (+242 to +421) | no go |
| 0 | 30 percent | 16.6 (13.8 to 16.8) | 137.0 (83.6 to 158.4) | **+716 %** (+506 to +853) | no go |
| 1 percent | 0 percent | 187.9 (128.1 to 217.6) | 293.5 (106.2 to 368.2) | **+35 %** (−17 to +96) | rough to no go |
| 1 percent | 10 percent | 175.2 (115.5 to 198.1) | 396.7 (189.5 to 457.8) | **+100 %** (+64 to +161) | no go |
| 1 percent | 30 percent | 172.8 (104.4 to 196.5) | 494.3 (228.9 to 556.9) | **+186 %** (+119 to +186) | no go |

B here moves the clients of one group claim one after another and runs one restart at a time. 0 wrong verdicts in
every cell.

PARALLEL_MOVES_SECTION

## Requirement time

Seconds from the moment the requirement starts (claim) to its verdict, moves and restart included. Median of the
3 jobs' p50 and p95.

| Restarts | Groups | A p50 | A p95 | B p50 | B p95 |
|---|---|---|---|---|---|
| 0 | 0 % | 0.022 | 0.160 | 0.008 | 0.108 |
| 0 | 10 % | 0.019 | 0.152 | 0.017 | 0.882 |
| 0 | 30 % | 0.017 | 0.149 | 0.019 | 1.114 |
| 1 % | 0 % | 0.045 | 0.193 | 0.027 | 0.131 |
| 1 % | 10 % | 0.030 | 0.171 | 0.026 | 1.502 |
| 1 % | 30 % | 0.027 | 0.156 | 0.023 | 1.277 |

- A's p95 is the async kinds (0.11 to 0.25 s: the async work itself plus waits on other attempts' async work).
- B's p95 with groups is the moves: group requirements take 0.05 to 2.3 s; singles sit behind a group that holds the
  scheduler or move away from a crowded Paper (single p95 0.30 to 0.84 s).
- Restart requirements: A 10.1 to 20.3 s p50 (boot 6.8 to 13.9 s), B 9.8 to 39.6 s p50 (boot 7.5 to 30.8 s).

Where the time goes in A with restarts: the 990 normal requirements are done after 20 to 26 s; the rest is the 10
restarts one after another on the extra Paper.

## Moves, boots and memory

| Measure | Value |
|---|---|
| Move a client between stepped Papers (B, leave like the pause menu, connect, facts ready, step again) | p50 0.28 to 0.78 s, p95 0.50 to 2.1 s; faster with fewer moves in flight |
| Move a client to the unstepped extra Paper and back (A restart) | p50 0.51 to 1.31 s each way |
| Boot of 4 Papers in parallel (B setup) | 22.5 s (9V45), 33.4 s (9V74), 37.2 s (7763); each 22 to 36 CPU s |
| Boot of 2 Papers in parallel (A setup) | 12.0 s, 15.4 s, 17.7 s; each 23 to 34 CPU s |
| Restart boot while the rest runs | A 12 to 14 s p50 on 9V74 and 7763, 7 to 8 s on 9V45; B 21 to 31 s and 7.5 to 17 s |
| Kill to ready (facts) | A 8.6 to 17.4 s, B 9.4 to 38.1 s |
| Paper RSS after boot | 0.78 to 0.94 GB |
| Client RSS | 1.35 to 1.50 GB |
| Peak memory used, whole runner (MemTotal − MemAvailable) | **A 8.0 to 8.7 GB, B 10.1 to 10.7 GB** of 16 |
| Busy vCPU over a run, no restarts | A 1.1 to 2.0, B 2.5 to 3.4 |
| Busy vCPU over a run with restarts | A 3.5 to 3.8, B 3.6 to 4.0 |

## A: time lost to another attempt's async work

The step policy attributes every idle pass to each running attempt: its own member lags or is busy, or another
attempt's member is busy (lost to async) or lags (lost to ack).

| Run (per 1,000) | Lost to others' async, total s | Attempts hit | Loss per attempt hit, median ms | Lost to others' ack, total s | Own async wait, total s |
|---|---|---|---|---|---|
| no restarts, 0 % groups | 25.0 to 26.8 | 244 to 250 | 95 to 105 | 2.0 to 3.1 | 9.4 to 9.8 |
| no restarts, 10 % groups | 20.9 to 22.3 | 212 to 215 | 93 to 98 | 1.6 to 2.8 | 9.2 to 9.9 |
| no restarts, 30 % groups | 14.0 to 15.3 | 134 to 150 | 94 to 101 | 1.1 to 1.8 | 9.5 to 9.9 |
| 1 % restarts, 0 % groups | 17.0 to 17.4 | 179 to 189 | 87 to 102 | 4.7 to 6.2 | 9.1 to 9.6 |
| 1 % restarts, 30 % groups | 9.5 to 10.3 | 101 to 108 | 91 to 96 | 1.7 to 2.7 | 9.3 to 9.5 |

- The totals add over attempts running at once, so they exceed the wall time; the effect on wall time is that the
  100 async requirements (each about 100 ms) stop the Paper for about 10 s, close to A's whole run.
- Groups lower the loss because fewer attempts run at once (3 clients for one claim).
- A per player tick is impossible on a shared Paper, so this loss can only shrink by moving async work off the tick
  path (work that does not hold the tick) or by running async heavy requirements elsewhere (**inferred**).

## B-fresh: a fresh Paper per requirement, booted ahead (computed, not built)

Inputs measured above, runner 4 vCPU and 16 GB: boot 22 to 36 CPU s per Paper (4 in parallel), 12 to 18 s wall
when 2 boot together, Paper RSS 0.85 GB, 4 clients 5.6 GB, a client join to a new Paper 0.3 to 0.8 s.

| Target | Rate | CPU needed for boots | Booters in flight (rate × 12 s boot) | Memory for them |
|---|---|---|---|---|
| Match A, no restarts (1,000 in 13.7 s) | 73 per s | 1,600 to 2,600 vCPU | about 880 | about 750 GB |
| Match A with 1 % restarts (1,000 in 188 s) | 5.3 per s | 117 to 190 vCPU | about 64 | about 54 GB |
| Everything the runner has | 4 vCPU / 22 to 36 CPU s | 0.11 to 0.18 boots per s | 2 to 3 | 2 to 3 GB |

On the free runner B-fresh is CPU bound at 0.11 to 0.18 requirements a second: 1,000 requirements take **1.5 to
2.5 hours** (with restarts free, since every Paper is fresh anyway), against 14 s to 3 minutes for A. Memory is not the
limit (16 GB holds about 12 Papers next to 4 clients); boot CPU is. Inferred from the measured boot cost; a smaller
Paper (C4's trimmed boot) would have to be 100 to 1,000 times cheaper to matter.

## Complexity cost

Non blank, non comment lines of the throwaway rig (`orchestrator/topo.py`, `probe-plugin/.../N.java`).

| Part | Shared by both | A only | B only |
|---|---|---|---|
| Step policy widened from one subject to a set of attempts (`N.java` hook, finish, attempt) | about 115 (50 before) | | |
| Idle keepalive tick (a Paper with no attempt still ticks once a second) | 8 | not needed in practice (S always runs attempts) | needed: idle Papers hit Paper's 60 s watchdog |
| Requirement body, move, restart scene, Paper wrapper | 90 | | |
| Scheduler and rig base | 95 | | |
| Topology class (claims, placement, restart handling) | | 61 | 72, 88 with parallel moves |

Concepts each needs:

- **A**: one tick stream for every attempt; every claimed client acks every tick; every claimed player's async work
  blocks everyone; an extra unstepped Paper for restarts with a move out and back; auto ticks while a client joins.
- **B**: everything A's policy has (a group of k players still shares one Paper's ticks), plus a client location map,
  the placement rule (free Paper with the most free clients, move the rest), clients riding along when a restart
  kills their Paper, an idle keepalive tick, a cap on restarts at once, and turning stepping off and on around a
  restart in place.

## Surprises

- **Without groups B beats A by 2.7 times.** The cost of sharing is not ticks or acks (ack waits on others: 1 to 5 s
  per 1,000) but async work: one attempt's 100 ms stops every attempt.
- **Four restart boots at once are slower than one after another.** Uncapped, B started 4 restarts together: boot 61
  to 77 s each (run 42336500003 job 1, Xeon 8370C, archive not mapped), against 12 to 14 s for one boot. Boot is CPU
  bound (22 to 36 CPU s), so 4 vCPU give no parallel gain. The measured B therefore runs one restart at a time.
- **An idle stepped Paper dies after 60 s.** With no attempt nothing grants a tick, so Paper's watchdog stops the server
  ("The server has stopped responding!") and keepalives stop too. B's first CI run lost every Paper this way. Fix: one
  tick per second while no attempt runs.
- **The AppCDS archive silently failed to map with the agent.** A dynamic archive dumped without
  `-XX:+AllowArchivingWithJavaAgent` fails to dump with an agent; dumped with it, the same diagnostic flag must also be
  set at run time or `-Xshare:auto` drops the archive silently (boot 7.5 s against 5.1 s on the Mac). Spike K's runner
  boot may have had the same gap.
- **Boot CPU is 22 to 36 s per Paper on the runner** even with the archive mapped; two Papers booting together take 12
  to 18 s wall. The runner fleet varies a lot: the EPYC 9V45 job ran restarts 1.5 to 2 times faster than the 7763.
- **Restarts are 1 percent of requirements and 75 to 90 percent of A's wall time.** Whatever topology wins, restart
  requirements decide suite time; a second extra Paper for A halves that part (**inferred**).

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
python3 orchestrator/topo.py run --topo B --n 1000 --mixes 0,0.1,0.3 --restart 0.01,0 --seed 1 [--parallel-moves 1] [--restart-slots 1]
python3 orchestrator/topo_report.py runs/topo.jsonl
```

CI: matrix rows `{ plan: topology, backend: vulkan, runner: ubuntu-24.04, repeat: 0|1|2 }` run
`orchestrator/ci.py plan topology` (both topologies, order alternating with the repeat, seed = repeat + 1).

Mac development runs (M1 Max, load 9 to 15 with another worktree's spike running) only checked that both
topologies work; no Mac number is used above.
