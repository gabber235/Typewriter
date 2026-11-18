# D: how many clients, on how many Papers, and who disturbs whom

## Answer

- **On the free runner: up to 8 gated clients, best as 2 Papers with 4 clients each, joined one at a time,
  each client gated the moment it is ready.** Measured 16,000 to 17,500 requirements per minute with the E
  signals, p95 55 ms, 3.1 vCPU busy, 13.6 GB of 16 used. One Paper with 8 clients gives the same rate
  (15,400 to 16,900); two Papers halve the reach of every server wide effect for 0.7 GB.
- **Throughput is linear in clients only when "done" (E6) counts work per player.** Each client adds about
  2,100 to 2,400 requirements per minute up to 8. With E6 server wide, as E and I built it, one Paper flattens
  at 6,800 to 11,700 per minute, whatever the client count, because every client waits for its neighbours'
  pending ticks and async work.
- **More clients pay only for big suites.** A client costs about 16 s to join (staggered, gated on ready) and
  1.4 GB; a trivial requirement costs 24 ms. Inferred from these numbers: the best client count is about
  the square root of (single client work seconds / 16 s). Hundreds of requirements of today's kind take under a
  minute on 1 or 2 clients; 8 clients pay off above about 15 minutes of single client work.
- **The framework must hold four rules per player** (each measured: world wide API leaks, per player API 0 of
  about 1,600 victim requirements):
  1. Effects go to one player: chat, titles, boss bars, scoreboards, time of day, weather, entities, sounds and
     particles use the per player API. World wide calls are forbidden in requirements.
  2. Regions are far apart and players are hidden from each other: at 16 blocks neighbours see each other's
     players, world entities, sounds and particles; at 1024 blocks nothing leaked.
  3. E6 counts the player's own scheduled and async work, not the whole plugin.
  4. Chat and title checks match the requirement's own token, not "the newest line".
- **Only a Paper of its own (or a separate phase) isolates what is server wide by nature:** tick rate (a demo
  rerun at rate 10 cut neighbours by 94 percent), main thread lag (a 400 ms spike every 0.6 s cut them by 39
  percent), and coverage per requirement (inferred: JaCoCo probes are per JVM, so concurrent requirements on one
  Paper share them). On its own Paper the same aggressor moved the victims by 0 to 16 percent (CPU only).

Machines: GitHub hosted `ubuntu-24.04`, 4 vCPU, 16 GB, Vulkan on lavapipe (`llvmpipe (LLVM 20.1.2, 256 bits)`,
Mesa 25.2.8), 854x480, render distance 2, void world, render gate 2, server rate 200 unless named. CPUs: Xeon
Platinum 8370C, Xeon Platinum 8573C, EPYC 7763, EPYC 9V74, EPYC 9V45; each table names them. Steal 0.0 in every
window. Mac only to build the harness (load 12 to 71); no Mac timing is used. Measured unless marked
**inferred**. 245,224 requirements over 11 jobs: 0 wrong verdicts outside the world wide broadcast phases; 15
wrong there (see Interference).

## Evidence

| Run | What |
|---|---|
| [42184657603](https://github.com/gabber235/Typewriter/actions/runs/42184657603) | 3 x `clients` (all arrangements, E6 server then player), `joins`, 2 x `interfere` |
| [42187755498](https://github.com/gabber235/Typewriter/actions/runs/42187755498) | 2 x `joins2` (gate on ready), 2 x `cells` (rate 20, 1x1x1x1, 4x4) |
| [42189430842](https://github.com/gabber235/Typewriter/actions/runs/42189430842) | `scopes` (E6 server wide against per player, alternating after a warm up). The second `scopes` job hung in apt twice (first attempt and rerun), so this table has one job |

Artifacts per job: `h.jsonl` (rows carry CPU and Mesa), `d-clients/*.jsonl.gz` (one raw row per requirement:
kind, window, verdict, quiet, done and total ms, leftovers seen), `h-evidence/` (log tails per client and
server). 14 day retention, so they expire around 2026-11-20.

## The requirement as measured

Every client runs a mixed loop, every 10th requirement broken (the effect never comes):

| Kind | Effect | Window |
|---|---|---|
| title, chat, block, entity | per player title, chat line, fake block, packet only text display | 2 ticks |
| late | chat line 1 to 8 ticks later through the scheduler | late + 2 ticks (3 to 10) |
| async | Bukkit async task, 0 to 20 ms, then chat | 200 ms worth of ticks (40 at rate 200) |

Per requirement: effect and a window barrier w ticks later (one `d.req`); verdict **E3t** (pass on the first
client loop holding the fact, fail at the window barrier); done **E6** (quiet barrier, then a client loop with
radius chunks held, no title fading in, perceived state equal to the loop before); a leftover check on that
state (and in interference runs also boss bars, sidebar, time of day, rain, particles, sounds); reset. "Total"
is all of it including the reset. Start signal: E's level, no screen, radius chunks held, hands settled (`r.bits`).

## 1. Throughput per arrangement

`clients` plan, rate 200, 20 s per phase, 3 jobs (Xeon 8370C, EPYC 7763, EPYC 9V74); `cells` for 1x1x1x1 and
4x4 (EPYC 9V45, Xeon 8573C). Per minute: median of jobs (range). E6 per player.

| Arrangement | Clients | Requirements / min | Per client | Total median, p95 ms | E6 quiet p95 ms | Busy vCPU | Machine GB used |
|---|---|---|---|---|---|---|---|
| D1: 1 Paper x 1 | 1 | **2,399** (2,354 to 2,450) | 2,399 | 24, 50 | 2.2 to 2.9 | 0.4 | 3.2 to 3.4 |
| D2: 1 x 2 | 2 | 4,819 (4,811 to 4,865) | 2,410 | 24, 50 | 2.3 to 2.8 | 0.6 to 1.0 | 4.6 to 4.7 |
| D2: 1 x 4 | 4 | 9,450 (9,422 to 9,577) | 2,363 | 24, 51 | 3.2 to 3.4 | 1.6 to 1.7 | 7.3 to 7.4 |
| D2: 1 x 6 | 6 | 13,902 (13,436 to 13,984) | 2,317 | 24, 53 | 4.7 to 7.3 | 2.3 to 2.6 | 10.2 to 10.3 |
| D2: 1 x 8 | 8 | **16,494** (15,396 to 16,861) | 2,062 | 25, 56 | 9.4 to 13.1 | 3.1 to 3.3 | 12.8 to 13.0 |
| D3: 2 x 2 | 4 | 9,525 (9,185 to 9,538) | 2,381 | 24, 51 | 3.6 to 5.1 | 1.6 to 2.1 | 8.2 to 8.3 |
| D3: 2 x 3 | 6 | 13,542 (13,032 to 13,608) | 2,257 | 24, 54 | 5.9 to 8.3 | 2.6 to 2.9 | 11.2 to 11.3 |
| D3: 4 x 1 | 4 | 9,573, 9,545 | 2,390 | 24, 50 | 3.2 to 4.4 | 1.9 to 2.0 | 10.2 to 10.3 |
| D3: 2 x 4 | 8 | **16,695, 17,503** | 2,140 | 25, 55 | 7.6 to 9.8 | 3.1 | 13.6 to 13.7 |

- **Linear to 6, 88 percent of linear at 8.** Per client rate falls from 2,400 to 2,060 at 8 on one Paper,
  where the machine runs 3.1 to 3.3 of 4 vCPU (Paper 78 to 80 percent of a core, each gated client 24 to 28).
- **D3 costs memory, not speed.** Papers 0.9 to 1.35 GB each, clients 1.33 to 1.62 GB. 4 x 1 needs 2.9 GB more
  than 1 x 4 for the same rate; 2 x 4 fits with about 2.3 GB to spare. **Inferred:** a ninth client (1.4 GB) fits
  on one Paper; a tenth does not.
- **0 wrong verdicts and 0 leftovers in every cell**: the per player kinds do not reach each other.
- Pass verdict p95 35 to 40 ms is the late kind's own ticks (8 ticks at rate 200); fail verdict 13 to 15 ms is
  the 2 tick window plus the barrier.

### Rate 20 against rate 200

`cells`, E6 per player, 15 s, EPYC 9V45 and Xeon 8573C.

| Clients | Requirements / min | Total median, p95 ms | Busy vCPU |
|---|---|---|---|
| 1 | 375, 376 | 100, 400 | 0.3 to 0.4 |
| 4 | 1,485, 1,491 | 101, 445 to 448 | 1.5 |
| 8 | 2,943, 2,895 | 103 to 104, 443 to 447 | 2.6 to 2.7 |

At rate 20 every client is held by ticks (6.4 times slower than rate 200), so clients scale linearly with CPU
to spare. Requirement windows and late effects are in ticks, so rate is the biggest lever after the gate.

## 2. E6 server wide against per player

`scopes`, EPYC 7763, 15 s phases in the order player, server, player, server after the join. Per minute.

| Arrangement | First phase after join (player) | Server wide | Per player | Server wide | Quiet p95 server wide / per player ms |
|---|---|---|---|---|---|
| 1 x 4 | 7,950 | 7,332 | **9,571** | 7,653 | 35 / 2.7 |
| 1 x 8 | 8,020 | 9,904 | **16,772** | 11,711 | 41 to 51 / 11 |
| 2 x 4 | 7,343 | 9,559 | **16,045** | 13,800 | 37 to 48 / 11 |

- **Server wide E6 costs 20 to 23 percent at 4 clients and 30 to 41 percent at 8** on one Paper; per Paper scope
  with 2 x 4 costs 14 to 40 percent. The quiet barrier waits for any neighbour's pending late chat or async task
  (median 4 to 21 ms, p95 35 to 51 ms against 2 to 11 ms per player).
- Round one ran server wide always first after the join, so its server wide numbers carry the warm up too:
  one Paper flattened at 6,800 to 8,200 per minute from 4 to 8 clients (`clients` jobs, all three CPUs).
- **Warm up: the first 15 s after 8 clients join run at half rate** (8,020 against 16,772), with 3.9 vCPU busy.
  Interference runs show the same at 4 clients: 5,000 per minute at the start, 6,000 in the same setup at the end.
  Inferred: JIT and the last of the join work; a suite should start requirements on each client as it is ready
  rather than measure from "all joined".
- The same server wide wait is what I's coverage dump uses (`Coverage.waitAndDump` polls the plugin's busy count),
  so its cost per requirement on a shared Paper is this column. Not measured separately.

## 3. Joining

Seconds. "All" is the first start to the last client ready; "each" is each client's own start to ready.

| Join | 4 clients: all; each | 8 clients: all; each | CPU |
|---|---|---|---|
| Together, drawing until all are ready | 60, 61; 58 to 60 | 125; 121 to 125 | EPYC 9V74 |
| Together, gated from the first frame (gate 1) | 84 to 106 | 170 to 183 | Xeon 8370C, EPYC 7763, 9V74 |
| Staggered, drawing | 108; 15.8, 20.0, 28.0, 43.8 | 419; 15.5 rising to 96.7 | EPYC 9V74 |
| Together, each gated once ready | 59 to 61, 80 | 117 to 168 | EPYC 9V74, 9V45, 7763, Xeon 8573C |
| **Staggered, each gated once ready** | 65; **15.5 to 17.6** | 144; **16.1 to 21.2** | EPYC 9V74 |

- **Gating from the first frame hits the client's 30 s loading timeout** (`Timed out while waiting for the client
  to load chunks, letting the player into the world anyway` in every client log): the loading screen waits for
  section meshes, which are never uploaded without a drawn frame. One client took 50 to 52 s against 15 to 20.
- **Staggered without gating gets slower with every client**, because the clients already in keep drawing at
  full rate on the software renderer. Gated once ready, every client joins in 16 to 21 s, as alone.
- All at once is CPU bound: about 15 s of join per client on 4 vCPU, so together and staggered end at about the
  same time. **Inferred, not measured:** with staggered gated joins the first client can work from about 16 s,
  so the join cost of the others overlaps with requirements.
- **1 of 20 clients joining together while drawing never became ready in 240 s** (run 42184657603, 4 together).
  Its logs were lost (the fleet stopped without its exit step); fixed, and the next 8 together joins were all
  ready. The other 270 client starts in this spike were all ready.
- Papers boot in 10 to 15 s; 2 in parallel 14 to 24 s, 4 in parallel 35 to 41 s.

## 4. Interference

`interfere`, 2 jobs on EPYC 7763. Client 0 is the aggressor; 3 victims run the mixed set with E6 server wide and
a leftover check after every done. The aggressor repeats its leaky requirement: effect held 10 ticks (50 ms),
done, reset, 0.3 s pause; so a leak is present for a fraction of each phase. The aggressor checks its own effect
every time (44 of 44 seen for every kind, so a victim's 0 is not a blind observer). Cell: victim requirements
that perceived the leak at done / victim requirements, both jobs; wrong verdicts in brackets when not 0.

| Leak | World wide API, neighbours 16 blocks | Per player API, 16 blocks | World wide, 1024 blocks | World wide, aggressor on its own Paper |
|---|---|---|---|---|
| Broadcast chat | 116 / 1536 **(3 wrong)** | 0 / 1562 | 123 / 1611 **(5 wrong)** | 0 / 1479 |
| Title to all players | 116 / 1545 **(7 wrong)** | 0 / 1608 | | |
| Time of day | 281 / 1633 | 0 / 1625 | | 0 / 1541 |
| Weather | 500 / 1605 | 0 / 1628 | | |
| Boss bar to all | 258 / 1613 | 0 / 1624 | | |
| Main scoreboard sidebar | 268 / 1647 | 0 / 1620 | | |
| World text display | 175 / 1626 (two nearest) | 0 / 1652 (hidden by default, shown to owner) | 0 / 1534 | 0 / 1573 |
| Sound, volume 2 | 35 / 1678 (nearest only) | 0 / 1607 | 0 / 1620 | 0 / 1601 |
| Particles | 535 / 1632 (nearest only) | 291 / 1628, all leftovers of the world phase in its first 4 s | 0 / 1576 | |
| Neighbour players | every victim requirement | (same) | 0 | (victims share a Paper) |

Server wide effects. Victim requirements per minute (both jobs) against the same setup at the end of the job
(about 6,030 on one Paper, 5,820 with the aggressor on its own Paper).

| Effect | Same Paper | Change | Own Paper | Change |
|---|---|---|---|---|
| Main thread lag 400 ms, every 0.6 to 1 s | 3,728, 3,642; total p95 60 to 65 ms, max 440 ms | **-39 percent**, 0 wrong | 5,825, 5,873 | 0 |
| Async work 300 ms, victims E6 server wide | 592, 585; quiet p95 306 ms | **-90 percent** | 5,627, 5,723 | -2 percent |
| Async work 300 ms, victims E6 per player | 7,169, 7,042; quiet p95 2.4 ms | 0 (faster than the end baseline, which is server wide) | 6,903, 7,041 | |
| Demo rerun: rate 10 and the aggressor drawing | 310, 416; total p95 1000 ms | **-94 percent** | 4,944, 4,819 | **-16 percent** (CPU: 3.2 vCPU busy) |

- **Broadcast leaks cause wrong verdicts, and rarely: 15 of 4,692 (0.3 percent).** The neighbour's line or title
  arrived in the same client loop as the victim's own, so the newest chat line or the shown title was the
  neighbour's from the first loop on, and the victim failed at its window. Distance does not help. A check that
  looks for its own token anywhere in chat would pass; a title is replaced outright. Flaky, the worst kind (as
  in E: right by luck is worse than always wrong).
- Every other world wide leak left the verdict right (the mixed kinds do not check sky, rain, bars or sounds) and
  showed up only in the leftover check: a requirement checking a golden frame, an absence, or the sidebar would
  have been wrong in those cases (**inferred** from the leftover counts; goldens were not taken here).
- **Every per player counterpart leaked 0 times**, and every spatial leak was 0 at 1024 blocks.
- **Rate, lag and E6 server wide hit every client on the Paper and only those.** On its own Paper the aggressor
  disturbed nothing but CPU.
- Coverage per requirement (I) on a shared Paper: **inferred** wrong attribution. JaCoCo's probes are one array per
  class per JVM, and concurrent requirements on one Paper run the same plugin code; a dump at one requirement's
  end holds its neighbours' lines too. Not measured. Per requirement coverage needs one requirement in flight per
  Paper: one client per Paper, or a sequential coverage pass.

### What isolates what

| Leak | Per player rule in the framework | Far regions | Own Paper |
|---|---|---|---|
| Broadcast chat, title to all, boss bar, sidebar, time, weather | yes (measured) | no | yes |
| World entity, sound, particle | yes (measured) | yes (measured at 1024) | yes |
| Neighbour player visible | hide players (inferred) | yes | yes |
| E6 quiet barrier | yes: count the player's own work (measured) | no | yes |
| Tick rate (demo rerun, rate 10) | no | no | **only this** |
| Main thread lag | no | no | **only this** |
| Coverage per requirement | no (inferred) | no | **only this**, one client per Paper |

## Surprises

1. **Gating a client from its first frame makes its join 30 s slower**: the loading screen waits for meshes that
   are uploaded only in a drawn frame, then times out.
2. **The client's barrier was "last ping", not "highest"**: a window barrier still scheduled after a fast pass
   arrived after the reset barrier and hid it; 2 of 10 Mac requirements waited 20 s. `PingMixin` now keeps the
   highest id. Ids still never repeat.
3. **A tick window shrinks with the rate, wall clock work does not**: the async kind with E's 4 tick window was
   wrong 22 of 51 at rate 200 on the Mac (load 18); 4 ticks are 20 ms there. The mixed set above sized that
   window for the rate, a patch; "Fail rule with async work" below removes the cause.
4. **Music plays by itself** (`minecraft:music.creative`) and every spike's options set particles to minimal,
   which hides every particle, including a neighbour's. A sound observer must ignore music; a particle requirement
   needs particles on.
5. **`setTime` back to noon moves the clock a full day forward**, so a time of day check compares modulo 24000.
6. Server wide E6 caps one Paper at 6,800 to 11,700 per minute however many clients it has.
7. The first 15 s after joining 8 clients run at half rate.
8. **`apt-get install` hung until the 25 min job limit in 2 of 13 job attempts**, the same matrix row 30 min
   apart (`apt-get update` took 5 s both times); H saw 9 min once. Caching the packages is now needed, not nice.

## What this means for the search

- **D**: the free runner holds 8 gated clients; the useful count follows from the suite's total work, and 1 or 2
  clients cover today's suite. Recommend 2 Papers x 4 clients when a suite needs more than 4.
- **Framework (G and the implementation plan)**: requirements get a per player effect API only; world wide calls
  are forbidden or isolated. Regions are far apart and players hidden. Chat and title checks match the
  requirement's own token. E6 counts the player's own work, so Typewriter's scheduled and async work must carry
  the player it serves (extends I's "counted dispatchers" with an owner).
- **B**: a demo rerun at rate 10 must run on a Paper of its own (or after the gated suite); next to gated work it
  cut neighbours by 94 percent.
- **I**: per requirement coverage needs one requirement in flight per Paper JVM. Either one client per Paper (4 x
  1 measured: same rate as 1 x 4, 2.9 GB more) or coverage in its own pass.
- **C and E**: rate stays the biggest lever (rate 200 is 6.4 times rate 20 per client). Windows for async work
  not be sized for the rate: fail only when the window has passed and the player's own work is quiet (see
  "Fail rule with async work"). Start each client's requirements as soon as it is ready.
- **H**: cache the apt packages; a job limit must cover a 25 min hang or retry.

## Rerun

Build as in E. Plans in `orchestrator/ci.py`, picked by `matrix.include` in
`.github/workflows/game-verification-prototype.yml`; push to the prototype branch, then `gh run download <id>`.

| Matrix row | What | Time |
|---|---|---|
| `{ plan: clients, backend: vulkan, runner: ubuntu-24.04, repeat: N }` | 1, 4, 8, 2x2, 2, 6, 3x3 with E6 server then player (1x1x1x1 is skipped by the budget) | 21 min |
| `{ plan: joins, ... }` | together, staggered, gated from the first frame, for 4 and 8 | 23 min |
| `{ plan: joins2, ... }` | gated once ready, together and staggered; 4 together | 11 min |
| `{ plan: cells, ... }` | rate 20 for 1, 4, 8; 1x1x1x1; 4x4 | 11 to 13 min |
| `{ plan: scopes, ... }` | 4, 8, 4x4: E6 per player and server wide, alternating | 12 min |
| `{ plan: interfere, ... }` | every leak near, spatial leaks far, server wide effects, aggressor on its own Paper | 13 min |
| `{ plan: failrule, ... }` | fail rules at rates 20, 200, 400, 100 rounds per cell, 10 hangs | 14 min |

The branch is left with one `smoke` row. On the Mac, from `prototypes/game-verification`, with
`SDL_MAC_BACKGROUND_APP=1`: `python3 orchestrator/d.py fleet --layout 2x2 --seconds 10 --join ready-gate` and
`python3 orchestrator/d.py interfere --layout 4 --seconds 4 --spacing 1 [--leaks bcast:world,time:player]`.
Results append to `runs/d-clients.jsonl`, raw rows to `runs/d-clients/`.

## Reuse

- **Plugin** `probe-plugin/.../D.java`: `d.req` (every requirement and leak kind, `scope=world|player`, window
  barrier `wping`), `d.quiet` (quiet barrier `qping`, `scope=server|player`), `d.reset` (everything a player's
  requirements left, including world time, storm, bars, objectives), `d.busy`. Parameters are not named `ping`:
  the line handler sends a ping for that name right after the command.
  `d.req ... fail=quiet limitMs= limitTicks=` is the cause based fail rule (cancels the player's async work at
  the limit), `d.qinfo` reports quiet time and hung count; kinds `asyncslow`, `asyncsync`, `hang`.
- **Mod**: `r.bits` (E's start bits on demand), `held` now has `day`, `rain`, `particles`; `PingMixin` keeps the
  highest barrier id.
- **Orchestrator** `orchestrator/d.py`: `Fleet` (any list of Papers with k clients, join modes `together`,
  `stagger`, `gated`, `ready-gate`, `stagger-gate`, regions with any spacing), `requirement` (E3t, E6, leftover
  check, reset, one raw row), `e6`, `leaks_in`, `fleet_cell`, `interfere`, `failrule` (`d.py failrule`). `ci.d_hooks` plugs in Xvfb, the renderer
  assertion, `/proc` CPU and per member log tails.

## Fail rule with async work

Question: instead of sizing a window for the fastest rate (a patch), fail only when **the window barrier has
arrived and that player's own counted work is quiet** (no pending task the player's requirements scheduled, no
running async worker for the player); a pass still decides the moment the fact holds. Work that hangs is
stopped by an outer limit.

Built as `d.req ... fail=quiet`: the window task, after w ticks, starts the per player quiet wait instead of
sending the barrier; the barrier goes out once the player is quiet. At the outer limit (`limitMs` wall clock, or
`limitTicks`) the player's running async work is interrupted, its effect skipped, and the barrier goes out.
Kinds use E's windows, not sized: chat and title 2 ticks, late chat 1 to 8 ticks (window late + 2), async 0 to 20
ms then chat, slow async 50 to 150 ms then chat, async then a tagged one tick task then chat, all 4 ticks. Every
kind is broken in every fifth round, and broken async kinds still run their work. One client, gated, E6 per player.
Hang: async work that would sleep 10 min and never sends its effect; it must fail.

Machines: Mac M1 Max, OpenGL on Metal, 50 rounds per cell, load 7.0 to 9.4 (`uptime` 8.6 before, 8.2 after);
runner [42198290611](https://github.com/gabber235/Typewriter/actions/runs/42198290611), Xeon Platinum 8370C,
Vulkan on lavapipe, 100 rounds per cell, load 0.2 to 0.5.

Wrong verdicts (all were wrong fails of good requirements; 0 wrong passes anywhere). Runner, out of 100 per
kind; Mac out of 50 in brackets.

| Rate | Rule | chat | title | late | async 0 to 20 ms | slow async 50 to 150 ms | async then tick task | hang (10) |
|---|---|---|---|---|---|---|---|---|
| 20 | window (E3t) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 **(1)** | 0 (0) | |
| 20 | window + own work quiet, limit 1000 ms | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) |
| 20 | window + own work quiet, limit 20 ticks | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) |
| 200 | window (E3t) | 0 (0) | 0 (0) | 0 (0) | **16 (15)** | **80 (40)** | **28 (15)** | |
| 200 | window + own work quiet, limit 1000 ms | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) |
| 200 | window + own work quiet, limit 20 ticks | 0 (0) | 0 (0) | 0 (0) | 0 (0) | **28 (20)** | 0 **(1)** | 0 (0) |
| 400 | window (E3t) | 0 (0) | 0 (0) | 0 (0) | **44 (24)** | **80 (40)** | **55 (31)** | |
| 400 | window + own work quiet, limit 1000 ms | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) |
| 400 | window + own work quiet, limit 20 ticks | 0 (0) | 0 (0) | 0 (0) | 0 (0) | **73 (39)** | 0 (0) | 0 (0) |

- **The cause based rule with a wall clock limit is never wrong**: 0 of 1,800 runner and 900 Mac requirements,
  and every hang failed (30 of 30 on each machine). The bare window is wrong whenever the window is shorter than
  the work: 303 of 600 async requirements at rates 200 and 400 on the runner, none at rate 20 except one Mac
  edge case (up to 150 ms of work against a 200 ms window under load).
- **A pass costs the same**: both rules pass the moment the fact holds, so chat and title pass medians match
  (runner: 4.4 and 4.4 ms at rate 200, 2.1 and 2.1 at rate 400). Kinds with random work differ only by their
  random draw and by which passes the window rule lost.

Extra wait on a real fail (broken requirements, runner, median fail verdict ms, window rule against the new rule
with the 1000 ms limit; max of the new rule in brackets):

| Rate | chat | title | late | async 0 to 20 ms | slow async 50 to 150 ms | async then tick task |
|---|---|---|---|---|---|---|
| 20 | 149.6, 149.6 (150) | 149.9, 149.4 (150) | 349, 350 (549) | 249.4, 249.3 (250) | 249.3, 249.7 (250) | 249.6, 249.4 (250) |
| 200 | 14.8, 14.8 (15) | 14.8, 14.8 (15) | 38.4, 39.8 (55) | 23.8, 23.8 (30) | 23.4, **115.1** (156) | 23.4, 23.8 (30) |
| 400 | 8.4, 7.6 (8.5) | 6.4, 6.4 (8.6) | 18.0, 19.4 (27) | 10.6, 14.9 (26) | 12.7, **108.0** (145) | 14.7, 19.1 (28) |

- **The rule adds exactly the work still running past the window, and nothing when there is none**: +92 and +95 ms
  for 50 to 150 ms work at rates 200 and 400, at most 4.4 ms for every other kind, nothing at rate 20 where every
  window already covers the work. The Mac agrees (+98 and +90 ms slow async, within 5 ms otherwise).
- A fail is still decided by its window when the player has no work running: chat and title fail medians match
  within 1 ms.

### The outer limit for hung work

| Limit | Rate 20 | Rate 200 | Rate 400 | Legitimate slow work (50 to 150 ms) |
|---|---|---|---|---|
| 1000 ms of wall clock | fail at 1249 ms | 1024 ms | 1014 ms | 0 wrong at any rate |
| 20 ticks | fail at 1249 ms | 124 ms | 64 ms | **28 wrong at 200, 73 at 400** of 100 |

Runner medians, 10 hangs per cell, hung work cancelled 10 of 10 in every cell. The Mac matches (1000 ms: 1248,
1026, 1014 ms; 20 ticks: 1247, 123, 63 ms; 10 of 10 cancelled).

- **Express the outer limit as wall clock time on the player's async work, held by the dispatcher that counts it,
  never in ticks.** A tick limit shrinks with the rate exactly like the window did and brings the wrong fails back.
  Wall clock is right here because the thing it bounds (async work) runs in wall clock; it is not E's wall clock
  window, which bounded the fact and broke under lag. The fact window stays in ticks.
- **At the limit the framework cancels the work**, otherwise the player's later requirements all inherit a busy
  player. Measured here with thread interrupt on Bukkit async workers.
- **Inferred, not measured**: report a limit hit as its own failure ("async work hung after 1000 ms"), not as
  "fact missing"; size the limit from the slowest legitimate async work (a database or web call), far above the
  window; and let a pending tick task wait for ticks, not for the wall clock limit, since a server lag spike delays
  it legitimately (the limit here cancelled only async workers; a lag spike next to a hang was not tried).
- **This needs every async path to be counted with its player**, as spike I and the E6 per player result already
  require: work on an uncounted thread would make the rule fail early again (not measured here).
