# Lease time: where the 1.2 s from grant to lease went

A measurement, not a prototype. Every requirement's first step is the pool granting clients and the attempt
getting its lease; that cost about 1.2 s per requirement with an unknown cause. A temporary timing build split
each attempt into parts, and the fixes followed.

## Answer

- **Paper's wall clock chunk send cap is about 1.08 s of the 1.13 s median.** `player-max-chunk-send-rate 75`
  (unchanged in the test Paper) throttles the 81 chunks a claim waits for (radius 3 plus the edge ring, while the
  client draws render distance 2). The wipe itself costs 1.4 ms; the synchronous claim 18 ms, mostly generating
  the centre chunk.
- **Experiments, median grant to lease** (each a mode of the timing build, every region fresh): cap removed 499
  ms; cap removed plus regions loaded ahead (`preload=140`) 291 ms; render distance 4 1661 ms. What remains
  without the cap is 11 to 13 stepped ticks, with the moving client acking about 28 ms late (a guess: section
  compiles, not timed).
- **A separate 8 to 17 s tail** (3 or 4 claims per run): a free player holds back no ticks, its client falls up
  to 235 ticks behind, and once claimed every attempt waits for it to catch up (`StepPolicy` `allAcked(claimed)`).
- **Fixes, commit `e5f88a238`: `cargo xtask e2e game` 83 passed, grant to lease median 409 ms, p90 684 ms, max
  5284 ms** (was 1132, 1422, 16353). The fixes: the test Paper no longer caps chunk sends and loads; Paper loads
  the ground of the regions the next claims get during earlier attempts (`GroundAhead`); every connected client
  gets step pings and holds back the next tick until it acked the last one, claimed or free (a client stalled 5 s
  still counts as lost); a claim keeps waiting for the chunks the client draws plus the ring of neighbours it
  needs to mesh them, and PROBE-3 guards that a block at the edge of that area shows right after a far teleport.
- **Unknown:** why the client reports view distance 3 with render distance 2, and why Paper sends only about 10
  chunks per tick without the cap.

Machines: the developer's machine (local runs; the machine model is not recorded). Evidence: 4 full suite runs, 82 passed each, under the timing build; the fixed
build 83 passed. Measured unless marked as a guess. No CI run ids: this was local.

## What the timing build measured

Each process (pool, Paper, clients) appended wall clock lines to an `lt-*.log` in the pool folder; a
`lease-time.mode` file beside the pool log chose an experiment (`sendRate=-1`, `loadRate=-1`, `preload=140`,
`renderDistance=4`, one per line). `analyze.py` split each attempt from the pool's claim to its lease into parts
and printed median, p90 and max of each:

| Part | From, to |
|---|---|
| `claim_sync` | Paper's synchronous claim work (wipe, wipe event, highest block, teleport) |
| `sent_wait` | claim end on Paper until every chunk in view was sent |
| `confirm_wait` | all sent until Paper's delivery is done (one more tick acked by the client) |
| `claimed_hop` | delivery done on Paper until the pool hears Claimed |
| `reset_client` | pool sends Reset until the last client's ResetDone reaches the pool |
| `group_wait` | last ResetDone until the lease (waiting for side by side attempts) |

Each sync and wait part also counted the ticks and the time between ticks spent waiting for acks. Modes measured:
none; `sendRate=-1 loadRate=-1`; the same with `preload=140`; `renderDistance=4`.

## Rerun

The measuring code was temporary and lived on branch `proto/gv-lease-time` (commits `acc21a35b`, the timing in
pool, Paper plugin, client mixin and `LeaseTime.java` plus `analyze.py`; and `056013429`, the analysis scripts);
that branch is deleted, so this is kept only as a record of how it was run. All under `services/playtest/` at
those commits:

- `lease-time/collect.sh`: copied one run's logs (`lt-pool.log`, `lt-paper.log`, each client's `lt-client.log`,
  the mode file, `paper-global.yml`, `server.properties`, `test_run.json`) into a folder per run.
- `lease-time/analyze.py`: the part split above.
- `lease-time/drawn_chunks.py`: the time from a claim's sync end until the nearest 25 of the 81 awaited chunks
  were sent, against all 81 (what waiting for only the chunks the client draws would save).
- `lease-time/catch_up.py`: per claim, how many ticks the claimed players' clients lagged behind Paper and how
  long until all caught up (the source of the 235 tick and 8 to 17 s tail).

## What this means for the search

- **Do not let Paper's wall clock caps into a stepped run**: the test Paper turns off the chunk send and load
  caps (decision `lease-time-fixes`), and the real wait is the chunks the client draws plus its neighbour ring.
- **Every connected client is stepped, claimed or free** (decision `free-clients-in-step`), one rule, lost clients
  still go after 5 s.
- **The client's graphics are pinned** (decision `pin-client-graphics`): the default FANCY preset overrides render
  distance 2 with 3 at start (`Minecraft.java:576`), so a move waited for 81 chunks; graphics preset custom with
  render distance 2 cuts that and keeps a preset change from moving the goldens. Built after slice 6, before any
  golden hash exists.
- Regions are still never reused; the lookahead loads the next few during earlier attempts.
