# C: how low can seconds per requirement go

## Answer

- **6 ms per requirement** on one real client and one real Paper, for a trivial requirement: 5000 in 28.6 s, median 5.6 ms, p95 7.1 ms, 0 wrong verdicts, clean state confirmed after every requirement. Verdicts come from client facts, not pixels.
- **Realistic floors**, from most to least shortcut. The steps are per requirement, trivial scene, load 10 to 30:

| Recipe | Median | p95 | 500 requirements |
|---|---|---|---|
| Same place, commands bypass the tick, render gated | 0.006 s | 0.008 s | 3 s |
| Same place, real tick commands, server rate 200, render gated | 0.010 s | 0.015 s | 5 s |
| Same place, real tick commands, 20 TPS | 0.100 s | 0.106 s | 50 s |
| New world from a pool of 8, rate 200 | 0.060 s | 0.083 s | 32 s |
| New world from a pool of 8, 20 TPS | 0.450 s | 0.456 s | 225 s |

- **The 3 second limit is not at risk from reset, render or observation.** What remains is the requirement's own duration: a 3 s title stays 3 s unless the clock runs faster (C2), and the legacy cinematic clock does not follow the tick rate (inferred from source, see C2).
- **Biggest wrong verdict risk is the fast fail.** The barrier decides a fail in 2 to 6 ms, but it gave **95 wrong fails out of 95** when the server showed the thing one tick after the barrier. See "Fail decisions".

Machine for every number: M1 Max, 10 cores, JBR 25.0.3, OpenGL 4.1 on Metal, 1708x960 framebuffer, render distance 2, void world, other work running. Load is the 1 minute average. No Gradle build overlapped a timing run. Medians are over one run of the stated size; "×3" means three runs. Rate means Bukkit `setTickRate`.

## What a requirement was

Arrange a clean place, server shows one thing (cycle: title, chat line, per player block, packet only entity), client confirms over a live socket, cleanup, then read the client's state behind a barrier and assert nothing is left. Every 20th requirement is deliberately broken: the server shows nothing. Tokens are unique and block materials cycle, so a leftover cannot pass the next check.

Three things were added for speed, beyond the reset itself:

- **Live channel in the mod** (`Speed.java`). `observe` wakes on each published frame or tick, so detection does not depend on polling a file.
- **Barrier**: vanilla `ClientboundPingPacket`, seen through a mixin on `handlePing`. TCP order means everything sent before it has been handled. No custom channel.
- **Dispatch**: `tick` uses the Bukkit scheduler and waits for the next tick. `direct` uses `MinecraftServer.execute`, which runs between ticks. `direct` is a test driver shortcut; a real plugin behaviour that schedules on a tick cannot use it.

## C3: reset approaches

Tuned Paper unless stated (see "Paper limits"). Seconds per requirement including arrange, act, observed, cleanup. Passing requirements only.

| Approach | Runs | Median | p95 | Max | Arrange ms | Load | Wrong | After broken passes | Dirty after cleanup |
|---|---|---|---|---|---|---|---|---|---|
| R4 same place, tick | 200 ×3 | 0.100, 0.100, 0.100 | 0.105 to 0.107 | 0.116 | 0 | 15 to 19 | 0 | 27/27 | 0 |
| R4 same place, direct | 200 ×3 | 0.013, 0.014, 0.015 | 0.018 to 0.022 | 0.071 | 0 | 18 to 21 | 0 | 27/27 | 0 |
| R1 fresh region 64 chunks apart | 200 ×3 | 0.439, 0.441, 0.456 | 1.06 to 1.29 | 3.22 | 340 | 20 to 30 | 0 | 27/27 | 0 |
| R1p 8 prebuilt regions, reused | 200 ×1 | 0.400 | 0.409 | 0.532 | 299 | 21 | 0 | 9/9 | 0 |
| R3 pool of 8 void worlds | 200 ×3 | 0.450, 0.450, 0.450 | 0.455 to 0.456 | 0.51 | 350 | 14 to 32 | 0 | 27/27 | 0 |
| R5 reconnect | 200 ×3 | 0.550, 0.550, 0.550 | 0.555 to 0.599 | 0.74 | 450 | 10 to 22 | 0 | 27/27 | 0 |
| R2 new world per requirement | 200 ×2 | 0.498, 0.749 | 0.70, 1.25 | 4.57 | 401, 673 | 10 to 31 | 0 | 18/18 | 0 |
| R1 fresh, stock Paper | 100 ×1 | 0.850 | 0.904 | 1.50 | 750 | 22 to 29 | 0 | 4/4 | 0 |

Across every `c3` run in this spike, 18050 requirements outside the deliberate late test: **0 wrong verdicts, 0 dirty cleanups.**

Notes:

- R1 fresh has a long tail and hurts the server: 170 to 200 percent server CPU, TPS 18.6, RSS 1.7 GB, send to seen up to 643 ms. Reusing regions (R1p) removes all of that. Inference: chunk generation and unload work on the server.
- R2 create takes 300 to 550 ms on the main thread, so TPS falls to 10 to 17. Worst approach, and it interferes with anything else on that server.
- R3 pool setup: 8.5 to 10.7 s once, RSS 1.46 GB.
- All approaches hold steady over 200 at this load. Soak on the best recipe: no drift over 5000.

### Paper limits were hiding the reset cost

Arrange in R1 went from 750 ms to 300 ms by config only:

```
chunk-loading-basic.player-max-chunk-send-rate: -1    # default 75 per second
chunk-loading-basic.player-max-chunk-load-rate: -1    # default 100 per second
view-distance=3, simulation-distance=3, sync-chunk-writes=false, network-compression-threshold=-1
```

Trace of one R1 move after tuning, client side: position at 40 ms, old chunks dropped at 44 ms, first chunk at 136 ms, then one batch per server tick, player section ready about 300 ms. So the rest is **tick bound**, which is why C2 cuts it to 48 ms.

### Leftovers

Each round leaves one of everything, then applies only the approach's own reset. 6 of 6 rounds per cell. Load 16 to 21.

| Leftover | R1 teleport | R2, R3 world swap | R4 no move | R5 reconnect |
|---|---|---|---|---|
| Title, still in fade | leaks | leaks | leaks | cleared |
| Action bar | leaks | leaks | leaks | leaks |
| Chat | leaks | leaks | leaks | new join line |
| Packet only entity | **leaks after 64 chunks** | cleared | leaks | cleared |
| Real entity | out of range | cleared | leaks | leaks |
| Potion effect | leaks | leaks | leaks | leaks |
| Inventory | leaks | leaks | leaks | leaks |
| Velocity | gone | gone | leaks, and it moves the player | gone |

- **No approach is clean by itself. Moving saves nothing on leftovers.** Reset packets, a server side player clean and a client chat clear gave zero leftovers in all rounds of all approaches.
- **Chat can only be cleared by the mod**: `mc.gui.hud.getChat().clearMessages(false)`. There is no server packet. Not tried: pushing with blank lines.
- A packet only entity leak after a far teleport is a trap: the server never told the client to forget it.
- Not valid or not tested: fire (creative ignores it, always false). Block in the R4 column of this probe (velocity moved the player, and the watched block is relative); block cleanup is covered by the 200 requirement runs. Position after a velocity leak: the clean does not restore it, so a same place recipe must also teleport home. Not checked at all: bossbar, scoreboard, tab list, open screens, spectator camera, world border, weather, gamemode, game rule changes, real blocks, sound.
- R4 shares the place, so **it only suits requirements that leave no real world changes**. Real blocks or mobs need a move, or undo logic.

### A wait that really covers chunks

Screenshot right at each signal, compared to the same view later, pixel difference over 8 of 255. 5 rounds per signal, 4 for `settledAt`. One R3 round per signal swapped into the world it was already in (a test bug, fixed after); it is the one right frame in each R3 count.

| Signal | R1 move | R3 world swap |
|---|---|---|
| Nothing | 608k pixels differ | 1.6M |
| `LevelLoadingScreen` gone | not used | Gone **4 ms** after the swap, before any chunk |
| `hasRenderedAllSections` | not retested, S0 found it useless | not retested |
| All radius chunks on client (`readyAt`) | 3 of 5 frames wrong, 12k to 31k pixels | 4 of 5 wrong |
| Feet section compiled (`compiledAt`) | 0 of 5 wrong | still wrong, see below |
| 3x3 sections around the feet compiled and queue empty (`settledAt`) | **identical in 3 of 4 rounds**, about 230 ms | changes for up to 3 s |

- Facts only (no pixels): `readyAt` is enough and needs no rendering. Rule: position in the signal includes dimension and chunk, so a stale ready cannot pass.
- `settledAt` in R1 rounds 2 to 4 gave exactly 0 pixels difference against 3 s later. Round 1 of every session took up to 3 s to settle; cause not looked at.
- **After a new level the frame keeps changing**: R3 72k to 330k pixels for 0.4 to 3 s, R5 115k pixels for 0.4 s. Frames show the first person hand absent and the fog and sky different. Inference: hand raise animation plus an atmosphere fade. Not separated.
- So: **goldens want same world moves.** R3 and R5 add 0.4 to 3 s per golden frame unless a later spike finds the cause.
- A toast ("Chat messages can't be verified") and the join chat line sit in frames for about 6 s after join. Matters for F.
- This corrects S0's note that the `LevelLoadingScreen` exit is a useful signal: on a world swap it is not.

## Fail decisions

Every 20th requirement shows nothing.

| Method | Time to decide a fail | Passes wrongly failed | Note |
|---|---|---|---|
| Barrier, 20 TPS or direct | 2 to 6 ms, gated about 2 ms | 0 of 12730 | Only when the effect is sent before the barrier |
| Timeout 30 ms, gated, R4 | 31 ms | 0 of 3800 | Load 12 to 15 |
| Timeout 100 ms, R4 direct | 101 ms | 0 of 190 | Load 19 |
| Timeout 250 ms, R4 direct | 251 ms | 0 of 190 | Load 20 |
| **Barrier, effect one tick late** | 4 ms | **95 of 95** | Every pass became a fail, and 78 of 100 cleanups were dirty |
| Timeout 150 ms, effect one tick late | 151 ms | 0 of 95 | Seen at 58 ms median, 105 ms max |

- **A barrier only proves what was already sent.** A real behaviour that runs a tick later is failed wrongly. A requirement must state its window: the barrier goes after that many ticks, not right after the trigger. Otherwise a fail verdict cannot be trusted.
- Same for cleanup: it does not cancel scheduled server work. Late effects land in the next requirement. The framework needs to know a behaviour has finished.
- Largest send to seen over all passes: R4 direct gated 15 ms in 4750; R4 tick 28 ms; **R1 fresh 643 ms**. A short timeout is safe only on a recipe that does not stall the server.
- Observation timeout in all barrier runs: 2000 ms, never reached.

## C1: render on demand

The seam, in `speed/mixin/RenderGateMixin.java`, three redirects inside `Minecraft.renderFrame`:

```java
// no acquired texture: blit and present skip themselves, both check isAcquired
if (!Speed.decideFrame()) surface.acquireNextTexture();
if (!Speed.skipExtract()) renderer.extract(delta, advance);   // mode 2 only
if (!Speed.skipRender()) renderer.render();
```

Plus a park of 2 ms at the end of a skipped frame; without it the loop spins at 33000 per second.

### Gate mode must also skip extract

**Mode 1 (skip render, keep extract) loses world updates for good.** `LevelExtractor.java:176` clears the dirty flag at extract and compile runs only in render (`LevelRenderer.java:299`). Measured: the facts say `gold_block`, and 0.8 s after opening the gate the frame has 0 gold pixels, against 50444 in mode 2. Mode 2 is the only valid gate. This is also a lying scene for axis A.

### CPU and latency

Client process CPU, 10 s windows, 3 rounds, facts on change, load 8 to 15. Excludes GPU and the window server. Send to seen over 90 samples.

| Mode | CPU percent | Loop per s | Client TPS | Send to seen median, p95 ms | Same content |
|---|---|---|---|---|---|
| Unlimited | 103, 65, 59 | 510 to 642 | 20 | 3.2, 5.5 | base |
| 60 FPS | 25, 20, 22 | 60 | 20 | 32.8, 33.2 | yes |
| 20 FPS | 11, 10, 10 | 20 | 20 | 50.8, 53.8 | yes |
| Gate 1 | 16, 19, 15 | 360 to 400 | 20 | 2.6, 3.5 | yes (facts lie, see above) |
| **Gate 2, park 2 ms** | 11, 15, 13 | 380 to 406 | 20 | **2.5, 3.7** | yes |

Park sweep, 2 rounds, load 8: no park 135, 128 percent and 0.63 ms; 0.2 ms 32, 30 percent and 0.67 ms; 1 ms 16 percent and 1.4 ms; 2 ms 15 percent and 2.6 ms; 5 ms 11 percent and 6.1 ms.

- **A gated client beats unlimited rendering on both CPU and latency.** 20 FPS costs about the same CPU but 20 times the latency, because packets are handled once per frame. So plain low FPS is the wrong tool: R4 direct is 0.100 s at 20 FPS and 0.050 s at 60 FPS, against 0.006 s gated.
- Same content: title, subtitle, fades, action bar, chat, block, standing block, effects, inventory, position, entity text all equal in every round.
- GPU load gated: not measured. Inference: near zero, since nothing is submitted.

### Turning rendering back on

Draw exactly k frames while gated, save the frame, compare with a stable frame. Mode 2, 3 rounds per row, load 8 to 10.

| Frames | Drawn ms | PNG written ms | Pixels off |
|---|---|---|---|
| 1 | 4 | 81 | 150k, 166k, 166k (block not meshed yet) |
| 2 | 7 | 85 | 162k to 167k |
| 3 | 8 | 88 | 0, 15k, 16k |
| 5 | 11 | 94 | 7k, 16k, 16k |
| 10 | 21 | 101 | 0, 19k, 0 |
| **30** | **54** | **131** | **0, 0, 0** |

- **A correct frame needs 54 ms of drawing, 131 ms including the PNG**, so a pixel checked requirement is about 0.14 s. The 80 ms from draw to PNG: inference, mostly PNG encoding and read back. Axis B can look at raw frames.
- Use a condition, not a frame count: frames 3 to 10 are wrong sometimes. Not built: wait until the queue is empty and the dirty list is drained.

### What breaks while gated

- **Section compile stops**: `readyAt` arrives in 212 ms, `compiledAt` never within 3 s. Opening the gate gives it in 30 ms. Use `readyAt` while gated.
- **Not stuck, against what source suggested**: a world swap while gated finishes, about 300 ms, no errors. One ungated swap read 32 ms, not explained, n=1, not seen in any R3 run.
- Stale while gated by reading the code, not tested: the camera in facts, anything on the render state. Anything needing a drawn frame (A2, A3, A4) must open the gate.

### Best C3 approaches with the gate

| Recipe | Runs | Median | p95 | Client, server CPU | Wrong, dirty | Load |
|---|---|---|---|---|---|---|
| R4 direct, gate 2 | 200 ×3 | 0.0060 to 0.0063 | 0.008 | 84 to 106, 51 to 58 | 0, 0 | 10 to 14 |
| R4 direct, gate 2, soak | 5000 ×1 | **0.0056** | 0.0071 | 48, 21 | 0, 0 | 9 to 10 |
| R4 tick, gate 2 | 200 ×1 | 0.100 | 0.104 | 40, 11 | 0, 0 | 12 to 13 |
| R1p tick, gate 2 | 100 ×1 | 0.400 | 0.408 | 22, 23 | 0, 0 | 9 to 11 |
| R3 tick, gate 2 | 100 ×1 | 0.450 | 0.453 | 28, 18 | 0, 0 | 11 to 12 |

- At 20 TPS the gate cuts CPU, not time: the tick dominates.

## C2: faster clock

Both sides at a higher rate work. Server: `Bukkit.getServerTickManager().setTickRate`. Client: `TickCapMixin` drops the `Math.max(50, mspt)` cap at `Minecraft.java:2930`. Rate changes live, no reconnect.

Title 10, 40, 10, client elapsed. TextDisplay with teleport duration 20 ticks moving 10 blocks. 40 ticks of server driven path, one teleport per tick. 3 repeats each, load 8 to 11, values are the range.

| Condition | Client TPS | Frames per s | Title s (expected) | Interpolated move s (expected) | Tick path s (expected) | Worst distance from a straight line, blocks |
|---|---|---|---|---|---|---|
| Rate 20, stock client clock | 19.5 | 269 | 2.96 to 2.99 (3.0) | 0.99 to 1.00 (1.0) | 1.99 (2.0) | 0.04 to 0.14 |
| Rate 40 | 39.8 | 674 | 1.48 to 1.50 (1.5) | 0.50 (0.5) | 0.99 to 1.00 (1.0) | 0.08 to 0.12 |
| Rate 100 | 99.8 | 623 | 0.59 (0.6) | 0.20 (0.2) | 0.40 (0.4) | 0.09 to 0.18 |
| Rate 200 | 200.3 | 502 | 0.296 (0.3) | 0.10 (0.1) | 0.195 to 0.199 (0.2) | 0.12 to 0.26 |
| Rate 400 | 399.9 | 376 | 0.147 (0.15) | 0.05 (0.05) | 0.095 to 0.10 (0.1) | 0.32 to 0.44 |
| Rate 200, gate 2 | 199.6 | 309 | 0.296 (0.3) | 0.10 (0.1) | 0.20 (0.2) | 0.15 to 0.28 |
| Rate 200, 20 FPS | 198.4 | 20 | 0.254 (0.3) | 0.10 (0.1) | 0.20 (0.2) | sampling: 4.4 |
| Rate 200, 10 FPS | **99.4** | 10 | **0.503** (0.3) | **0.20** (0.1) | 0.20 (0.2) | sampling: 4.5 |
| Rate 200, client capped | 19.9 | 691 | **2.96** | **1.00** | 0.245 | 0.05 |
| Rate 40, client capped | 19.7 | 551 | **2.97** | **1.00** | 1.04 | 0.05 |

- **Viable, and coherent.** Client elapsed shrinks within about 1 percent. Moves never went backwards in any condition. Rate 200 screenshot shows the title correctly drawn. 0 server warnings, 0 client errors.
- **10 ticks per frame cap is real**: rate over 10 × FPS drops ticks and the client falls behind (rate 200 at 10 FPS gives 99 TPS). Low FPS and fast clock conflict; the gate does not, since its loop runs at 300 to 400 per second.
- `Bukkit.getTPS()` reports 60 to 220 during these runs, a rolling figure not meant for this. Do not use it as evidence.
- Client CPU at rate 200: 73 percent rendering, 36 percent gated. Server 19 percent.

### What it does to C3

| Recipe, server rate 200 | Runs | Median | p95 | Max | Arrange ms | Wrong, dirty | Load |
|---|---|---|---|---|---|---|---|
| R4 tick, client capped | 200 ×3 | 0.016 | 0.022 | 0.037 | 0 | 0, 0 | 9 to 11 |
| R4 tick, gate 2, 30 ms timeout | 2000 ×1 | **0.0102** | 0.015 | 0.032 | 0 | 0, 0 | 12 to 14 |
| R3 tick, client capped | 1000 ×1 | **0.0635** | 0.083 | 0.139 | 46 | 0, 0 | 14 to 18 |
| R3 tick, gate 2, both fast | 200 ×1 | 0.050 | 0.060 | 0.112 | 35 | 0, 0 | 12 to 15 |
| R1p tick, client capped | 200 ×2 | 0.065 | 0.115, 0.146 | 0.52 | 48 | 0, 0 | 14 to 16 |
| R1p tick, both fast | 200 ×2 | 0.065, 0.076 | 0.085, 0.105 | 0.75 | 51, 60 | 0, 0 | 14 to 17 |
| R5 tick, client capped | 100 ×1 | 0.153 | 0.206 | 0.291 | 133 | 0, 0 | 14 to 17 |

- **Raising only the server rate is the honest replacement for `direct`.** Real tick dispatch at 16 ms, nothing bypassed.
- **Isolation becomes cheap: a full new world per requirement at 60 ms.**

### Honest limits: what a faster clock changes

- **Tick driven things get faster. Wall clock things do not.** Toasts and sound are real time on the client by reading the code; not measured here.
- **Legacy cinematics would not speed up.** Frame comes from real elapsed time: `engine/engine-paper/.../interaction/PlayerSession.kt:61` to `:72` uses `System.currentTimeMillis` and `delay`, then `entry/temporal/TemporalInteraction.kt:41` computes `frame = playTime / 50`. A 3 s title inside such a cinematic would last 0.3 s at rate 200 while the cinematic still takes its full time, **a broken test that a real player never sees**. Inference from source, not run. If v1 cinematics count ticks they speed up; if they use wall time they do not. Worth deciding on purpose.
- **It changes what a test proves.** It proves ordering and tick counts, not real time duration, and not behaviour under normal server pacing. Things bound to milliseconds and ticks at once will shift relative to each other. A few requirements should still run at 20.
- **Client capped is not coherent for durations**: at server rate 200 a server path takes 0.245 s while a title takes 2.96 s. Fine for "did it appear", wrong for "does it end when the path ends".
- **Video**: at rate 200 and 500 FPS there are about 2.5 frames per tick and fades last 0.05 s. Recorded requirements probably run at 20, or capture per tick. For axis B.
- **Rate and freeze are server wide.** Every player on a Paper shares them. A requirement at 20 cannot overlap one at 200 on the same server, so parallel clients (D2) must agree on one rate or use several servers (D3). The client cap is per client, so a client out of step gets the incoherent row above.

## C4: micro server

Time boxed. Wall seconds to Done, existing void world, 512 MB heap, 3 boots, load 8 to 13.

| Paper | Boots | Median | RSS MB |
|---|---|---|---|
| Jar, stock settings | 7.69, 8.17, 8.30 | 8.17 | 1000 |
| Jar, tuned | 8.62, 7.81, 7.62 | 7.81 | 1010 |
| Direct classpath, no paperclip | 8.60, 7.38, 7.29 | 7.38 | 960 |
| Plus no nether, no end, no spark | 6.63, 7.09, 6.38 | 6.63 | 760 |
| Plus C1 only, SerialGC, no perf data | 6.36, 6.52, 6.54 | 6.52 | 657 |
| Trimmed, AOT without class linking | 4.43, 4.56, 4.93 | 4.56 | 835 |
| **Trimmed, dynamic AppCDS, 153 MB archive** | 4.25, 4.16, 4.22 | **4.22** | 843 |
| Same with C1, SerialGC, archive from G1 | 4.26, 4.26, 4.37 | 4.26 | 661 |

- `-XX:AOTCacheOutput` leaves a **0 byte file** without failing the training run. `AOTMode=create` fails while archiving heap objects: `Cannot archive the sub-graph ... ConcurrentHashMap`, on JBR 25.0.3, also with SerialGC. `-XX:-AOTClassLinking` works. Cause not looked at. Three rows ran with the empty file and are not in the table; a new world each boot at no cache was 7.86.

| Client, jar only classpath, 3 runs, load 9 | Title screen s | Load finished s |
|---|---|---|
| No cache | 9.76 to 9.88 | 11.8 to 11.9 |
| AppCDS, 102 MB | 9.36 to 9.88 | 11.4 to 11.9 |
| **AOT, 147 MB, 7.1 s to write at exit** | **7.89 to 8.21** | **9.9 to 10.2** |

- **Test, do not assume: Knot defeats it partly, not fully.** About 5100 of 17100 game classes came from the cache, and the JDK and libraries as well. Inference: the 5100 are `com.mojang` libraries on the app loader, and `net.minecraft` through Knot stays out.
- Directories on the classpath make the dump fail (`non-empty directory`), so the mod must come from its jar. Dev launch as generated by Loom cannot use a cache.
- **Per test: never.** 4.2 s against 6 ms is 700 times. **Per suite: affordable**: a fresh Paper at 4.2 s plus a client around 10 s, about 14 s if started together (inferred, not run together), for crash recovery or one clean server per suite.

## What broke, in one list

1. Barrier with a late effect: 95 of 95 wrong. Needs a declared window.
2. Gate mode 1 drops world updates for good while the facts still look right.
3. `hasRenderedAllSections` and the loading screen exit are not readiness. One section compiled is not enough after a new level.
4. New level frames keep changing for 0.4 to 3 s.
5. Paper's default chunk send rate cost 400 ms per move, silently.
6. R1 with fresh regions and R2 stall the server: send to seen up to 643 ms, TPS down to 10. A short timeout would misjudge there.
7. 10 ticks per frame cap against low FPS.
8. AOT cache output left a 0 byte file with no failure.

Not tested here: non trivial requirements, input stimuli, real Typewriter behaviour, pixels as the verdict, several clients, Linux or CI, Vulkan.

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Then, with `S=prototypes/game-verification/orchestrator/speed.py`:

```
python3 $S c3 --approach R4 --n 5000 --dispatch direct --gate 2                # best
python3 $S c3 --approach R4 --n 200 --rate 200                                 # best with real ticks
python3 $S c3 --approach R3 --n 1000 --rate 200                                # best with isolation
python3 $S c3 --approach R1 --n 100 --stock                                    # Paper defaults
python3 $S c3 --approach R4 --n 100 --late-ticks 1                             # barrier trap
python3 $S c3 --approach R4 --n 100 --late-ticks 1 --fail timeout --obs-timeout 150
python3 $S leak --approach R1 --rounds 6
python3 $S ready --approach R1 --rounds 5
python3 $S ready2 --approach R3 --rounds 4
python3 $S trace --approach R1
python3 $S c1 cpu --rounds 3 --seconds 10 --samples 30
python3 $S c1 cpu --rounds 2 --seconds 8 --samples 20 --park-sweep
python3 $S c1 frame --rounds 3 --keep-shots
python3 $S c1 broke
python3 $S c2 --rounds 3
python3 prototypes/game-verification/orchestrator/c4.py paper2 --repeat 3
python3 prototypes/game-verification/orchestrator/c4.py client2 --repeat 3
```

`c3` flags: `--approach R1|R1p|R2|R3|R4|R5`, `--dispatch tick|direct`, `--fail barrier|timeout`, `--obs-timeout ms`, `--gate 0|1|2`, `--park us`, `--rate`, `--uncap`, `--fps`, `--stock`, `--late-ticks`. Results append to `runs/c-speed.jsonl`. `c4.py paper` reproduces the rows without a cache plus the failed AOT attempts. `probe-plugin/build.gradle` holds an absolute path to a jetbrains annotations jar from the Gradle cache; fix it on another machine.

## Reuse in later spikes

- **Client** `probe-mod/.../speed/Speed.java`: socket on `-Dprobe.live.port`, one JSON line per request. `observe?needle=&ping=&timeoutMs=`, `state?ping=`, `clearChat`, `gate?mode=2&parkMicros=`, `oneshot?frames=&path=`, `shot?path=`, `fps?limit=`, `uncap?on=`, `reconnect?addr=`.
- **Facts** added in `Probe.perceived`: `ping`, `relBlock`, `under`, `pos`, `vel`, `effects`, `inv`, `dim`, `screen`, `chatCount`, `loaded`, `readyAt`, `compiledAt`, `settledAt`, entity `x` and `rx`.
- **Plugin** `probe-plugin/.../Speed.java`: socket on `-Dprobe.line.port`, request `tick/name?...` or `direct/name?...`, any command takes `ping=` for a barrier. `act`, `reset`, `dirty`, `region`, `poolInit`, `poolSwap`, `worldNew`, `tickrate`, `moveDisplay`, `moveTick`.
- **Orchestrator** `speed.py`: `Session` (context manager, asserts silence, stops everything), `Line`, `TunedPaper`, `Reset`, `leftovers`, `diff`, `cpu_seconds`. Always use `paper-global-tuned.yml`.

## What this means for the search (for the README keeper)

- **Performant is no longer the limiting criterion for reset, render or client count.** One client does 100 to 160 trivial requirements per second gated. Spend effort on Accurate and Flexible.
- **The real unknown is requirement duration.** The next useful number is how many requirements are bound to real time, and at what length. A title fade or a cinematic dominates everything measured here.
- **Decide for v1: tick clock or wall clock for cinematics and sequences?** It decides whether C2 applies. A tick clock makes long sequences testable in a tenth of the time; a wall clock does not.
- **E**: E1 barrier is excellent and dangerous. Requirements must declare a window; absence needs that window to be meaningful. `readyAt` for facts, `settledAt` for pixels in the same world.
- **A**: new lying scene, gate mode 1: facts say the block is there, no block drawn. Also a real one: the block is not drawn for the first frames after it arrives.
- **B**: a frame on demand costs 54 ms plus read back, so frames per requirement matters more than rendering itself. Recording and fast clock conflict.
- **D**: one client may be enough on this machine for facts. D is more about isolation and rate conflicts than throughput now. A shared rate rules out mixing 20 and 200 on one Paper.
- **F**: prefer same world moves for goldens. Hide or wait out the hand, toast and join line.
- **H**: the gate should matter far more on software rendering (inferred). Worth measuring first there.
