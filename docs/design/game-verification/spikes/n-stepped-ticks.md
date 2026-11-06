# N: the test runner steps ticks, the real client follows

## Answer

- **Yes, with a small Paper tweak (N2), not with vanilla's freeze (N1).** Paper's main loop waits for a
  permit from the runner instead of a deadline; between ticks it keeps handling packets and tasks exactly as
  it does while idle. The real 26.3 client freezes its own clock (`Util.timeSource`) and moves it by one tick
  per step ping that Paper sends at the end of each stepped tick, so **server and client ticks match one to
  one** (2000 of 2000 steps, 0 extra client ticks, Mac and runner).
- **The step policy:** grant tick n+1 only when the subject's client has acked tick n (a payload sent at the
  end of its own tick) and the subject's async work is quiet. Under it every verdict was right and **every
  main thread effect landed on the same step every time**: 0 wrong in 1200 mixed requirements, 375 of 375
  exact window cases (window k passes an effect k ticks late, window k−1 fails it), 10 of 10 hung requirements
  failed at the 1 s limit. The only wall clock left in a verdict is that hung work limit.
- **Faster than rate 200, not slower.** A lockstep tick (server tick, client tick, ack) costs **1.2 to 1.9 ms**
  on the Mac under load 10 to 30, about 500 to 800 ticks per second; the server alone steps in 0.05 to
  0.15 ms. A trivial requirement takes **2.9 ms to pass and 4.6 ms to fail** (window 2), against **7.0 ms** for
  C's recipe at rate 200 on the same rig, and 10 ms in C. A fail costs its window in ticks, never in wall time.
- **Block breaking works at full speed** once Paper's break clock counts ticks: break 200 of 200 and cancelled
  break 200 of 200, one event sequence each, **0.027 s per break** against J's 1.0 to 1.25 s at rate 20. With
  Paper's wall clock break timer left in place, stepped breaking fails (17 of 50). The runner first failed
  0 of 100: a rig bug (the client was gated while its startup loading overlay was still up), not a platform
  difference; fixed, the runner breaks **150 of 150 and cancels 150 of 150** (see Breaking on the runner).
- **Async work no longer needs a wall clock window.** Stepping waits for the work instead of counting it
  against ticks, so slow async work (50 to 150 ms) passes in its window of 4 every time (D needed a 1000 ms
  limit plus a quiet wait to stop the wrong fails). Effects sent *from* an async thread still race the tick
  that started the work by one step (seen at step 1 or 2), so effects should land on the main thread or the
  dispatcher should start work only between ticks.
- **What still runs on wall clock** is listed below. Four break a stepped suite unless handled: Paper's packet
  limiter (kicks a client stepped faster than about 170 ticks per second), the 30 s network read timeout and
  Paper's 60 s watchdog (both hit by a runner pause), and Paper's lag compensations (block break, eating,
  sprint jump). The tweak that handles the first and the block break is 4 method prefixes in Paper (106 lines
  as an agent, about 30 as a Paper patch, **inferred**) plus about 60 lines of step policy.

Machines: the developer's M1 Max (OpenGL 4.1 on Metal, gated client mode 2, 854x480, render distance 2, void
world; load 7 to 30, given per table; other work was running all along) and the free runner run
[42304863563](https://github.com/gabber235/Typewriter/actions/runs/42304863563) (`ubuntu-24.04`, x86, 4 vCPU, Vulkan on
lavapipe). Measured unless marked **inferred**.

## N1: vanilla freeze and step

`ServerTickManager.setFrozen(true)` for 2 s of wall clock, then `stepGameIfFrozen(10)` and 1 s of wall clock
(Mac, load 11.4):

| Counter | While frozen, 2 s | During the 10 step burst, 1 s |
| --- | --- | --- |
| Server tick count (`getTickCount`) | +43 | +20 |
| Bukkit scheduler (`getCurrentTick`, a timer task) | +42, +43 runs | +20 |
| Player ticks (`tickCount`, `getTicksLived`) | +43 | +20 |
| Paper's break clock (lag compensation tick) | +39 | +20 |
| World game time | +1 | +10 |

- **The freeze stops only the world** (entities other than players, block ticks, time). The main loop keeps
  ticking at 20 per wall second, and with it every plugin task, every player, every connection and Paper's
  break clock. A Bukkit timer task ran 43 times during the 2 frozen seconds.
- So N1 cannot make Typewriter's behaviour exact: its chains run on the Bukkit scheduler and on players, both
  of which the freeze leaves on wall clock. The `/tick step` machinery is not a runner clock.

## N2 as built

**Paper side**, a Java agent (`step-agent`, ClassFile API, 4 method prefixes, each a no-op until the runner
switches stepping on):

| Method | Prefix while stepping |
| --- | --- |
| `MinecraftServer.recordTaskExecutionTimeWhileWaiting` (Paper's real between tick wait, not `waitUntilNextTick`) | `waitingForNextTick = true; while (!Step.take()) { if (!pollTask()) Step.idle(); }` |
| `MinecraftServer.waitForTasks` | `Step.idle()`: run the policy hook, park 50 µs or until a permit |
| `MinecraftServer.haveTime` | true while no permit is pending (between ticks there is no deadline) |
| `ServerLevel.currentLagCompensationTick` | `MinecraftServer.currentTick` instead of `(System.nanoTime() - SERVER_INIT) / 50 ms` |

Plus: when stepping is switched off, Paper's tick schedule is reset (`nextTickTimeNanos = now`,
`initTickSchedule()`), otherwise Paper's own loop waits until wall clock catches up with the ticks already
stepped (1 s after 20 fast ticks, measured).

**Step policy** (plugin `N.java`, on the main thread on every idle pass between ticks):

1. at `ServerTickEndEvent`, send the subject a vanilla `ClientboundPingPacket` with id `2^30 + tick`;
2. grant the next tick when the client's `probe:step` ack for that tick has arrived (custom payloads are
   handled in order on the main thread with all other packets of the client), and
3. the subject's counted async work is quiet: running, or handed to the Bukkit async scheduler by a tick that
   already ran (Bukkit async tasks start at the next tick's heartbeat, so counting them before that would
   deadlock); pending sync tasks never block, since they need ticks;
4. after `limitMs` (1000) of quiet waiting, interrupt the subject's async work and count it hung.

**Client side** (mod `n/N.java`, 2 mixins, about 130 lines): `Util.setTimeSource(() -> virtNanos)`; a step
ping (handled at the head of `Minecraft.runTick`, before the delta tracker reads the clock) adds exactly 50 ms;
after that client tick the client sends `probe:step(tick, needle seen, client ticks)`. Packets keep being
handled every loop. A mixin on `PacketProcessor.scheduleIfPossible` unparks the gated render thread when a
step ping arrives.

A requirement is one round trip: `n.watch?needle` to the client, `n.req` (the stimulus, between ticks), then
`n.run?max=w` which steps up to w ticks under the policy and returns at the first ack that saw the token.

## Cost of a step

2000 steps per row, gated client, Mac, load 10.2 to 11.1.

| Client gate park | Policy | ms per tick | of which ack wait | Client ticks per step | Client loops per step |
| --- | --- | --- | --- | --- | --- |
| 2000 µs | server only | 0.152 | 0 | 0 | 0.06 |
| 2000 µs | lockstep (ack) | **1.73** | 1.45 | 1.000 | 1.04 |
| 200 µs | server only | 0.089 | 0 | 0 | 0.3 |
| 200 µs | lockstep | 1.90 | 1.63 | 1.000 | 2.6 |
| 0 (spin) | server only | 0.050 | 0 | 0 | 1.4 |
| 0 (spin) | lockstep | **1.19** | 1.06 | 1.000 | 3.6 |

- Most of a lockstep tick is the client's own tick: 0.6 to 1.0 ms from the step being taken to the ack being
  sent; the ping wakes the gated render thread within 0.08 to 0.3 ms, so the gate's park barely matters.
- The server alone runs 6,500 to 20,000 ticks per second in the void world with one player. A requirement
  whose subject has no client (pure server work) could step at that rate (**inferred**).
- Runner: see "Runner" below.

## Requirements under stepping

Every fifth repeat is broken (no effect, async work still runs). Windows are E's and D's, not tuned: chat 2,
late k + 2, async 4. Mac, 200 rounds of each kind, load 21.8 to 29.8 (run 1200 requirements in 35.7 s).

| Kind | n good, broken | Wrong | Step the client saw it (good) | Effect tick after stimulus | Quiet wait median ms | Seconds median (p95) |
| --- | --- | --- | --- | --- | --- | --- |
| chat now | 160, 40 | 0 | 1: 160 | 0: 160 | 0 | pass 0.0029 (0.0092), fail 0.0046 (0.0105) |
| late k = 1 to 8 | 160, 40 | 0 | k: 20 each | k: 20 each | 0 | 0.003 (k=1) to 0.017 (k=8) |
| async on own dispatcher, 0 to 20 ms | 160, 40 | 0 | 1: 160 | 0: 160 | 12.8 | 0.016 (0.027) |
| Bukkit async, 0 to 20 ms, chat from the async thread | 160, 40 | 0 | **2: 156, 1: 4** | 1: 160 | 11.3 | 0.017 (0.027) |
| Bukkit async, 50 to 150 ms | 160, 40 | 0 | 2: 160 | 1: 160 | 100 | 0.108 (0.155) |
| Bukkit async, then a sync task | 160, 40 | 0 | 2: 160 | 2: 160 | 9.0 | 0.016 (0.029) |
| hang (10 min sleep) | 0, 10 | 0 | never | | 1000 | 1.015 (1.067) |

Fixed async durations, 100 rounds, Bukkit async with the chat sent from the async thread:

| Work | Seen at step 1 | Seen at step 2 | With a sync hop instead |
| --- | --- | --- | --- |
| 0 ms | 79 | 1 | step 2: 80 of 80 |
| 2 ms | 1 | 79 | step 2: 80 of 80 |
| 10 ms | 1 | 79 | step 2: 80 of 80 |

- **Main thread effects are exact.** The effect tick and the step the client saw it are the same in every
  repeat of every kind whose effect is sent on the main thread, including work that waited 150 ms of wall clock.
- **An effect sent from an async thread races by one step.** The work starts at a tick's heartbeat and runs
  while that tick finishes; whether its packet leaves before or after the step ping is a race between two
  threads (0 ms work usually wins, 2 ms work usually loses). Seen once in 80 the other way even for 10 ms work:
  the client handles all packets that arrived before its tick, so a packet that left just after the ping still
  counts for that step (**inferred** from the order of handling). Verdicts stay right because windows are
  never 1 tick tight for async kinds; exact timelines need effects applied on the main thread.

### Exact windows

Effect `late` ticks after the stimulus, window `w = late` and `w = late − 1`, 25 of each pair, `late` 1 to 8
(Mac, load 19.5): **375 of 375 right.** Every `w = late` passed at step `late`; every `w = late − 1` failed.
C's barrier trap (95 of 95 wrong when the effect came one tick late) cannot happen: a window counts the ticks
that really ran on both sides.

### Same requirement unstepped

C's R4 tick recipe on the same rig (agent loaded, stepping off), server rate 200, client uncapped, 500
requirements, Mac, load 21.6: **0.0070 s median, 0.0108 p95, 0 wrong.** Stepped: 0.0029 pass, 0.0046 fail.
At rate 200 a fail costs its window at 5 ms per tick (a window of 10 is 50 ms); stepped, 1.2 to 1.9 ms per tick.

## Block breaking

J's inputs through J2 (the client's own input handlers), probe focus and grab, gated, server and client in
lockstep (auto stepping: the policy grants every tick as soon as the client acked). Mac.

| Server clock | Break clock | n | Break ok | Cancelled break ok | Event sequences | Seconds per break median (p95) | Load |
| --- | --- | --- | --- | --- | --- | --- | --- |
| stepped | ticks | 200 | **200** | **200** | 1 and 1 | **0.027** (0.056) | 13.7 |
| stepped | wall clock (stock Paper) | 50 | 17 | 16 | 8 and 5 | 0.108 | 13.2 to 19.7 |
| rate 200 | ticks | 50 | 50 | 49 | 1 and 2 | 0.120 | 19.7 |
| rate 200 | wall clock (stock Paper) | 50 | 0 | 0 | 1 and 1 | 0.375 | 17.6 |
| rate 20, J | wall clock | 200 | 200 | 200 | | 1.0 to 1.25 | J |

- Paper's break clock (`ServerLevel.lagCompensationTick`, `ServerLevel.java:2896`, read by
  `ServerPlayerGameMode.gameTicks`) is `(System.nanoTime() - SERVER_INIT) / 50 ms`. That confirms J's
  inference: it is a Paper change, vanilla counts ticks. Tying it to `MinecraftServer.currentTick` alone fixes
  breaking at rate 200 too; stepping adds the exact, single event sequence and the speed.
- Server ticks per break operation (arrangement included) were 32 to 36; they vary because J's bench waits on
  wall clock between its own phases while auto stepping keeps ticking, not because the break varies.

## Pauses: the runner stops stepping

Stepping on, nobody grants a tick (Mac):

| Pause | What happened |
| --- | --- |
| 10 s | Paper's watchdog early warning: a full thread dump every 5 s ("The server has not responded for 10 seconds") |
| 35 s | **client dropped: "probe1 lost connection: Timed out"**; the next requirement fails |
| 70 s | Paper's watchdog: "The server has stopped responding!" at 60 s, then "Stopping server" |

- With no ticks the server sends nothing (keepalives are sent from the tick), the client sends nothing (it
  only sends from its own ticks), so both sides' 30 s netty read timeout fires.
- Under the policy a pause lasts at most the hung work limit (1 s) plus a client tick, so none of these
  triggers. A runner that holds the server longer (a debugger, a slow assertion in the test JVM) must keep the
  connection warm (send a keepalive while idle) and raise `timeout-time` in `spigot.yml` (**inferred**, not built).

## Runner

Run [42304863563](https://github.com/gabber235/Typewriter/actions/runs/42304863563): AMD EPYC 9V45, 4 vCPU,
Vulkan on lavapipe, load 2.2 to 4.9, job 421 s, no failed step and no leaked process.

| Measure | Runner | Mac |
| --- | --- | --- |
| N1 freeze, 2 s: server ticks, Bukkit tasks, players, break clock, world time | +40, +40, +40, +40, 0 | +43, +43, +43, +39, +1 |
| Server only step, ms per tick | 0.15 to 0.20 | 0.05 to 0.15 |
| Lockstep step, ms per tick | **1.22 to 1.31** | 1.19 to 1.90 |
| Client ticks per step | 2000 of 2000, 0 extra | 2000 of 2000, 0 extra |
| Mixed requirements, wrong | **0 of 600** | 0 of 1200 |
| Trivial requirement, pass and fail median | **0.0020 s and 0.0029 s** | 0.0029 s and 0.0046 s |
| Bukkit async, chat sent from the async thread: step 2, step 1 | 75, 5 | 156, 4 |
| asyncslow, asyncsync, asyncx: same step every repeat | 2, 2, 1 (80 of 80 each) | 2, 2, 1 |
| async 0 ms: step 1, step 2; with the sync hop | 27, 13; step 2 40 of 40 | 79, 1; step 2 80 of 80 |
| Exact windows | 187 of 187 | 375 of 375 |
| Unstepped rate 200 recipe, median | 0.0050 s, 0 wrong of 500 | 0.0070 s, 0 wrong of 500 |
| Hung requirement | 5 of 5 failed at 1.03 s | 10 of 10 at 1.015 s |
| Break, stepped, tick break clock: break, cancelled break | **0 of 100, 0 of 100** | 200 of 200, 200 of 200 |
| Break, stepped, wall break clock | 11 of 30, 5 of 30 | 17 of 50, 16 of 50 |
| Break, rate 200, tick break clock | **30 of 30, 30 of 30** | 50 of 50, 49 of 50 |
| 35 s pause | client dropped ("lost connection: Disconnected") | client dropped ("Timed out") |

- **Stepped breaking failed on the runner** (explained and fixed in Breaking on the runner). No `BlockBreakEvent` fired in any of the 200
  operations: the break script ran its full 60 client ticks (86 server ticks per break against 35 on the Mac)
  and the cancelled break its 20 (46 server ticks, the same as the Mac). The break clock did count ticks
  (`lagTicks` equals `serverTicks`), and the same runner with the same input path and the same tick clock broke
  30 of 30 at rate 200. So the fault sits in the client in step on Linux: J2 input (fake focus and grab) or the
  client's own break progress under the virtual clock. The rows did not keep their event logs and the server and
  client logs show nothing. Everything else matches the Mac.
- The pause text differs ("Disconnected" against "Timed out"); both are the dropped connection.

## What still runs on wall clock

Server sources from the patched Paper 26.3 jar (`paper-26.3-242`, decompiled with Vineflower into
`cache/paper-src/full`, line numbers of that output). Client sources from `.mc-sources`.

| Where | What | Under stepping | Handled here |
| --- | --- | --- | --- |
| `ServerLevel.java:2896` `currentLagCompensationTick` | Paper's block break clock | breaks fail (17 of 50) | yes, agent prefix |
| `Connection.java:218` packet limiter, `paper-global.yml` `packet-limiter.all-packets` 500 per s over 7 s | counts client packets per wall second | **kicked after about 1100 steps** ("Kicked for exceeding packet rate limit"): the client sends 2 to 3 packets per tick | yes, `max-packet-rate: 0.0` in the rig |
| `ServerCommonPacketListenerImpl.java:264, 272` keepalive every 1 s, kick after 30 s | sent from the tick | no traffic while paused | no, see Pauses |
| netty read timeout, 30 s, both sides | | client dropped after a 35 s pause | no |
| `WatchdogThread`, spigot `timeout-time` 60 s, early warning every 5 s after 10 s | time since the last tick start | stops Paper after 60 s paused | no |
| `LivingEntity.java:4101` eating lag compensation | finishes eating once `(1 + duration) * 50 ms` of wall clock passed | eating ends **early** in ticks if the runner waited (async work) during the eat; nondeterministic | no (**inferred**, not run) |
| `LivingEntity.java:2935` sprint jump boost | the forward boost needs 250 ms of wall clock since the last jump | stepped sprint jumps lose the boost: movement differs from a player | no (**inferred**, not run) |
| `ServerGamePacketListenerImpl.java:2110` spam limiter, `incoming-packet-threshold` | more than 8 use item packets within 300 ms wall are dropped | fast repeated right clicks may be dropped | no (**inferred**) |
| `ServerGamePacketListenerImpl.java:1594` moved too quickly allowance | allowance grows with wall clock | threshold only for large moves; walking is likely unaffected (J's walk passed at rate 200; not run stepped, **inferred**) | no |
| `ServerGamePacketListenerImpl.java:480` idle kick | minutes, off by default | none | no |
| `FoliaAsyncScheduler.java:99` Paper's async scheduler (`getAsyncScheduler().runDelayed`) | delays in wall time | a plugin's delayed async task fires by wall clock, not ticks | no; Typewriter's dispatcher must count it |
| `RegionizedPlayerChunkLoader.java:170` chunk send and load rate | per wall second | already off in the tuned config (`-1`) | config |
| `ClickCallbackProviderImpl.java:156` click callback lifetime | 12 h default | none | no |
| `TickLimiter.java` (spigot entity and tile tick budgets) | ms per tick | a slow tick skips entity work; not caused by stepping | no |
| `CraftPlayer` last played, first played, `PlayerList.loginTime` | timestamps | none for verdicts | no |
| client `FramerateLimiter`, sound engine (OpenAL), netty | real time | frame pacing and audio only; tests run silent and gated | no |
| client `ChunkBatchSizeCalculator`, `LevelLoadTracker`, toasts, boss bar easing, subtitles (`Util.getMillis`) | follow the virtual clock | a world swap or reconnect needs ticks to finish loading, so joins run in auto stepping | by the virtual clock |

## Surprises

- **Paper's main loop no longer waits in `waitUntilNextTick`.** Moonrise replaced it with
  `recordTaskExecutionTimeWhileWaiting`; a prefix on the old method alone did nothing.
- **Paper's packet limiter is the first wall clock wall a fast lockstep hits.** At about 400 steps per second
  the client's per tick packets (movement, client tick end, the ack) exceed 500 per second and Paper kicks it,
  silently from the runner's view (the server waits for an ack that never comes). Rate 200 sat just below it.
- **Turning stepping off stalls Paper.** Its tick schedule had advanced one period per stepped tick, so its own
  loop waited for wall clock to catch up (1 s after 20 steps measured; about 50 s after 1000, **inferred**).
- **A managed block inside a tick also idles.** Without a "between ticks" flag the policy could grant the next
  tick while a tick was still running (chunk waits call `waitForTasks`).
- **The first agent changed nothing in `MinecraftServer`**: four `transformingMethods` chained with `andThen`
  applied none of the prefixes (cause not looked at); one transform over a method map applied all four. The
  agent prints each prefix it applied, and the orchestrator reads that from Paper's log.
- **Stepped breaking passed every time on the Mac and never on the runner**, while rate 200 broke on both. The
  cause was the rig's readiness check, not the platform (see Breaking on the runner).
- **The vanilla freeze looks like a stepped clock but is not**: plugin tasks and players keep their wall clock
  rate.

## What this means for the search

- **Rate grouping goes away for facts and mining.** One stepped Paper runs every requirement at its own pace:
  no rate 20 group for block breaking, no rate 200 group for the rest. J's "breaking runs at rate 20" and C's
  "rate is server wide" stop being constraints on facts. Frames still need drawn frames, but the render rate
  no longer couples to the server rate: the runner steps a tick after the frames it wants (B4's fixed step
  becomes "advance the client clock by a frame interval, step the server every 50 ms of client clock",
  **inferred**, not built).
- **The async fail rule simplifies.** D's rule (fail when the window barrier arrived and the player's work is
  quiet, with a 1000 ms wall limit) becomes: step only when the subject's work is quiet; fail when the window's
  ticks have run. The window no longer shrinks against wall clock work, so it never needs sizing for the rate.
  The 1000 ms limit stays, only for hung work. The requirement on Typewriter is unchanged and stronger: every
  async path must be counted with its subject, and effects should land on the main thread (or the dispatcher
  starts work only between ticks) so timelines are exact.
- **Windows are exact.** E3t's window barrier is now the tick count itself; a window of k passes an effect at
  tick k and fails at k−1 every time. The E3t pass is unchanged (pass at the first ack that holds the fact).
- **Every runner command that waits for "the next tick" needs a step.** Bukkit `callSyncMethod` and the probe's
  `tick/` dispatch hang while stepping unless the policy is in auto mode; direct (`MinecraftServer.execute`)
  calls run between ticks.
- **Parallel clients on one Paper share the clock.** With several subjects the policy waits for all their acks
  (**inferred**, built for one subject only); D's 2 Papers with 4 clients becomes a question of how slow the
  slowest client tick is, not of rate.
- **Deviations from a real server are now explicit**: async work takes zero ticks, lag compensations are tick
  based or off. A few requirements should still run unstepped at rate 20, as C said.
- **Cost**: about 1.5 ms per tick per requirement tick, so requirement duration in ticks matters again: a 3 s
  title (60 ticks) is about 0.1 s stepped against 0.3 s at rate 200 (**inferred** from the step cost).

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :step-agent:jar :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, one at a time, `SDL_MAC_BACKGROUND_APP=1`:

```
python3 orchestrator/n.py freeze
python3 orchestrator/n.py steps --n 2000 --park 2000,200,0
python3 orchestrator/n.py req --n 200
python3 orchestrator/n.py req --n 100 --kinds async,asyncsync --async-ms 0      # also 2, 10
python3 orchestrator/n.py req --n 10 --kinds hang,chat
python3 orchestrator/n.py exact --n 200
python3 orchestrator/n.py base --n 500
python3 orchestrator/n.py break --n 200 --lag tick
python3 orchestrator/n.py break --n 50 --lag wall
python3 orchestrator/n.py break --n 50 --lag tick --mode 200
python3 orchestrator/n.py pause --seconds 35                                     # also 70
```

Results append to `runs/n.jsonl`; each command copies Paper's and the client's log to `runs/n-logs/`. CI: matrix
row `{ plan: stepped, backend: vulkan, runner: ubuntu-24.04, repeat: 0 }` runs `orchestrator/ci.py plan stepped`.
Paper sources for the wall clock list: `java -jar vineflower-1.12.0.jar -dgs=1 cache/patched/versions/26.3/paper-26.3.jar cache/paper-src/full`.

## Reuse

- **Paper** `step-agent/` (`Agent`, `Step`): `-javaagent:step-agent-0.jar=lag=tick|lag=wall`; `Step.on`,
  `Step.grant(n)`, `Step.hook` (the policy, main thread, between ticks only), `Step.tickClock`.
- **Plugin** `probe-plugin/.../N.java`: `n.mode?on&subject&ack&quiet&auto&limitMs&lag`, `n.req?kind=chat|late|
  asyncx|async|asyncsync|hang`, `n.run?max&stopOnSeen` (blocking, off the main thread), `n.stats`, `n.freeze`
  (N1 probe), `resetSchedule`.
- **Client** `probe-mod/.../n/N.java`: `n.mode?on` (virtual clock), `n.watch?needle`, `n.stats`, `n.resend`;
  `StepTickMixin` (head of `runTick`, tail of `tick`), `WakeMixin` (`PacketProcessor.scheduleIfPossible`);
  `PingMixin` routes ids from `2^30` to it.
- **Orchestrator** `orchestrator/n.py`: `Rig` (K's rig plus the agent, packet limiter off, logs kept),
  `step_on`, `steps_run`, `one_req`; `ci.py cmd_stepped`.

## Breaking on the runner

**Cause: a rig bug, not a platform difference.** K's join waited for "no screen, level, chunks, hands drawn"
and then gated the client. The startup `LoadingOverlay` is not a screen: it can still be fading out after the
player is in the world. While an overlay is up, `Minecraft.tick` skips `handleKeybinds`, so the attack key never
reaches `startAttack` or `continueAttack`. The overlay removes itself only inside a drawn frame
(`LoadingOverlay.java:150`, `fadeOutAnim >= 2.0`, 2000 ms of `Util.getMillis`), and a gated client draws no
frames (and a stepped one has its clock moved only 50 ms per tick), so it stayed for the whole run. Whether it
was gone at gating time is a race with client start up: the Mac usually won it, the slower lavapipe runner
always lost it.

Evidence, both sides traced (client: one token per client tick plus every player action packet sent; server:
packets on arrival with `gameTicks`, `destroyProgressStart`, ground, then the events):

| | Client per tick | Packets sent | Server |
| --- | --- | --- | --- |
| failing row (Mac, 3 of 5 fresh rigs before the fix) | `ov=LoadingOverlay miss=10000 down=0 d=0 p=0.00` for all 60 ticks | none | no `PlayerAction`, no `BlockDamageEvent`, no `BlockBreakEvent` |
| passing break (Mac, after the fix) | `down=1 d=1`, progress 0.33, 0.50, 0.67, 0.83 | `START_DESTROY_BLOCK#1` at client tick 97, `STOP_DESTROY_BLOCK#2` at 102 | START on step 260, `breakSpeed 0.1667 ground=true`, STOP on step 265 (`gt=265 start=260`: 6 × 0.1667 = 1.0), `BlockBreakEvent` |
| passing cancelled break | same | `START#3` at 129 | START on step 292, STOP on step 300, `BlockBreakEvent cancelled`, block restored |

- `missTime` is set to 10000 while a screen or overlay is up and reset only by `handleKeybinds`; `miss=10000`
  with the key up is the fingerprint. The server never saw a single break packet, so Paper, the break clock and
  stepping were never involved. Why the rate 200 rig on the same runner won the race every time was not
  measured (**inferred**: its overlay finished on the unfrozen clock before the first break).
- **Fix** (`ready/Ready.java`): the readiness fact `SCREEN_NONE` now also requires `gui.overlay() == null`, so
  every K based rig waits for the overlay before it gates. Mac, 6 of 6 fresh rigs passed after the fix against 2
  of 5 before.

Runner, CI run [42310014228](https://github.com/gabber235/Typewriter/actions/runs/42310014228) (plan
`breakstep`, x86, Vulkan on lavapipe, load 3.1 to 4.7), three fresh rigs of 50 each, stepped, tick break clock:

| Rig | Break ok | Cancelled break ok | Event sequences | Seconds per break median (p95) | Server ticks per op median |
| --- | --- | --- | --- | --- | --- |
| 1 | 50 of 50 | 50 of 50 | 1 and 1 | 0.034 (0.080) | 37 and 48 |
| 2 | 50 of 50 | 50 of 50 | 1 and 1 | 0.034 (0.072) | 37 and 48 |
| 3 | 50 of 50 | 50 of 50 | 1 and 1 | 0.031 (0.083) | 37 and 48 |
| **total** | **150 of 150** | **150 of 150** | | | |

No traced row on the runner showed the overlay. What this means for the search: a readiness check must cover
every layer that eats input (screens and overlays), and anything that removes itself in a drawn frame must be
gone before a client is gated. Rerun: `python3 orchestrator/n.py break --n 50 --lag tick --trace 1`, or the CI
plan `breakstep`.
