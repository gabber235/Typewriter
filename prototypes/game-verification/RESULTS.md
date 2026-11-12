# Frames spike: drawn frames and the perception stream on the shared stepped Paper

Question: when every client draws a frame each stepped tick and streams its perception records, how much slower is
the shared stepped Paper (topology A) at 1,000 requirements on GitHub's free runner than without frames? Thresholds
from the developer: within 10 percent is fine, 20 percent is rough, over 50 percent is probably a no go.

## Answer

- **A frame per tick is a no go: +408 % at 10 percent groups** (15.4 s against 78.6 s per 1,000, median of 3 jobs,
  range +340 to +461 %). Without groups +369 %, at 30 percent groups +545 %. The runner is CPU bound: 4 lavapipe
  clients keep 3.9 of 4 vCPU busy, each client at 0.9 cores, and the stepped tick goes from 3 to 5 ms to 49 ms.
- **The best combination still lands over the no go line: +53 % at 10 percent groups** (17.6 s against 26.5 s), with a
  214x120 window, frames only on ticks after a game packet, only while a check waits, and barrier pings waking the
  render thread. 320x180 with the same levers: +59 %. Without groups +75 to +84 %, at 30 percent groups +91 to +92 %.
- **Only fewer pixels and fewer frames help.** The window buys most (854x480 to 427x240 cuts the cost from +408 to
  +136 %); below 320x180 a frame stops getting cheaper (about 8 to 12 ms of client CPU each). Drawing only after game
  packets cuts frames per tick by a third. Everything that only reschedules work (barrier wake, lavapipe threads, the
  client's worker pool) buys at most a few percent, because there is no idle CPU to schedule into.
- **"Frames only while a check waits" buys almost nothing on a shared Paper**: with 4 attempts at once every client
  is claimed nearly all the time (frames per tick per client 1.09 to 1.03).
- **Verdicts right**: 0 wrong in 210 runs of 1,000 (210,000 requirements, 21,000 deliberately broken, 23,400 group
  requirements; 144,000 judged from the stream).
- **The stream is deterministic in what it sends**: every one of the 1,000 requirements produced the same number of
  records until its verdict, per member, in every job, every repeat, every lever and every window size. The tick label
  inside a record is not (see Surprises).

Machine: GitHub hosted `ubuntu-24.04`, x86, 4 vCPU, 16 GB, Vulkan on lavapipe (llvmpipe, Mesa 25.2.8, LLVM 20.1.2)
under one Xvfb per client, gate mode 2, park 2 ms, render distance 2, void world, Paper 26.3 build 242 with the step
agent and the AppCDS archive. CPUs: run 43306724605 jobs 0 and 1 AMD EPYC 9V74, job 2 EPYC 9V45; run 43320141634 jobs
0 and 1 EPYC 9V74, job 2 Xeon 8370C. Every variant of a job runs on the same rig with the same seeds, so slowdowns
compare within a job only. Measured unless marked **inferred**.

Evidence:

| Run | What |
|---|---|
| [43306724605](https://github.com/gabber235/Typewriter/actions/runs/43306724605) | round 1: frames against none at 0, 10, 30 percent groups; levers: demand, wake, LP_NUM_THREADS 1 and 2, max.bg.threads 1, 427x240, combinations; 3 jobs, 0 wrong |
| [43320141634](https://github.com/gabber235/Typewriter/actions/runs/43320141634) | round 2: packet dirty frames, 427x240, 320x180, 214x120, combinations at 0, 10, 30 percent groups; 3 jobs, 0 wrong |

Raw rows: artifact `h-frames-vulkan-X64-<job>`, file `frames.jsonl` (one summary per run of 1,000 with every
requirement's verdict, records until the verdict and tick offsets), tables by `orchestrator/frames_report.py`.

## What was built

- **Rig**: P1's topology A (`topo.py`) with P4's stream (`Stream.java`, `Tag.java`, `streammix/*`) merged in;
  `orchestrator/frames.py` runs it. No restart Paper (no restart requirements), 4 warm gated clients, 99 warm up
  requirements per rig.
- **Workload**: P1's mix (`topo.generate`, restarts 0): 10 percent async 50 to 150 ms, 10 percent broken (the last
  member never gets the effect), the rest half chat now (window 2) and half chat 1 to 8 ticks late (window late + 2),
  groups of 2 or 3 players at 0, 10 or 30 percent. Fixed seeds, the same 1,000 requirements in every job.
- **Stream verdict**: the requirement starts with `st.begin` on each member (clear the chat, reset the stream, draw
  from now on). Pass once every member's stream holds a legible run tagged chat with the token; the test process then
  calls `n.end`, and Paper ends the attempt at its next idle pass. When the window runs out Paper sends each member a
  barrier (vanilla ping below 2^30); the verdict is what the member's stream held when its echo arrived.
- **Listener**: in the orchestrator, one socket per client, records decoded as they arrive (`frames.py`
  `ClientStream`).
- **Levers** (live unless noted): `st.mode every=0` (frames only while a check waits), `st.mode dirty=1` (a tick
  draws only when a game packet other than ping, keepalive and time was handled since the last frame; counted when
  queued on the netty thread, read before `processQueuedPackets`), `n.wake barriers=1` (barrier pings unpark the
  render thread); per client start: `LP_NUM_THREADS`, `-Dmax.bg.threads`, window size.

## Frames against none (round 1, 854x480)

Seconds per 1,000 requirements; median of 3 jobs (range). Slowdown per job against the base of the same rig.

| Groups | No frames (gated, ack verdict) | Frame every tick, stream verdict | Slowdown |
|---|---|---|---|
| 0 % | 12.9 (12.3 to 13.1) | 60.3 (52.9 to 62.6) | **+369 %** (+329 to +379) |
| 10 % | 15.4 (13.4 to 17.4) | 78.6 (67.3 to 85.6) | **+408 %** (+340 to +461) |
| 30 % | 15.5 (15.3 to 16.3) | 103.3 (89.8 to 105.3) | **+545 %** (+480 to +577) |

- At 10 percent groups each job ran base and frames twice (first and last); the base is the median of both. The first
  base run after the warm up is about 20 percent slower than the last (17 s against 14 s), so single base runs carry
  about ±12 %.
- The base matches P1 (14.9 s at 10 percent groups). Round 2 repeated it: base 15.8 s, frames 85.6 s, +457 %.
- More groups cost more with frames: a group's members all draw, and fewer attempts at once means fewer frames that
  overlap.

## What each lever buys (10 % groups)

Slowdown against the base of the same rig, median of 3 jobs. "f" is a frame every tick with the stream verdict.

| Client setup | f | demand | demand + wake | dirty | demand + dirty | demand + dirty + wake |
|---|---|---|---|---|---|---|
| 854x480 (round 1) | +408 % | +374 % | +364 % | | | |
| 854x480 (round 2) | +457 % | | | +279 % | +260 % | +251 % |
| 854x480, LP_NUM_THREADS=1 | +393 % | +344 % | +338 % | | | |
| 854x480, LP_NUM_THREADS=2 | +388 % | +328 % | +326 % | | | |
| 854x480, max.bg.threads=1 | +398 % | +339 % | +331 % | | | |
| 427x240 (round 1) | +136 % | +103 % | +101 % | | | |
| 427x240 (round 2) | +144 % | | | +78 % | +70 % | +65 % |
| 427x240, LP=1, bg=1 | +137 % | +104 % | +103 % | | | |
| 427x240, LP=2, bg=1 | +140 % | +104 % | +99 % | | | |
| 320x180 | +127 % | | | +71 % | +61 % | +59 % |
| 214x120 | +125 % | | | +65 % | +61 % | **+53 %** |

Wake alone at 854x480: +422 % against +408 % for f (noise). Frames every tick with the old ack verdict ("fack"):
+305 %.

The best levers at the other group shares (demand + dirty):

| Window | 0 % groups | 10 % groups | 30 % groups |
|---|---|---|---|
| 427x240 | +99 % (25.1 s against 13.0) | +70 % | +107 % (32.6 s against 16.2) |
| 320x180 | +75 % (23.5 s against 13.4) | +61 % | +91 % (31.3 s against 16.4) |
| 214x120 | +84 % (24.4 s against 13.4) | +61 % | +92 % (31.9 s against 16.6) |

What each lever does:

- **Window size**: the only big lever. A frame costs about 40 ms of client CPU at 854x480 with 4 clients, 10 to 15 ms
  at 427x240, 8 to 12 ms at 320x180 and 214x120 (**inferred**: client CPU above the same run's gated CPU per tick,
  over frames drawn). The rest is a fixed cost per frame that a smaller window does not touch.
- **Dirty frames**: frames per tick per client 1.08 to 0.69. The remaining dirty frames come from wipes: per 1,000
  requirements one client handles about 12,000 `ClientboundContainerSetSlotPacket`, 1,150
  `ClientboundSetEntityMotionPacket`, 600 `ClientboundSetPlayerInventoryPacket`; the entity packets reach every
  client that sees the wiped player (**inferred**: players hidden from each other would cut more). Not safe in
  general: it misses changes that need no packet (title and chat fades, interpolation); right here only because
  every check in this mix follows a packet.
- **Demand** (frames only while a check waits): frames per tick 1.09 to 1.03. On a shared Paper with 4 attempts at
  once almost no client is ever free.
- **Barrier wake**: 0 to 5 percent of wall on top of demand or demand + dirty, largest once the CPU is no longer
  saturated (214x120: +61 to +53 %); alone at 854x480 it is noise. It takes 0 to 5 ms off the barrier echo.
- **LP_NUM_THREADS and max.bg.threads**: within noise. The frames are CPU bound across the machine; fewer threads per
  client only move the same work.
- **The stream verdict itself costs about 24 percent** over the ack verdict with the same frames (78.6 against
  63.2 s): Paper runs about 300 more ticks per 1,000 requirements (1,576 against 1,275) because `n.end` arrives after
  the next ticks were already granted.

## Ticks, CPU and lateness under 4 clients (10 % groups)

Median of 3 jobs; tick is the time between consecutive stepped tick ends; cores are CPU seconds over wall seconds;
echo is Paper sending the barrier to the listener holding its echo; late is the server's tick end to the listener
holding the record drawn for that tick.

| Setup | Tick p50 ms | Frames per tick per client | Paper cores | Cores per client | Busy vCPU of 4 | Echo p50 / p95 ms | Late p50 / p95 ms |
|---|---|---|---|---|---|---|---|
| no frames, 854x480 | 2.6 to 5.7 | 0 | 0.25 to 0.46 | 0.23 to 0.47 | 1.5 to 2.4 | | |
| f, 854x480 | 48.8 | 1.08 | 0.10 | 0.90 | 3.89 | 88 / 130 | 79 / 128 |
| demand + dirty + wake, 854x480 | 35.4 | 0.69 | 0.11 | 0.85 | 3.72 | 54 / 100 | 53 / 97 |
| f, 427x240 | 21.2 | 1.10 | 0.17 | 0.78 | 3.52 | 34 / 65 | 32 / 64 |
| demand + dirty + wake, 427x240 | 13.8 | 0.68 | 0.18 | 0.64 | 2.95 | 21 / 39 | 21 / 39 |
| f, 320x180 | 18.3 | 1.10 | 0.20 | 0.75 | 3.39 | 29 / 52 | 27 / 57 |
| demand + dirty + wake, 320x180 | 12.4 | 0.67 | 0.21 | 0.60 | 2.87 | 17 / 34 | 19 / 35 |
| f, 214x120 | 18.2 | 1.10 | 0.20 | 0.76 | 3.45 | 29 / 59 | 28 / 57 |
| demand + dirty + wake, 214x120 | 12.7 | 0.68 | 0.21 | 0.63 | 2.96 | 19 / 33 | 19 / 36 |

- Paper is idle (0.1 to 0.2 cores) and waits on client acks: lost to other attempts' acks 49 to 60 s per 1,000 with
  frames at 854x480, against 3 to 4 s without frames.
- One client alone drew a lavapipe frame in about 6 ms (P4); four together take 35 to 49 ms per tick at the same size.
- Stream size: 2,210 records, 287 KB per 1,000 requirements (1,900 and 2,794 at 0 and 30 percent groups), the same
  in every setup. Building and encoding a record: 0.02 to 0.05 ms.

## Determinism

| What | Result |
|---|---|
| Records until the verdict, per requirement and member, across 3 jobs and repeats (10 % groups) | 1,000 of 1,000 identical in every setup |
| The same across levers and window sizes | identical: 100 broken members with 1 record (the reset frame), 1,055 with 2 (reset, token) |
| 0 % and 30 % groups | identical across jobs (900 and 1,347 members with 2) |
| Verdict per requirement across jobs, levers, windows | identical |
| Token text a check read at 427x240, 320x180, 214x120 against 854x480 | identical; same verdicts and record counts |
| Tick label of the token record, two identical runs | 80 to 83 percent equal |

## Surprises

- **Four lavapipe clients are not four times one.** P4 measured about 6 ms per frame for one client; with four, a
  frame costs about 40 ms of client CPU and the runner is saturated. Frame cost, not the stream, decides everything.
- **A record's tick label is not "as of that tick".** A client that is not claimed does not gate ticks, so it falls
  up to 4 ticks behind Paper. When its requirement starts it handles every queued packet at the head of a loop but
  runs one tick per loop, so the token record can carry a tick from before the stimulus (offsets −2 to +8; 17 to 20
  percent of labels differ between identical runs). Counts and verdicts stay exact; a check that asks "by tick N"
  needs clients that keep up, or a record stamped with the last packet's tick (**inferred**).
- **Demand frames are a lever for B, not A.** On a shared Paper every client is almost always in an attempt.
- **Without a reset the chat section grows without bound.** The ack verdict variant never resets the stream: 4.5 MB per
  1,000 requirements against 287 KB with a reset per requirement (P4 noted the requirement scope must reset it).
- **Shrinking the window changed nothing a chat check reads**, down to 214x120 (GUI scale 1). Titles, tooltips, the
  sidebar and long action bar lines were not checked; at 214 pixels wide they will clip or wrap (**inferred**).

## Rerun

Build from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :step-agent:jar :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, `SDL_MAC_BACKGROUND_APP=1` (development only; no Mac number is used above):

```
python3 orchestrator/run.py prepare
python3 orchestrator/frames.py run --instances "default;w=320x180" --n 1000
python3 orchestrator/frames_report.py runs/frames.jsonl
```

CI: `.github/workflows/gv-frames-prototype.yml`, matrix `{ plan: frames, repeat: 0|1|2 }`; `FRAMES_INSTANCES` lists the
client setups (`lp=N`, `bg=N`, `w=WxH`, comma joined), `FRAMES_ARGS` the variant plan (`variant@groups`).
