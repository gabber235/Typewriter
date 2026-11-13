# Perceive without drawing: A2 records from the extract and submit stages, pixels only for A4

Question (P11): can a real Minecraft 26.3 client build its perception records from the frame's extract and submit
stages without the GPU draw, so 4 clients on the shared stepped Paper stay within 20 percent of the speed without
frames, and do the verdicts stay right? Thresholds from the developer: within 10 percent is fine, 20 percent is rough,
over 50 percent is probably a no go. Branch cut from `proto/gv-frames` (P8); P8's numbers are on that branch.

## Answer

- **Perceiving every tick without drawing lands inside the 20 percent line, close to the 10 percent line**: +7 % at
  0 percent groups, +15 % at 10 percent groups, +10 % at 30 percent groups (854x480, slowdown against the base runs
  around each run, median of 9 to 12 runs in 6 jobs). A frame every tick on the same jobs: +374, +451, +580 %. The
  10 percent block runs first and still carries the warm up drift; the runs after it (second half of that block) are
  +8 to +11 %. The window size no longer matters: 427x240 and 320x180 give the same +5 to +16 %.
- **A4 on demand costs 6 to 27 points on top**, when 10 percent of requirements ask once for the pixels the token owns:
  854x480 +26, +33, +37 % (0, 10, 30 percent groups); 427x240 +14, +22, +22 %; 320x180 +14, +22, +20 %. Each ask
  draws 2 real frames and reads them back while the whole shared Paper waits (37 to 54 ms per ask at 854x480).
- **Verdicts right**: 0 wrong in 249 runs of 1,000 (249,000 requirements, 24,900 deliberately broken, 150,000 judged
  from the stream). Every requirement got the same verdict, the same token text and the same record count from
  perceive frames as from drawn frames (P8's `f` in the same job).
- **Lying scene battery: 0 flips.** A2 read from a perceive frame gave the same verdict as A2 from a drawn frame in all
  238 scene runs (spike A's 33 scenes 5 times, 12 new kinds 6 times, t1 once). The record's own legibility rules on
  the perceive frame agreed wherever they apply. A2 on the perceive frame plus A4 on demand: correct on every scene.
- **Nothing went stale for a later drawn frame** that the battery could see: the first frame drawn after a perceive
  only stretch equals the frame after it exactly as often as in drawn mode (0 differing pixels on every static scene).
- **A2 needed four things from the draw**, all inside `LevelRenderer.render`: the submit stage (name tags, world
  text, entity geometry), section compile and buffer upload, the section occlusion update, and
  `RenderSystem.isRenderingLevel` during submit. GUI text, blur strata, cover and world text facing need nothing.

Machine: GitHub hosted `ubuntu-24.04`, x86, 4 vCPU, 16 GB, Vulkan on lavapipe under one Xvfb per client, gate mode 2,
park 2 ms, render distance 2, void world, Paper 26.3 build 242 with the step agent and the AppCDS archive. CPUs: run
43330492175 EPYC 9V74 (jobs 0, 2), Xeon 8573C (job 1); run 43333247905 EPYC 7763 (jobs 0, 1), EPYC 9V45 (job 2).
Every variant of a job runs on the same rig with the same seeds, so slowdowns compare within a job only. Battery: M1
Max, OpenGL over Metal, 1708x960, as spike A, load 29 to 131 (other work on the machine). Measured unless marked
**inferred**.

Evidence:

| Run | What |
|---|---|
| [43330492175](https://github.com/gabber235/Typewriter/actions/runs/43330492175) | round 1: base, p, p+a4, f, f+a4 at 0, 10, 30 percent groups (854x480), and base, p, p+a4, f at 10 percent (427x240); 3 jobs, 0 wrong |
| [43333247905](https://github.com/gabber235/Typewriter/actions/runs/43333247905) | round 2: 300 warm up requirements, base, p, p+a4 interleaved (base p p+a4 base p+a4 p base) at 0, 10, 30 percent groups at 854x480, 427x240, 320x180; 3 jobs, 0 wrong |
| Mac, `battery-p11.jsonl` (rows of `runs/a-observers.jsonl` labelled `p11`, `p11t1`, `p11draw`) | battery and new kinds in perceive mode (5 and 6 runs), drawn gate 2 battery as the stale baseline (2 runs) |

Raw rows: artifact `h-frames-vulkan-X64-<job>`, file `frames.jsonl`; tables by `orchestrator/nodraw_report.py`.

## Where 26.3 splits extracting from drawing

`Minecraft.renderFrame` calls `GameRenderer.extract` (window, options, camera, lightmap state,
`LevelExtractor.extract`, `Gui.extractRenderState`), then `GameRenderer.render`, then the swapchain blit, the command
submit and present. The rig already skips the acquire on gated frames, so blit and present skip themselves.
`GameRenderer.render` is not pure GPU work: `LevelRenderer.render` submits features first and compiles sections last.

A perceive frame (`probe.mod.nodraw.Nodraw`, mixin invokers on `LevelRenderer` and `GameRenderer`) runs extract and
then:

| Step | Perceive frame | Why |
|---|---|---|
| `LevelRenderer.repositionCamera` | kept | view area and compile order follow the camera |
| `submitFeatures` (entities, block entities, particles, outline, gizmos) | kept | name tags, world text (text displays, signs) and entity geometry are A2 seams here |
| `SubmitNodeStorage` | drained, every phase sorted into a no op | instead of `FeatureRenderDispatcher.prepareFrame` |
| `compileSections` and `uploadTerrainBuffersToGpu` | kept | block A2 reads the compiled mesh; later drawn frames need current buffers |
| `SectionOcclusionGraph.update`, compiled section callback | kept | the next extract culls with the visible section list |
| window resize of the render targets | kept | targets follow the window |
| clear, global uniforms, lightmap, post effects, fog buffer | cut | |
| frame graph setup and execution (sky, terrain, entities, translucency, outline) | cut | |
| `prepareFrame` (sort, vertex building, glyph and vertex upload) | cut | |
| first person hand (`render3dHud`) | cut | |
| `GuiRenderer.render` and `endFrame` (GUI vertices, item atlas, draw) | cut | `Gui.extractRenderState` resets the GUI state at its start anyway |
| render buffers and transient target pool `endFrame` | cut | |
| acquire, blit, present | cut (already, by the gate) | |

Each tick the client now does one of three things per loop: nothing, perceive, or draw. Record frames perceive; only
an A4 pair draws. Per perceive frame (854x480, 4 clients): 0.6 to 1.3 ms of loop time, of which extract 0.1 to 0.35
ms and submit, compile and occlusion 0.04 to 0.12 ms. The rest is the frame's fixed work around it (pending GPU tasks,
an empty queue submit, building the record) (**inferred** from the difference).

What A2 turned out to need from the draw:

- **Block section compile and visibility.** `compileSections`, the buffer upload and `SectionOcclusionGraph.update`
  sit at the end of `LevelRenderer.render`, after the frame graph. Skipping all of `render` (gate mode 1, or mode 2 on
  record frames) freezes them, while extract still consumes the dirty section states: the lost world updates spike A
  found for gate mode 1. Kept, the block scenes (12, 13, 18d) give the drawn verdicts, and A4 on a block after a
  perceive only settle sees the new block.
- **Name tags, world text, entity geometry.** `SubmitNodeCollection.submitText`, `submitNameTag` and the model submits
  run inside `submitFeatures`, so they need `render`'s first stage, not its GPU work.
- **`RenderSystem.isRenderingLevel` true during submit.** `SubmitNodeCollection.canRenderAsSolid` reads it to pick the
  solid or translucent phase. Not an A2 input, but submit must see the same flag as in a drawn frame.
- **Nothing for GUI text, blur strata, cover, the HUD hidden flag or world text facing.** `GuiRenderState.addText`,
  `addGuiElement` and `blurBeforeThisStratum` run in `Gui.extractRenderState`; facing is projected with the extracted
  camera state.

## Suite speed (P8's mix, 1,000 requirements, 4 clients, one stepped Paper)

Variants: `base` no stream, no frames, ack verdict (P1); `f` a drawn frame after every client tick, stream verdict
(P8); `p` a perceive frame after every client tick, stream verdict; `p+a4` as `p`, and requirements whose id ends in 7
(exactly 10 percent) declare an A4 check: once the token is drawn legibly, the client draws that tick for real with
and without the token and the record carries the pixel difference; the requirement passes only with at least 30
pixels; `f+a4` the same on drawn frames.

Slowdown is against the mean of the base runs before and after the run in the same block of the same job, so the
warm up drift does not land on one variant. Seconds per 1,000 and slowdown: median (range) over every run.

### 854x480

| Groups | No frames s | Frame every tick s | Perceive s | Perceive + A4 s | Frame every tick | Perceive | Perceive + A4 |
|---|---|---|---|---|---|---|---|
| 0 % | 13.1 (12.6 to 14.8) | 60.8 (60.5 to 62.1) | 14.3 (12.9 to 15.6) | 16.6 (15.4 to 18.7) | +374 % (+370 to +379) | **+7 %** (+1 to +10) | +26 % (+21 to +30) |
| 10 % | 15.6 (13.3 to 18.9) | 84.4 (79.8 to 86.1) | 17.6 (14.3 to 21.1) | 20.8 (18.3 to 23.4) | +451 % (+448 to +456) | **+15 %** (−2 to +23) | +33 % (+29 to +44) |
| 30 % | 16.6 (14.7 to 17.9) | 104.7 (103.9 to 106.5) | 17.6 (16.4 to 20.0) | 21.2 (19.4 to 25.4) | +580 % (+563 to +596) | **+10 %** (+8 to +14) | +37 % (+32 to +46) |

Runs: base 12 to 15, f 3, p 9 to 12, p+a4 9. f+a4 at 10 percent: 80.9 s, +433 %.

- The 10 percent block runs first in every job. Its first base run is 19 to 24 percent slower than its last (round 2
  job 0: 18.7 s, then 15.6 and 15.4) even after 300 warm up requirements. Its second perceive run, between two warm
  base runs, is +10, +11, +9 % (round 2) and +9, +8, +9 % (round 1).
- Perceive frames per tick per client: 1.13 (the extra ones are barrier and reset frames). Records and stream size are
  exactly P8's: 2,210 records, 296 KB per 1,000 at 10 percent groups.

### Smaller windows (round 2, 6 runs each; 427x240 at 10 percent adds round 1)

| Window | Groups | No frames s | Perceive s | Perceive + A4 s | Perceive | Perceive + A4 | A4 pixels p50 |
|---|---|---|---|---|---|---|---|
| 427x240 | 0 % | 13.7 | 14.7 | 16.0 | +5 % (+4 to +10) | +14 % (+10 to +17) | 351 |
| 427x240 | 10 % | 15.5 | 17.6 | 18.3 | +16 % (+11 to +22) | +22 % (+16 to +27) | 351 |
| 427x240 | 30 % | 17.0 | 19.2 | 20.9 | +11 % (+7 to +21) | +22 % (+20 to +24) | 352 |
| 320x180 | 0 % | 13.7 | 15.1 | 15.5 | +8 % (+7 to +11) | +14 % (+11 to +16) | 352 |
| 320x180 | 10 % | 16.0 | 17.7 | 19.9 | +15 % (+9 to +24) | +22 % (+18 to +26) | 349 |
| 320x180 | 30 % | 17.0 | 18.9 | 20.3 | +12 % (+10 to +14) | +20 % (+19 to +23) | 351 |

Frame every tick at 427x240, 10 percent groups: 39.4 s, +152 %. At 854x480 the token owns 1,404 pixels; at the smaller
windows (GUI scale 1 and 2) about 350, still far over the 30 pixel line.

### What A4 on demand costs

| Window | Drawn frame ms (2 per ask) | One ask, base frame to record ms | Points over perceive (0, 10, 30 % groups) |
|---|---|---|---|
| 854x480 | 16 to 32 | 37 to 54 | +19, +18, +27 |
| 427x240 | 10 to 13 | | +9, +6, +11 |
| 320x180 | 9 to 11 | | +6, +7, +8 |

- An ask holds this client's step grants until both frames are read back, so the shared Paper stops for everyone:
  record lateness p95 grows from 7 to 12 ms to 20 to 64 ms; p50 does not move.
- At 427x240 and smaller, a check that asks for pixels on 10 percent of requirements stays at or under +22 %.
  **Inferred**: a smaller target only for A4 pairs, or a crop, would give 854x480 records with that cost.

## Ticks, CPU and lateness under 4 clients

Median over runs. Tick is the time between consecutive stepped tick ends; client CPU is CPU time per client over
stepped ticks; echo is Paper sending the barrier to the listener holding its echo; late is the server's tick end to
the listener holding the record for that tick.

| Variant (854x480) | Groups | Tick p50 ms | Client CPU ms per tick | Busy vCPU of 4 | Echo p50 / p95 ms | Late p50 / p95 ms |
|---|---|---|---|---|---|---|
| no frames | 0 % | 3.7 | 3.3 | 1.6 | | |
| perceive | 0 % | 3.8 | 3.3 | 1.6 | 4.3 / 8.1 | 4.0 / 7.8 |
| frame every tick | 0 % | 45.0 | 43.6 | 3.8 | 83 / 107 | 73 / 108 |
| no frames | 10 % | 4.3 | 4.3 | 2.0 | | |
| perceive | 10 % | 5.1 | 5.2 | 2.4 | 5.2 / 11.7 | 5.5 / 12.1 |
| perceive + A4 | 10 % | 5.0 | 6.8 | 2.5 | 4.8 / 11.5 | 5.7 / 47.3 |
| frame every tick | 10 % | 47.2 | 47.0 | 3.9 | 84 / 121 | 76 / 125 |
| no frames | 30 % | 3.2 | 3.0 | 1.8 | | |
| perceive | 30 % | 3.4 | 3.1 | 1.9 | 3.4 / 6.7 | 3.7 / 7.5 |
| frame every tick | 30 % | 44.7 | 45.3 | 3.9 | 79 / 101 | 73 / 114 |

- Extract only, the client costs 0 to 1 ms of CPU per tick more than without frames; with a drawn frame it is about
  40 ms more. The runner is no longer saturated (1.6 to 2.5 busy vCPU against 3.8 to 3.9).
- **Inferred**: the remaining slowdown is latency, not CPU. A perceive frame runs after the client's tick and its ack,
  before the loop reads the next step grant, so each tick waits about 1 ms longer (tick p50 +0.1 to +0.8 ms).
  Untried levers: perceive only on ticks after a game packet (P8's dirty frames, 1.13 to about 0.7 per tick), or read
  the next grant before perceiving.

## Correctness

### Suite verdicts

| What | Result |
|---|---|
| Runs of 1,000 | 249 (both rounds, every variant) |
| Wrong verdicts, errors | 0, 0 |
| Deliberately broken requirements | 24,900, every one judged failed |
| Judged from the stream | 150,000 |
| Perceive against drawn, same job, same requirement | 1,000 of 1,000 same verdict, same token text, same records until the verdict, at every group share |
| Records until the verdict across jobs, perceive | 1,000 of 1,000 identical in every setup |
| The same with A4 asks | 997 to 1,000 identical; verdicts identical |

The few A4 requirements whose record count varies all have short windows: the A4 hold delays the token record, so
sometimes Paper's window ends first and the verdict comes from the barrier echo, which counts one more record. The
verdict is the same (**inferred** from the record ticks).

### Lying scene battery (spike A's scenes and truths)

Mac, gate 2. Each scene settles on perceive frames only after its stimulus; then A2p (A2 on a perceive frame) and A2r
(the record's rules, `Stream.snapshot`, on the same frame) are read first, then A2 on a drawn frame, A3 and A4 as in
spike A.

| Scene | Truth | A2 drawn | A2p perceive | A2r record | A4 | A2p and A4 |
|---|---|---|---|---|---|---|
| 0 null control | no | ok | ok | ok | ok | ok |
| 1 entity behind wall | no | FP | FP | | ok | ok |
| 2 entity behind the player | no | ok | ok | | ok | ok |
| 3 text display facing away | no | ok | ok | ok | ok | ok |
| 4 invisible flag | no | ok | ok | | ok | ok |
| 5a text display, opacity zero | no | ok | ok | ok | ok | ok |
| 5b black text on opaque black | no | ok | ok | ok | FP | ok |
| 6 title under inventory | no | ok | ok | ok | ok | ok |
| 7 title, HUD hidden | no | ok | ok | ok | ok | ok |
| 8 title under opaque rectangle | no | ok | ok | ok | ok | ok |
| 9 chat line faded | no | ok | ok | ok | ok | ok |
| 10 chat scrolled out | no | ok | ok | ok | ok | ok |
| 11 chat set to hidden | no | ok | ok | ok | ok | ok |
| 12 block in client, section stale | no | ok | ok | | ok | ok |
| 13 block behind block | no | FP | FP | | ok | ok |
| 14a, 14b sound beyond range, category zero | no | ok | ok | | ? | ok |
| 15a, 15b fake inventory | no, yes | ok | ok | | ok | ok |
| 17a, 17c title colour | no, yes | ok | ok | | ok | ok |
| 17b, 17d long title cut, fits | no, yes | ok | ok | | ok | ok |
| 18a to 18h true positives | yes | ok | ok | ok on text kinds | ok (18f ?) | ok |
| 19 hidden entity, another moving | no | FP | FP | | ok | ok |
| 20 visible entity, another moving | yes | ok | ok | | ok | ok |
| f1 to f5 boss bar, sidebar, HUD hidden | | ok | ok | ok | ok | ok |
| g1 to g4, g2b, g6 any text (signs, name tag, screen label) | | ok | ok | ok | ok | ok |
| g5 sign behind a wall | no | FP | FP | FP | ok | ok |
| t1 Diamonds toast | yes | ok | ok | | ok | ok |

Every cell holds for all runs (5 per battery scene, 6 per new kind, 1 for t1). A2p differs from A2 in **0 of 238**
scene runs; A2r differs from A2 in 0 of the runs where it applies. The FP cells are spike A's known A2 limit (no
occlusion by world geometry); A4 catches each one. A2p on a perceive frame takes 2.6 ms p50 (6.8 p95) to read
against 5.4 (21.7) for A2 with a drawn frame; A4 takes 21 ms p50.

## Stale after skipped draws

| Check | Result |
|---|---|
| First drawn frame after a perceive only settle against the next drawn frame | 0 differing pixels on every static scene, as in drawn mode; scenes that move (zombie idle, wiggle, name tag) differ by the same amounts in both modes (18e 46 to 62 against 45 to 58) |
| Meshes | block scenes 12, 13, 18d: A2 and A4 after a perceive only settle give the drawn verdicts; A4 on 18d sees the block in the first drawn pair |
| GUI item atlas | 15b and t1: A4 on items after a perceive only settle is right |
| Glyphs | every text A4 right on the first drawn pair (battery, and 500 to 1,800 asks per job in the suite) |
| Window resize | 17b resizes, then settles on perceive frames: right |

Not tested, **inferred** harmless because the next drawn frame redoes each one before using it: the lightmap texture,
post effect chains (a removed effect keeps its targets until the next draw), the transient target pool and render
buffers age only on drawn frames, oversized GUI item renderers keep their used flags. Goldens and clips need every
frame of their span drawn; a clip should switch its clients to drawing for that span, and its first frame is current
by the check above.

## Surprises

- **The extract stage is cheap; the frame was the GPU work.** A perceive frame is about 1 ms of loop time against
  about 40 ms for a drawn one with 4 lavapipe clients, so the runner goes from saturated to half idle.
- **`GameRenderer.render` holds CPU work A2 depends on.** Submit runs first and section compile and occlusion run
  last inside `LevelRenderer.render`; "extract only" as in the existing gate modes would have broken name tags, world
  text and every block check.
- **A4 is now the expensive part**: 10 percent of requirements asking once costs more (+18 points at 854x480) than
  perceiving every tick (+7 to +15 %), because each ask stops the shared Paper for two drawn frames and their read
  back. The window size matters only for A4 now.
- **Warm up drift outlives 300 warm up requirements.** The first block of every job is about 20 percent slower at its
  start; only interleaved base runs keep it off the variants.

## Rerun

Build from the worktree root (needs `python3 orchestrator/run.py prepare` once, for the Paper jar):

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :step-agent:jar :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, `SDL_MAC_BACKGROUND_APP=1`:

```
python3 orchestrator/observe.py battery --gate 2 --perceive --reps 5 --wait-toast 10 --label p11
python3 orchestrator/observe.py flex --gate 2 --perceive --reps 5 --label p11
python3 orchestrator/observe.py battery --gate 2 --reps 2 --wait-toast 10 --label p11draw
python3 orchestrator/frames.py run --instances "default" --plan-default "base@0.1,p@0.1,p+a4@0.1,base@0.1" --n 1000
python3 orchestrator/nodraw_report.py runs/frames.jsonl
```

CI: `.github/workflows/gv-nodraw-prototype.yml`, matrix `{ plan: frames, repeat: 0|1|2 }`; `FRAMES_INSTANCES` lists the
client setups, `FRAMES_ARGS` the variant plan (`variant@groups`). Client commands: `st.mode nodraw=1` (record frames
perceive), `st.begin a4=<text>` (one A4 ask for the requirement), `perceive frames=N`, `drawn perceive=1`,
`st.judge`, `frames.stats`.
