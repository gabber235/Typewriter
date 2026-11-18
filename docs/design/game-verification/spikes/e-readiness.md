# E: when a real client is ready, a scene arranged, a requirement done

## Answer

- **Start (client ready to test): level present, no screen, the framework clears toasts and chat, and the
  first person hands have settled** (hand height equal to the last client tick and attack strength full).
  This is the only start signal that matched the settled frame: 0 wrong in 100 Mac swaps and 30 runner swaps,
  wrong in 2 of 70 Mac reconnects and 3 of 16 on the runner (by 1 frame in terrain). It is wrong for a client
  process's first join (lighting still settles for about 0.5 s more, **inferred**) and after a reset that
  leaves the player moving, so the framework should warm a client once and reuse it. Every chunk and mesh signal (all radius chunks held, feet section compiled, render queue
  empty) fires 180 to 200 ms before the frame stops changing, because the hand rises and the attack indicator
  fills after the level is complete. Facts are ready earlier: a fact test started at "radius chunks held" was
  right every time; one started at join was wrong every time.
- **Arranged and verdict for a fact (E3t): read the fact on every client loop; pass the moment it holds; fail
  only when a window barrier arrives, sent by the server scheduler after the requirement's declared window in
  ticks.** 0 wrong verdicts in 2000 gated and 2000 rendered Mac repeats and 300 plus 500 on the runner, across
  every lying scene. A pass costs nothing over the truth; only a fail waits for the window. The plain barrier
  (E1) was wrong in 90 to 100 percent of repeats of every delayed scene, and a wall clock window (E3ms) was
  wrong in every lag repeat.
- **Done (the requirement's work has finished, for absence checks and the next requirement): E6, the plugin
  quiet barrier (no pending task, no running async worker) followed by a client loop where the client has
  nothing in flight** (radius chunks held, no title fading in, perceived state equal to the loop before). 0
  wrong everywhere, 2 to 4 ms over the bare barrier when nothing is pending. Server quiet alone (E4) is wrong
  for client side effects: a title fade (wrong 180 of 180) and chunk sending (wrong 180 of 180).
- **Pixel checks: after the fact verdict, wait for the object's own draw, plus an empty render queue and all
  radius chunks held (E3t + objq).** 0 wrong in every scene on both platforms, 0 ms past the pixel truth
  except a fresh chunk (46 ms). Fixed frame counts, two equal frames, and "entity render state built"
  each fail at least one scene.
- **Cost per requirement**: with the effect already present, E3t decides 2.6 to 3.1 ms after the command
  (gated Mac), 0.3 to 0.4 ms after the bare barrier, and E6 adds 2 to 4 ms; C's baseline is 5 to 10 ms per
  requirement. The quiet barrier polls 0.2 to 1 ms when the plugin is
  idle. Readback for pixel checks is 0.27 ms per frame on the Mac.

Machines: the developer's M1 Max (OpenGL 4.1 on Metal, 854x480, render distance 2, void world unless named,
load 6 to 31, given next to each table) and the free runner run
[42174196154](https://github.com/gabber235/Typewriter/actions/runs/42174196154) (`ubuntu-24.04`, AMD EPYC 9V45,
4 vCPU, Vulkan on lavapipe, Mesa 25.2.8, same options). Measured unless marked **inferred**.

## Signals as built

Every repeat records one trace that holds all signals at once, so every signal is judged on the same run.

| Id | Decides at | What it is |
|---|---|---|
| E1 | ack of a ping sent right after the command | the vanilla echo barrier |
| E1w | ack of a ping the server scheduler sends after the window `w` ticks | barrier after the declared window |
| E2 obj | first drawn frame after the object's own draw | section meshed with the block, in `visibleSections`, in `cullFrustum`, then the next drawn frame; entity extracted; GUI text at full alpha |
| E2 objq | E2 obj plus `hasRenderedAllSections` plus all radius chunks held | the render queue is empty too |
| E3t | first client loop where the fact holds, else fail at the E1w ack | poll, closed by a tick window |
| E3ms | first loop where the fact holds, else fail at `w x 50 ms` wall clock | poll, closed by a wall clock window |
| E4 | ack of a ping sent once the plugin has no task pending or running | server quiet |
| E5t1, E5t2 | E4 ack, then perceived state unchanged for 1 or 2 client ticks | server quiet plus a quiet client |
| E6 | E4 ack, then the first loop with radius chunks held, no title fading in, and perceived state equal to the loop before | server quiet plus nothing in flight on the client |

Perceived state is the hash of the client's perceived facts (spike A's A1 and A2 record), with clocks
stripped. Truth for facts is the client's own state each loop (block, chat line, title phase, entity in the view
cone). Truth for pixels is the first frame from which the scene's pixel rule holds in every later frame.

## The lying scenes

Every 10th repeat is broken (the effect never comes), so every signal is tested on fails too. A wrong verdict
is a pass on a broken repeat or a fail on a good one.

| Scene | Window | What lies |
|---|---|---|
| now | 2 ticks | nothing, control |
| late1 | 3 | chat line one tick later through the scheduler |
| late2 | 4 | two chained one tick tasks |
| async | 4 | Bukkit async task, sleeps 0 to 20 ms, then chat |
| section | 2 | 2x2x2 fake cube in an empty section two chunks ahead: held at once, meshed later |
| walk | 15 | text display spawned left of the view cone, walks in one block per tick for 13 ticks |
| title | 12 | title with 500 ms fade in |
| clientlag | 2 | client thread sleeps 400 ms, then the command |
| serverlag | 3 | chat one tick later, the main thread sleeps 400 ms |
| chunk | 20 | teleport 4096 blocks away, then a real block next to the player |

## Facts: gated Mac, 200 per scene

Cell: wrong / median decide ms / median wasted ms. `caN`: in N repeats the perceived state still changed after
the decision (not a wrong verdict, but the scene was not settled). Load 12 to 24.

| scene | E1 | E1w | E3t | E3ms | E4 | E5t1 | E6 |
|---|---|---|---|---|---|---|---|
| now | 0 / 2.8 / 0 | 0 / 102 / 99 | 0 / 3.1 / 0 | 0 / 3.1 / 0 | 0 / 2.8 / 0 | 0 / 11 / 8 | 0 / 5.3 / 2.4 |
| late1 | **179** / 2.0 | 0 / 152 / 100 | 0 / 52 / 0 | 0 / 52 / 0 | 0 / 52 / 0 | 0 / 61 / 9 | 0 / 54 / 2.5 |
| late2 | **180** / 2.4 | 0 / 202 / 100 | 0 / 102 / 0 | 0 / 102 / 0 | 0 / 102 / 0 | 0 / 111 / 9 | 0 / 104 / 2.5 |
| async | **171** / 2.2 | 0 / 202 / 149 | 0 / 55 / 0 | 0 / 55 / 0 | 0 / 26 / 0 | 0 / 61 / 39 | 0 / 29 / 2.5 |
| section | 0 / 2.2 / 0 | 0 / 102 / 99 | 0 / 2.6 / 0 | 0 / 2.6 / 0 | 0 / 2.2 / 0 | 0 / 11 / 8 | 0 / 2.5 / 0 |
| walk | **180** / 2.9 | 0 / 752 / 365 | 0 / 387 / 0 ca180 | 0 / 387 / 0 ca180 | 0 / 651 / 265 ca180 | 0 / 761 / 374 | 0 / 714 / 327 |
| title | **180** / 2.3 | 0 / 602 / 142 | 0 / 460 / 0 | 0 / 460 / 0 | **180** / 2.3 | **180** / 10 | 0 / 460 / 0 |
| clientlag | 0 / 357 / 0 | 0 / 357 / 0 | 0 / 361 / 0 | **180** / 100 | 0 / 357 / 0 | 0 / 365 / 4 | 0 / 365 / 3.5 |
| serverlag | **12** / 409 | 0 / 409 / 0 | 0 / 410 / 0 | **180** / 150 | 0 / 409 / 0 | 0 / 458 / 46 | 0 / 412 / 2.8 |
| chunk | **180** / 4.7 ca200 | 0 / 1002 / 900 | 0 / 103 / 0 ca180 | 0 / 103 / 0 ca180 | **180** / 4.9 ca200 | 0 / 161 / 58 ca200 | 0 / 255 / 153 ca200 |

- E3t is the only verdict signal that is never wrong and never waits past the truth on a pass. On walk its pass
  is at "in view" (387 ms), while the walker is still moving; that is the right verdict for "in view" and the
  reason a separate done signal exists.
- E4's walk decision changed afterwards in every repeat, up to 61 ms: client interpolation runs after the
  server is quiet. E5t1 and E6 cover it.
- E5t2 (two quiet client ticks) is also 0 wrong except title, and costs about 60 ms over E4.
- Chunk: every signal that passes still sees other chunks arrive afterwards. E6 waits for the radius chunks
  but lighting and the outer ring keep changing state for up to 200 ms; the verdict is still right.

## Facts and pixels: rendered Mac, 200 per scene

Facts, same cells. Load 6 to 19.

| scene | E1 | E1w | E3t | E3ms | E4 | E5t1 | E6 |
|---|---|---|---|---|---|---|---|
| now | 0 / 2.5 / 0 | 0 / 102 / 97 | 0 / 5.1 / 0 | 0 / 5.1 / 0 | 0 / 2.5 / 0 | 0 / 9.7 / 5.3 | 0 / 9.0 / 3.9 |
| late1 | **180** / 1.9 | 0 / 152 / 98 | 0 / 53 / 0 | 0 / 53 / 0 | 0 / 51 / 0 | 0 / 58 / 5.4 | 0 / 57 / 3.5 |
| late2 | **180** / 1.7 | 0 / 201 / 99 | 0 / 102 / 0 | 0 / 102 / 0 | 0 / 100 / 0 | 0 / 107 / 5.8 | 0 / 104 / 2.2 |
| async | **178** / 1.6 | 0 / 202 / 139 | 0 / 66 / 0 | 0 / 66 / 0 | 0 / 61 / 0 | 0 / 106 / 40 | 0 / 65 / 2.0 |
| section | 0 / 1.7 / 0 | 0 / 101 / 97 | 0 / 4.4 / 0 | 0 / 4.4 / 0 | 0 / 1.7 / 0 | 0 / 8.4 / 5.8 | 0 / 4.2 / 0 |
| walk | **180** / 2.2 | 0 / 751 / 369 | 0 / 382 / 0 ca180 | 0 / 382 / 0 ca180 | 0 / 650 / 268 ca180 | 0 / 755 / 373 | 0 / 708 / 326 |
| title | **180** / 2.8 | 0 / 603 / 145 | 0 / 458 / 0 | 0 / 458 / 0 | **180** / 2.8 | **180** / 53 | 0 / 458 / 0 |
| clientlag | 0 / 365 / 0 | 0 / 365 / 0 | 0 / 371 / 0 | **180** / 100 | 0 / 365 / 0 | 0 / 409 / 37 | 0 / 376 / 2.6 |
| serverlag | **9** / 405 | 0 / 406 / 0 | 0 / 409 / 0 | **180** / 150 | 0 / 406 / 0 | 0 / 458 / 47 | 0 / 412 / 3.4 |
| chunk | **180** / 4.4 ca200 | 0 / 1001 / 897 | 0 / 105 / 0 ca180 | 0 / 105 / 0 ca180 | **180** / 4.5 ca200 | 0 / 166 / 60 ca199 | 0 / 262 / 157 ca200 |

Pixels: is the frame at the signal already the final picture? Cell: wrong / median decide ms / median ms past the
pixel truth. Pixel rules: at least half the final count of changed pixels (chat, section), at least 30 pixels
(walk), the final frame's hash (title, chunk).

| scene | truth | E3t | E3t+f1 | E3t+f3 | E3t+stable | E3t+obj | **E3t+objq** | E2obj alone | E6+objq |
|---|---|---|---|---|---|---|---|---|---|
| now | 4.8 | 0 / 5.1 / 0 | 0 / 5.1 / 0 | 0 / 11 / 5.9 | 0 / 10 / 5.3 | 0 / 4.8 / 0 | 0 / 4.8 / 0 | 0 / 4.8 / 0 | 0 / 9.3 / 3.9 |
| late1 | 53 | 0 / 53 / 0 | 0 / 53 / 0 | 0 / 60 / 6.5 | 0 / 59 / 5.4 | 0 / 53 / 0 | 0 / 53 / 0 | 0 / 53 / 0 | 0 / 57 / 3.5 |
| late2 | 102 | 0 / 102 / 0 | 0 / 102 / 0 | 0 / 108 / 6.1 | 0 / 107 / 5.8 | 0 / 102 / 0 | 0 / 102 / 0 | 0 / 102 / 0 | 0 / 104 / 2.2 |
| async | 64 | 0 / 66 / 0 | 0 / 66 / 0 | 0 / 71 / 4.0 | 0 / 107 / 40 | 0 / 64 / 0 | 0 / 64 / 0 | 0 / 64 / 0 | 0 / 67 / 2.0 |
| section | 9.4 | **180** / 4.4 | **180** / 4.4 | 1 / 9.5 / 0 | **93** / 52 | 0 / 9.4 / 0 | 0 / 9.4 / 0 | 0 / 9.4 / 0 | 0 / 9.4 / 0 |
| walk | 180 | 0 / 382 / 202 | 0 / 382 / 202 | 0 / 386 / 206 | 0 / 755 / 575 | 0 / 382 / 202 | 0 / 382 / 202 | **180** / 4.8 | 0 / 708 / 528 |
| title | 458 | 0 / 458 / 0 | 0 / 458 / 0 | 0 / 465 / 6.7 | 0 / 508 / 50 | 0 / 458 / 0 | 0 / 458 / 0 | 0 / 458 / 0 | 0 / 458 / 0 |
| clientlag | 374 | 0 / 374 / 0 | 0 / 374 / 0 | 0 / 379 / 7.5 | 0 / 409 / 37 | 0 / 374 / 0 | 0 / 374 / 0 | 0 / 374 / 0 | 0 / 376 / 2.6 |
| serverlag | 410 | 0 / 410 / 0 | 0 / 410 / 0 | 0 / 418 / 7.7 | 0 / 458 / 47 | 0 / 410 / 0 | 0 / 410 / 0 | 0 / 410 / 0 | 0 / 413 / 3.4 |
| chunk | 213 | **180** / 105 | **180** / 105 | **180** / 112 | **180** / 110 | **180** / 170 | 0 / 259 / 46 | **180** / 170 | 0 / 267 / 52 |

- `f1`, `f3`: the first or third drawn frame after the signal. `stable`: two equal frames, the second a
  client tick later. `obj`: the object's own draw. `objq`: obj plus empty render queue plus radius chunks held.
- Section: the client holds the block at once; the block is drawn about two frames later (mesh compiled, then
  swapped in during a frame that still draws the old mesh). Every signal that does not read the mesh is wrong.
- Chunk: the block's section is meshed and drawn before the neighbouring chunks are; the frame keeps
  changing for about 90 ms more. Only objq waits for them.
- Walk: the pixel rule (30 pixels) holds while the walker is partly in view, 200 ms before the view cone fact,
  so "past the truth" there is a difference of definitions, not waste.

## The runner: run 42174196154

Same scenes, 30 gated and 50 rendered per scene, judged with the same code as the Mac (rejudged from the
uploaded traces). Load 3.5 to 4.1 on 4 vCPU.

| scene | gated E1 | gated E3t | gated E4 | gated E6 | rendered E3t | rendered E6 | pixels E3t | pixels E3t+objq |
|---|---|---|---|---|---|---|---|---|
| now | 0 / 2.7 | 0 / 3.5 / 0 | 0 / 2.9 | 0 / 4.9 / 2.1 | 0 / 10 / 0 | 0 / 13 / 3.3 | 0 / 10 / 0 | 0 / 10 / 0 |
| late1 | **27** | 0 / 53 / 0 | 0 / 53 | 0 / 55 / 2.1 | 0 / 59 / 0 | 0 / 61 / 3.3 | 0 / 59 / 0 | 0 / 58 / 0 |
| late2 | **27** | 0 / 103 / 0 | 0 / 102 | 0 / 105 / 2.1 | 0 / 108 / 0 | 0 / 111 / 4.3 | 0 / 108 / 0 | 0 / 108 / 0 |
| async | **27** | 0 / 64 / 0 | 0 / 62 | 0 / 65 / 2.1 | 0 / 60 / 0 | 0 / 62 / 2.9 | 0 / 60 / 0 | 0 / 59 / 0 |
| section | 0 / 2.6 | 0 / 3.1 / 0 | 0 / 2.6 | 0 / 2.8 / 0 | 0 / 7.4 / 0 | 0 / 7.2 / 0 | **45** | 0 / 16 / 0 |
| walk | **27** | 0 / 418 / 0 | 0 / 652 / 234 | 0 / 744 / 326 | 0 / 386 / 0 | 0 / 714 / 328 | 0 / 386 / 199 | 0 / 386 / 199 |
| title | **27** | 0 / 492 / 0 | **27** | 0 / 491 / 0 | 0 / 462 / 0 | 0 / 461 / 0 | 0 / 462 / 0 | 0 / 461 / 0 |
| clientlag | 0 / 354 | 0 / 356 / 0 | 0 / 354 | 0 / 358 / 2.1 | 0 / 371 / 0 | 0 / 374 / 3.1 | 0 / 371 / 0 | 0 / 372 / 0 |
| serverlag | **4** | 0 / 403 / 0 | 0 / 403 | 0 / 405 / 2.1 | 0 / 407 / 0 | 0 / 411 / 4.2 | 0 / 407 / 0 | 0 / 407 / 0 |
| chunk | **27** | 0 / 103 / 0 | **27** | 0 / 255 / 152 | 0 / 105 / 0 | 0 / 263 / 159 | **45** | 0 / 261 / 47 |

Gated E3ms was wrong in all 27 good lag repeats and rendered in all 45, like the Mac. The runner agrees with
the Mac on every finding; the rendered fact verdicts take 2 to 5 ms longer (lavapipe frames).

## Start: when is a freshly placed client ready

A trial moves the client into a new level (swap: `poolSwap` to another world on the same server; reconnect:
disconnect and join again; reset: spike C's per requirement reset after leftovers; fresh: a new client
process from the title screen). Truth: the first frame from which every later frame equals the settled final
frame (toasts and the join chat line cleared by the framework, day clock and weather stopped). Cell: frames
wrong / median ms after the transition. A fact test (a fake block plus barrier) starts when the orchestrator sees
the named signal; it is right when the block is held at the barrier.

Cell: wrong / median ms after the transition. Bold: never wrong. `meshed`: radius chunks held and the render
queue empty. `barrier`: the fact test's barrier ack. `stable`: two equal frames a client tick apart.

| platform | start | n | load | truth median (p95) | join | chunks | meshed | hands | barrier | stable | fact test at join | at chunks held |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Mac | swap | 100 | 31 | 530 (534) | 100 / 55 | 100 / 350 | 100 / 350 | **0 / 532** | 100 / 395 | 100 / 82 | 25 of 25 wrong | **0 of 25** |
| Mac | reconnect | 50 | 23 | 680 (814) | 50 / 278 | 50 / 500 | 50 / 500 | 1 / 681 | 50 / 546 | 1 / 730 | 13 of 13 wrong | **0 of 13** |
| Mac | reconnect terrain | 20 | 20 | 802 (1197) | 20 / 458 | 18 / 708 | 18 / 708 | 1 / 802 | 11 / 744 | 0 / 850 | 2 of 5 wrong | **0 of 5** |
| Mac | fresh client | 10 | 26 | 2093 (2457) | 10 / 1070 | 10 / 1373 | 10 / 1373 | 10 / 1611 | 10 / 1374 | 10 / 1960 | 1 of 3 wrong | **0 of 3** |
| Mac | reset after leftovers | 200 | 17 | 1146 (1152) | 200 / 2 | 200 / 2 | 200 / 2 | 200 / 22 | 200 / 90 | 200 / 973 | facts right at the barrier: **0 of 200** | |
| runner | swap | 30 | 4.1 | 495 (544) | 30 / 59 | 30 / 349 | 30 / 349 | **0 / 496** | 30 / 393 | 30 / 89 | 8 of 8 wrong | **0 of 8** |
| runner | reconnect | 10 | 3.6 | 696 (1576) | 10 / 288 | 10 / 505 | 10 / 505 | 1 / 699 | 10 / 547 | 1 / 745 | 2 of 3 wrong | **0 of 3** |
| runner | reconnect terrain | 6 | 3.5 | 860 (1110) | 6 / 376 | 6 / 722 | 6 / 722 | 2 / 836 | 4 / 739 | 1 / 890 | 1 of 2 wrong | **0 of 2** |

The runner's reset trials are left out: the leftover push made the player drift a little further each trial
until the player fell off the platform after about 12 trials (a fault of the trial, fixed after the run). The
runner's fresh client trial hit a harness fault (the old client's stop file stopped the new process); fixed
after the run, so fresh numbers are Mac only.

- Hands wrong cases outside fresh and reset: 1 Mac reconnect where frames changed until 1.7 s (not viewed),
  and reconnects in terrain that settled 1 frame after the hands signal.

- **Hands settled** is the last visible change after a level change: the first person hand rises and the attack
  indicator fills, both client tick driven, about 180 ms after the last chunk is meshed
  (`FirstPersonHandsAndItems.mainHandHeight`, `Player.getAttackStrengthScale`). Frame viewed at full size:
  the hand half raised 350 ms after a swap, the attack indicator still drawn.
- **Fact tests started at join are wrong every time**: the fake block arrives before the client holds the new
  level's chunk and is lost. Started at "radius chunks held" or later: right every time.
- **Two equal frames is not a start signal**: empty sky frames before the terrain arrives are equal to each
  other.
- **Reset with physical leftovers** settles visually only after 1.15 s: the leftover push and the hand
  animation after the inventory clear keep moving the view (frames viewed at full size, 0.3 s against 2.5 s:
  floor shifted, hand lower). The facts are clean at once (fact test 0 wrong of 200). No start signal here
  catches the residual motion; a reset that zeroes the player's motion and restores the held item is the fix
  (**inferred**).

## Cost

| Item | Mac | Runner |
|---|---|---|
| E1 decide, effect present (gated) | 2.2 to 2.8 ms | 2.6 to 2.9 ms |
| E3t decide over the effect's arrival | 0.3 to 0.4 ms | 0.5 to 0.8 ms |
| E6 over the quiet barrier, nothing pending | 2.4 to 3.5 ms | 2.1 ms gated, 3 to 4 ms rendered |
| Quiet barrier polls, idle plugin | 0.2 to 0.6 ms, 1 to 2 polls | not separated |
| Quiet barrier polls, a one tick task pending | 50 ms (the task), 122 polls | |
| Frame readback per frame (pixel checks) | 0.27 ms | not separated |
| A failing fact verdict | the window: `w` ticks | the window |

C's baseline is 5 to 10 ms per trivial requirement; E3t and E6 together add about 3 ms to a requirement that
needs no waiting.

## Surprises

- **`LockSupport.parkNanos` does not sleep on a thread that was unparked before**: `mc.execute` unparks the
  client thread, and the server main thread holds a permit too. The first lag scenes did not lag at all. Lag
  injection must use `Thread.sleep`.
- **E1 is flaky, not just wrong**: under server lag it passed 12 of 180 (Mac gated), 9 of 180 (rendered),
  because catch up ticks ran the delayed task before the barrier; async passed 9 of 180 when the sleep was
  short. A signal that is right by luck under load is worse than one that is always wrong.
- **Display entities are never culled** when width or height is 0 (`Display.affectedByCulling`), so "entity
  render state built" is true off screen: E2obj alone was wrong 180 of 180 on walk.
- **A new mesh is swapped in during a frame that still draws the old one**; the block shows one frame after
  the mesh is in use.
- **The title fade is invisible to the server**: the server is quiet at once, the client fades for 500 ms.
- **Chunk sending is not plugin work**: the quiet barrier says done while the new region is still arriving.
- **The plain barrier after a window wastes the whole window on every pass** (100 to 900 ms), which is why
  E3t polls instead of waiting.
- **Stone texture rotation depends on the block position**: the same platform at x 4096 and 8192 gives
  frames 41k to 66k pixels apart, so a "clean" frame must come from the same place.
- **A restarted client in the same directory stops itself at once**: the old client's stop file is still there.
  It failed the fresh step on the runner and on the Mac's first try.
- **A client process's first join settles about 0.5 s after its hands do**: only the floor changes, by at most
  27 levels (frames at 1.8, 2.0 and 4.0 s viewed at full size look the same). Lighting in a cold client is the
  likely cause (**inferred**).

## What this means for the search

- **Typewriter needs requirements to declare a window in ticks**, for fails and absence checks. A pass never
  waits for it. A wall clock window is wrong under lag and must not exist.
- **Two signals, not one**: a verdict signal (E3t) per observation, and a done signal (E6) per requirement for
  "nothing else happens" and before the next requirement starts. E6 needs the plugin's work to be countable:
  this matches spike I (coverage needs the same idle wait). Typewriter's async work must run on counted
  dispatchers (**inferred**: raw threads would be invisible to E4 exactly as in I).
- **The client must report what it still has in flight** (fades, chunks, interpolation). The server cannot know
  it. The probe's list is small: title phase, radius chunks, perceived state equal across one loop.
- **Pixel checks wait for the object's own draw plus an empty render queue.** That needs the A2 hooks spike A
  built (sections, extract) anyway.
- **Start readiness belongs to the framework**, not to each test: clear toasts and chat, stop the day clock,
  wait for hands settled. For facts, radius chunks held is enough and 180 ms faster.
- **C**: a per requirement reset should zero player motion and keep the held item, or pixel checks after a
  reset need a "player still" signal (**inferred**).
- **F**: the hands signal replaces the fixed wait F used before a golden after a level change.
- **H**: every finding held on the runner with Vulkan. Fresh client start is Mac only.

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, one at a time, `SDL_MAC_BACKGROUND_APP=1`:

```
python3 orchestrator/readiness.py scenes --mode gated --n 200 --label mac
python3 orchestrator/readiness.py scenes --mode rendered --n 200 --label mac
python3 orchestrator/readiness.py start --kind swap --n 100 --label mac
python3 orchestrator/readiness.py start --kind reset --n 200 --tail 1.5 --label mac
python3 orchestrator/readiness.py start --kind reconnect --n 50 --tail 6 --label mac
python3 orchestrator/readiness.py start --kind reconnect --world default --n 20 --tail 8 --label mac
python3 orchestrator/readiness.py start --kind fresh --n 10 --tail 10 --label mac
python3 orchestrator/readiness.py rejudge runs/e-readiness/mac-gated-*.jsonl.gz --suffix=-e6
python3 orchestrator/readiness.py report --label mac-e6
```

`scenes` flags: `--only now,late1`, `--n`. Every repeat's trace is kept in `runs/e-readiness/`, so a change
to the judging is checked with `rejudge` without running the game again. Results append to
`runs/e-readiness.jsonl`.

CI: the matrix row `{ plan: readiness, backend: vulkan, runner: ubuntu-24.04, repeat: 0 }` runs
`orchestrator/ci.py plan readiness`: rendered scenes 50, start swap 30, reset 30, reconnect void 10, reconnect
terrain 6, fresh 3, gated scenes 30. Traces are in the job's artifact under `e-readiness/`.

## Reuse

- **Client** `probe-mod/.../ready/Ready.java`: `r.watch?needles=&ent=&title=&block=&material=&chat=&pix=&ref=&radius=&freeze=&hud=`
  records one row per client loop (loop, time, tick, drawn, fact bits, perceived state hash) plus a frame hash
  and changed pixel count per frame; `r.stop?pingFrom=`, `r.wait?ids=&timeoutMs=`, `r.ref`, `r.lag?ms=`,
  `r.opts`, `r.now`. Barrier acks are recorded in `PingMixin`. Bits: held, in view, title fading in, drawn,
  level, no screen, radius chunks, feet section, settled, render queue empty, no toasts, meshed, hands settled.
- **Plugin** `probe-plugin/.../Ready.java`: `e.scene` sends the effect and three barriers (at once, after the
  window, after quiet); `busy()` counts this plugin's tasks and async workers; `e.calm` stops the day clock and
  weather in every world; `e.home`, `e.clean`, `e.info`.
- **Orchestrator** `readiness.py`: `judge` (all signals offline from one trace), `pixel_truth`, `judge_start`,
  `rejudge`, `report`.
