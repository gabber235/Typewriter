# Demo rerun video under stepped ticks: results

Throwaway prototype on `proto/gv-video`, built on the stepped client (spike N) and the live perception
stream (`proto/gv-stream`). Question: can a demo rerun record a smooth clip while the test runner steps
Paper's ticks, with each frame lined up with what the player perceived and the verdict unchanged?

## Answer

- **Yes, at 30 and at 60 fps.** The stepped client draws fps / 20 frames per stepped tick at evenly spaced
  partial ticks (30 fps: 0, 1/3, 2/3; 60 fps: 0, 1/6, ... 5/6). Every frame is exactly 1/fps of game time
  after the one before it: **zero duplicate frames, zero skipped frames, zero spread** in game time per
  frame, in every case, on both machines.
- **Smoother than a real time recording.** Pixel motion per frame is steadier than real time on the same
  machine, and there is **no jump at tick boundaries** (motion across a boundary over motion inside a tick:
  0.99 to 1.06 for camera and walk, real time 0.91 to 1.22). Real time on the runner dropped 3 to 5 frames per clip.
- **Every frame lines up.** Each frame carries its own record, at its scheduled tick and partial, with
  facts read on the frame it describes; 0 gaps and 0 off schedule frames in 4,320 demo frames per machine.
  Pixels agree with the facts (walk position r = -0.9996, title 117 of 120, particles 90 of 90, boss bar
  within 3 px).
- **Verdicts unchanged: 12 of 12** (6 cases, each good and deliberately broken) pass or fail the same in
  the gated run, the 30 fps demo, the 60 fps demo and the rerun, on the Mac and on the runner. First ticks
  are equal except for facts the client interpolates (walk, boss, broken camera): one tick apart.
- **Cost on the runner (lavapipe): 1.5 times gated at 30 fps, 2.6 times at 60 fps.** A requirement takes
  1.31 s instead of 0.94 s at 30 fps. A real time recording takes 3.8 to 4.7 s. A stepped tick that draws 1.5
  frames costs 17.6 ms, so a 30 fps demo runs **2.8 times faster than real time** even on a software
  renderer.
- **Reruns are bit identical** (same mp4 bytes) for 11 of 12 clips on one machine. **Particles** differ in
  pixels from the first frame (client side randomness), with identical facts. Across machines (Metal and
  lavapipe) every fact of every frame is equal and no frame's pixels are.

Machines: the developer's M1 Max (OpenGL 4.1 on Metal, gated client mode 2, 854x480, render distance 2;
load 12 to 17, other work running) and the GitHub free runner (ubuntu-24.04, Vulkan on lavapipe under
Xvfb, 854x480; load 2 to 4).

## What was built

| Piece | Where | What it does |
| --- | --- | --- |
| Demo schedule | `probe-mod/.../video/Demo.java` | Frame f is at game time f / fps: needs `floor(f*20/fps) + 1` ticks done, draws at partial `(f*20 mod fps) / fps`, virtual clock `base + f * 1e9 / fps` |
| Partial tick | `video/mixin/TimerMixin.java` | `DeltaTracker.Timer.advanceGameTime` returns the demo's tick count and sets the exact partial (no millisecond rounding) |
| Held packets | `video/mixin/HoldPacketsMixin.java` | Queued packets are handled only in the loop that starts the next tick, never between the frames of one tick |
| Held ack | `n/N.java` `demoLoop` | The step ack of tick t goes out only when the client needs tick t + 1, after the last frame of tick t |
| Facts per frame | `Demo.facts`, `observe/Stream.java` | Camera, interpolated entity positions, particle count, title alpha (the HUD's formula), boss progress, chat input, slot 0; appended to each stream record |
| Readback | `video/Video.java` | Ring of `copyTextureToBuffer` readbacks piped to ffmpeg x264; sidecar per frame with virtual time, facts and a CRC32C of the RGBA frame |
| Hard cases | `probe-plugin/.../VideoScenes.java` | `vd.set`, `vd.go?name&broken`, `vd.clear`; each case driven by a Bukkit task tick by tick |
| Orchestration | `orchestrator/demo.py` | `run` (gated, demo per fps, reruns, real time per fps), `report`, `compare` |
| CI | `.github/workflows/gv-video-prototype.yml` | Runs only on `proto/gv-video`; plan `demo` |

The hard cases and their requirements (ticks counted from the stimulus):

| Case | Good | Broken | Requirement |
| --- | --- | --- | --- |
| camera | text display with teleport duration 10, teleported every tick around an orbit of radius 5 at 1.8 deg per tick, player camera set to it in spectator (as cinematics do) | 0.9 deg per tick | camera yaw at least 89 by tick 70 |
| walk | villager without AI teleported 0.15 blocks per tick in +x | walks in -x | x at least 3.5 by tick 62 |
| title | fade in 500 ms, stay 2,000 ms, fade out 1,000 ms | stay 500 ms | title still legible from tick 45 |
| particles | 8 end rods per tick for 60 ticks, particles set to all | none | at least 20 particles by tick 10 |
| boss | bar fills over 100 ticks | stalls at half | progress at least 0.99 by tick 105 |
| typing | the client types `/give @s minecraft:diamond_sword 1` and presses enter | types `diamond_swrod` | slot 0 holds a diamond sword by tick 50 |

## Verdicts

Pass or fail, and the first tick the requirement held. Mac and runner gave the same table.

| Case | Gated | Demo 30 | Demo 60 | Rerun 30 |
| --- | --- | --- | --- | --- |
| camera good | pass, 61 | pass, 61 | pass, 61 | pass, 61 |
| camera broken | fail (reaches it at 111) | fail (111) | fail (110) | fail (111) |
| walk good | pass, 57 | pass, **56** | pass, **56** | pass, 56 |
| walk broken | fail | fail | fail | fail |
| title good | pass, 45 | pass, 45 | pass, 45 | pass, 45 |
| title broken | fail | fail | fail | fail |
| particles good | pass, 3 | pass, 3 | pass, 3 | pass, 3 |
| particles broken | fail | fail | fail | fail |
| boss good | pass, 100 | pass, **101** | pass, 100 | pass, 101 |
| boss broken | fail | fail | fail | fail |
| typing good | pass, 36 | pass, 36 | pass, 36 | pass, 36 |
| typing broken | fail | fail | fail | fail |

The gated run judges one frame per tick at partial 0; the demo judges every frame and names the tick it
belongs to. A fact the client interpolates between ticks (entity position, lerped boss progress, the
camera entity's teleport interpolation) crosses a threshold at a partial, so its first frame can fall in
the neighbouring tick. Facts set once per tick (title alpha by tick, particle count, slot, input) agree
exactly. A requirement judged near its deadline on an interpolated fact needs a one tick margin, or the
demo must judge only frames at partial 0.

## Smoothness against real time

Game ticks per frame (ideal: 0.667 at 30 fps, 0.333 at 60 fps), duplicate frames (no game time passed),
and pixel motion per frame in the steady part of the motion (20 percent trimmed at each end): coefficient
of variation, largest over median, and motion across a tick boundary over motion inside a tick.

Runner:

| Clip | Ticks per frame (mean, std, min, max) | Duplicates | Pixel motion cv | Max over median | Boundary over inside |
| --- | --- | --- | --- | --- | --- |
| demo 30 camera | 0.6667, 0, 0.6666, 0.6667 | 0 | 0.191 | 1.10 | 0.995 |
| real time 30 camera | | | 0.220 | 1.42 | 1.024 |
| demo 60 camera | 0.3333, 0, 0.3333, 0.3334 | 0 | 0.165 | 1.11 | 0.995 |
| real time 60 camera | 0.3336, 0.100, 0, 0.86 | 5 | 0.306 | 2.36 | 1.22 |
| demo 30 walk | 0.6667, 0, 0.6666, 0.6667 | 0 | 0.087 | 1.22 | 1.011 |
| real time 30 walk | | | 0.121 | 1.33 | 1.117 |
| demo 60 walk | 0.3333, 0, 0.3333, 0.3334 | 0 | 0.148 | 1.42 | 1.054 |
| real time 60 walk | 0.3333, 0.095, 0, 0.82 | 4 | 0.324 | 1.80 | 1.064 |
| demo 60 boss | 0.3333, 0, 0.3333, 0.3334 | 0 | fact cv 0.028 | 1.00 | 1.03 |
| real time 60 boss | 0.3330, 0.090, 0, 0.86 | 4 | fact cv 0.293 | 2.72 | 1.168 |
| real time 60 title, particles, typing | about 0.333, 0.08 to 0.10, 0, 0.78 to 0.86 | 3 to 4 | | | |

Mac (real time 60 shown; real time 30 is similar):

| Clip | Ticks per frame (std, min, max) | Duplicates | Pixel motion cv | Max over median | Boundary over inside |
| --- | --- | --- | --- | --- | --- |
| demo 30 camera | 0, 0.6666, 0.6667 | 0 | 0.192 | 1.09 | 0.995 |
| demo 60 camera | 0, 0.3333, 0.3334 | 0 | 0.165 | 1.11 | 0.996 |
| real time 60 camera | 0.019, 0.22, 0.44 | 0 | 0.184 | 1.27 | 0.992 |
| demo 60 walk | 0, 0.3333, 0.3334 | 0 | 0.141 | 1.38 | 1.057 |
| real time 60 walk | 0.032, 0.26, 0.40 | 0 | 0.229 | 1.45 | 0.910 |
| real time 60 boss | 0.238, 0, 2.68 | 30 | fact cv 0.255 | 2.09 | 1.04 |
| real time 60 typing | 1.541, 0, 14.26 | 83 | | | |

Under load the Mac's real time client stalled during boss and typing (a 14 tick hole while typing); a
demo cannot stall, because it waits for the frame before it lets the next tick run. Pixel motion cv is
not zero in a demo because the scene itself is not uniform (pillars and the wall enter and leave the
view); the fact cv (the camera yaw step per frame, 0.014; the walker's x step, 0.000) shows the motion
itself is even.

## Alignment

Timeline: every demo frame has exactly one record; its tick and partial match the schedule.

| Check (both machines) | Demo 30 | Demo 60 |
| --- | --- | --- |
| Frames (12 clips) | 1,440 | 2,880 |
| Gaps in frame numbers | 0 | 0 |
| Frames without a record | 0 | 0 |
| Record tick off schedule | 0 | 0 |
| Partial off schedule | 0 | 0 |

Facts against pixels, per case (runner; the Mac matches within rounding):

| Case | Demo 30 | Demo 60 | Real time 60 | Reading |
| --- | --- | --- | --- | --- |
| camera | pixel motion still 0 of 108 | still 0 of 214 | still 0 of 219 | the view moves in every frame the facts say it moves |
| walk | r = -0.9996, residual median 0.52 px, max 8 px | r = -0.9996, 0.53 px, 8 px | r = -0.9996, 0.56 px, 8.8 px | tracked villager column against the fact x; 24.5 px per block |
| title | 117 of 120 agree | 233 of 240 | | the disagreeing frames have alpha 8 to 34 of 255: the fact says visible, the text is below the pixel threshold |
| particles | 90 of 90 agree | 180 of 180 | | presence of bright end rod pixels against particle count |
| boss | max 3 px, mean 1.1 px | max 3 px, mean 1.8 px | max 4 px, mean 1.2 px | bar width decoded at full size against progress times 182 px; the drawn bar is always 0 to 3 px shorter than the fact |
| typing | 48 agree, 2 fact only | 101 agree, 0 fact only | | typed row against the input fact, frames with the chat screen open |

Clip against the record timeline: frame f of a clip is record `df = f` of the stream; its virtual time is
`base + f / fps` and its tick `go_tick + floor(f * 20 / fps)`. Nothing is estimated: the clip is cut at
the stimulus tick, so a requirement window maps to a frame range by arithmetic.

## Cost

Wall time per stepped tick (scene ticks only) and median wall time per requirement (setup, stimulus,
case ticks, tidy). Video: all 12 clips of one pass, x264, 854x480.

| Machine | Pass | ms per tick | Per requirement | Against gated | Frames | Video |
| --- | --- | --- | --- | --- | --- | --- |
| runner | gated | 11.7 | 0.94 s | 1.0 | | |
| runner | demo 30 | 17.6 | 1.31 s | 1.5 (tick), 1.4 (requirement) | 1,440 | 4.05 MB |
| runner | demo 60 | 30.9 | 2.23 s | 2.6, 2.4 | 2,880 | 4.50 MB |
| runner | real time 30 | 50 (fixed) | 3.83 s | 4.1 | 762 | 2.30 MB |
| runner | real time 60 | 50 (fixed) | 4.74 s | 5.0 | 1,495 | 2.59 MB |
| Mac, load 12 | gated | 3.7 | 0.29 s | 1.0 | | |
| Mac, load 12 | demo 30 | 5.4 | 0.41 s | 1.45, 1.4 | 1,440 | 4.04 MB |
| Mac, load 12 | demo 60 | 8.3 | 0.63 s | 2.2, 2.1 | 2,880 | 4.45 MB |
| Mac, load 12 | real time 30 / 60 | 50 (fixed) | 3.81 / 3.96 s | 13 | 759 / 1,483 | |
| Mac, load 17 | gated / demo 30 / demo 60 | 4.9 / 6.9 / 21.1 | 0.39 / 0.51 / 1.08 s | 1.4, 4.3 | | |

The gated pass on this branch already draws one frame per tick for the stream, so the demo adds half a
frame per tick at 30 fps and two at 60 fps, plus the readback and the encode. The encode runs on its own
threads and never blocked the render thread on the runner; on the loaded Mac the readback ring blocked for
35 ms to 1.2 s per pass. The demo clip is larger than the real time clip at the same frame count because
x264 gets no duplicate frames to compress away.

## Identity of reruns

| Comparison | Clips with identical frames | What differs |
| --- | --- | --- |
| Rerun on the same client, same machine (Mac and runner) | 11 of 12, mp4 bytes identical | particles good: pixels differ from frame 0; facts equal |
| Two separate runs, same machine (Mac; runner) | 11 of 12 | particles good: 2 of 90 frames equal |
| Mac against runner | 0 of 6 by pixels; facts equal in all 720 frames | Metal and lavapipe rasterize differently |

What broke identity during the prototype, and what fixed it:

| Cause | Symptom | Fix |
| --- | --- | --- |
| Client randomness in particles | particle pixels differ from frame 0 | not fixed; would need a seeded client random per run |
| Clock origin not on a whole millisecond | boss frames differ between runs (the bar eases on `Util.getMillis`) | round the demo base up to a whole millisecond |
| A packet handled between two frames of a tick | typing reached a different first tick (35 against 36) and a frame differed | hold queued packets until the loop that starts the next tick |
| Random partial in the gated pass | gated first ticks differed between runs | pin the gated partial to 0 |
| Command suggestions arrive asynchronously | one typing rerun differed in 2 frames (popup shown one frame apart) | gone after holding packets (**inferred**: the suggestion answer is a packet) |

## Lessons

- **Hold the ack and the packets, not only the clock.** A stepped tick with several frames is only
  deterministic when the server cannot run ahead (held ack) and its answers cannot land between the frames
  of one tick (held packets). Without either, the clip still looks smooth and the reruns drift.
- **Set the partial, do not derive it.** The delta tracker is told the partial and the clock is set to the
  matching game time, so a frame's position never depends on millisecond rounding of a wall clock.
- **The frame rate must divide into ticks.** 30 and 60 fps give a fixed set of partials. A rate below 20
  fps cannot work this way (the demo refuses it).
- **Interpolated facts move the first tick.** Judging every frame finds a threshold crossing between ticks;
  the gated run sees it at the next partial 0. Verdicts did not change here, but a requirement right at its
  deadline could.
- **Particles need their setting.** The gated client runs with minimal particles; the demo set them to all.
  Particles also outlive their case (end rods live about 3 s), so the tidy must clear them, or a broken
  case passes on the previous case's leftovers.
- **The renderer decides the pixels.** Rerun identity holds per machine and driver; across machines only the
  facts are equal. A golden image test across machines would need a tolerance, a fact check needs none.

## Surprises

- **The demo beats real time even on lavapipe.** A 6 s clip at 30 fps took about 2.1 s on the runner.
- **Real time on the free runner drops frames** (3 to 5 per clip, gaps up to 0.86 ticks), and on a loaded
  Mac it stalls for whole ticks. The demo cannot, so it is the better recording even for a human viewer.
- **Title alpha below about 35 of 255 is invisible against the backdrop**, while the HUD counts it as drawn.
  A "legible" requirement needs an alpha threshold, not "title shown".
- **The boss bar drawn is always slightly behind the fact** (0 to 3 px of 182, in real time too). The bar
  sprite is cut on whole pixels; the exact cause was not investigated.

## Running it

```sh
cargo xtask heavy -- bash -c "cd prototypes/game-verification && ./gradlew -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar :step-agent:jar"
python3 orchestrator/demo.py run --label mac             # gated, demo 30 and 60, two reruns, real time 30 and 60
python3 orchestrator/demo.py report runs/demo-mac-<t>     # tables into report.json
python3 orchestrator/demo_summary.py runs/demo-mac-<t>    # the tables printed compactly
python3 orchestrator/demo.py compare runs/demo-a runs/demo-b   # frame identity between two runs
```

Evidence: CI run 43312553335 on `proto/gv-video` (run 43311736944 was cancelled and replaced). Artifacts
`video-results-vulkan-X64-0` (reports, sidecars, stream, logs) and `video-clips-vulkan-X64-0` (one clip per
hard case at demo 30, demo 60 and real time 60). Mac reports: `runs/demo-mac2-*` (cost at load 12),
`runs/demo-mac3-*` and `runs/demo-mac3b-*` (final code, identity between runs); local, not committed.
