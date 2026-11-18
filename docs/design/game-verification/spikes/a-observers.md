# Spike A: observing what the player perceives

Machine and renderer for every number: M1 Max, Minecraft 26.3 client on OpenGL over Metal, 1708x960,
real Paper 26.3. Not tried: Vulkan, llvmpipe, Linux. The machine was shared with other work, so each
number names its load. Measured unless marked **inferred**.

## Answer

- **No single observer is honest.** A1 fails 16 of 33 scenes. A2 fails 3, A3 fails 3, A4 fails 1.
- **A2 and A4 combined made 330 of 330 battery verdicts correct** (165 in each gate mode), plus 61 of
  61 on the new kinds. Their failures do not overlap: A2 has no occlusion, A4 does not read content.
- All of it works unchanged in gate mode 2. The verdicts are the same in both modes.
- Combined cost per check is about 30 ms, about 60 ms for a block, in both modes.

## Observers as built

| Id | What it reads | Verdict |
|---|---|---|
| A1 | Client state: `Gui` title, chat, inventory, level entities and blocks, sound log, bossbar and sidebar | Does the client hold it |
| A2 | What each frame submitted, in a JSON record per frame | Drawn, with final position, colour, alpha, facing, cover |
| A3 | `mainRenderTarget` read back raw, compared with the frame before the action | Enough pixels changed |
| A4 | Same frame with and without one thing, suppressed at an A2 hook, partial tick pinned | How many pixels this one thing owns |

A2 seams in 26.3 (`probe.mod.observe.mixin`):

- GUI text: `GuiRenderState.addText`. Add order is paint order. `addGuiElement`, `addItem`,
  `blurBeforeThisStratum` give what covers it.
- GUI items: `GuiGraphicsExtractor.item`, because `GuiItemRenderState` holds no item id.
- Entities after culling: `LevelExtractor.extractEntity`, `extractVisibleEntities`.
- Block entities after culling: `LevelExtractor.extractVisibleBlockEntities`.
- World text and geometry: `EntityRenderDispatcher.submit` brackets, `SubmitNodeCollection.submitText`,
  `submitNameTag`, `submitTextBackground`, `submitModel`, `submitBlockModel`, `submitItem`.
- World text facing: project the quad with `projectionMatrix x viewRotationMatrix x pose`. Positive
  signed area means it faces the camera.
- Sounds: `SoundEngine.play`. Reads volume, range, distance, category. Silence is enforced by forcing
  `calculateVolume` to return 0, so "effective" leaves out master on purpose.
- Blocks have no per block draw: section compiled, section in `visibleSections`, `cullFrustum` holds
  the block, section mesh changed since the block went dirty (`LevelExtractor.setBlockDirty`).

## Matrix

5 runs per cell, gate 0 and gate 2 gave the same counts. `ok` correct, `FP` says perceived but is not,
`?` cannot tell. No false negatives in the battery. Load 10 to 22.

Truth: frame looked at by eye at full size, except 14a, 14b and 18f (silent, so truth comes from the
scene design) and 16 (by construction, interpolation duration 3 or 0).

| Scene | Truth | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| 0 null control | no | ok | ok | ok | ok |
| 1 entity behind wall | no | FP | **FP** | ok | ok |
| 2 entity behind the player | no | FP | ok | ok | ok |
| 3 text display facing away | no | FP | ok | ok | ok |
| 4 invisible flag | no | FP | ok | ok | ok |
| 5a text display, opacity zero | no | FP | ok | ok | ok |
| 5b black text on opaque black | no | FP | ok | **FP** | **FP** |
| 6 title under inventory | no | FP | ok | **FP** | ok |
| 7 title, HUD hidden | no | FP | ok | ok | ok |
| 8 title under opaque rectangle | no | FP | ok | ok | ok |
| 9 chat line faded | no | FP | ok | ok | ok |
| 10 chat scrolled out | no | FP | ok | ok | ok |
| 11 chat set to hidden | no | FP | ok | ok | ok |
| 12 block in client, section stale | no | FP | ok | ok | ok |
| 13 block behind block | no | FP | **FP** | ok | ok |
| 14a sound beyond range | no | ? | ok | ? | ? |
| 14b sound, category zero | no | ? | ok | ? | ? |
| 15a server holds items, client empty | no | ok | ok | ok | ok |
| 15b server empty, client shown items | yes | ok | ok | ok | ok |
| 16 ride, smooth or jerky (below) | | ? per tick | ok per frame | ok flow | ? |
| 17a title, wrong colour | no | ok | ok | ok | ok |
| 17c title, asked colour | yes | ok | ok | ok | ok |
| 17b title cut off by narrow window | no | FP | ok | ok | ok |
| 17d long title fits | yes | ok | ok | ok | ok |
| 18a title | yes | ok | ok | ok | ok |
| 18b chat | yes | ok | ok | ok | ok |
| 18c action bar | yes | ok | ok | ok | ok |
| 18d per player block | yes | ok | ok | ok | ok |
| 18e entity | yes | ok | ok | ok | ok |
| 18f sound | yes | ? | ok | ? | ? |
| 18g text display facing | yes | ok | ok | ok | ok |
| 18h entity half behind wall | yes | ok | ok | ok | ok |
| 19 hidden entity, another one moving | no | FP | **FP** | **FP** | ok |
| 20 visible entity, another one moving | yes | ok | ok | ok | ok |

Excludes scene 16, 33 scenes:

| Observer | Correct | False positive | False negative | Cannot tell |
|---|---|---|---|---|
| A1 | 14 | 16 | 0 | 3 |
| A2 | 30 | 3 | 0 | 0 |
| A3 | 27 | 3 | 0 | 3 |
| A4 | 29 | 1 | 0 | 3 |
| A2 and A4 | 33 | 0 | 0 | 0 |

Why each one is fooled:

- **A1**: it reports what the client holds. Same class of error as a packet test.
- **A2**: no occlusion by world geometry (1, 13, 19, and g5 below).
- **A3**: says something changed, not what. 5b: panel visible, text unreadable. 6: paper doll arm
  sways inside the region. 19: the neighbour moves. A region helps only if the test knows where to look.
- **A4**: counts pixels owned, not legibility. 5b counts 9030 pixels of black panel.

### Instability

In the final runs every cell was stable across 5 runs. Instability seen in earlier runs of the same
code, under load 21 to 58:

- Scene 9, A3, false positive 1 of 5 (27029 pixels of sky): the session started 2 s after join. Fixed
  by waiting. See "Join settle".
- Scene 6, A3, correct 1 of 5 in one gate 2 run. **Inferred**: the arm happened not to move.
- Scene 12, A4, false positive 2 of 5, then 4 of 5, then 3 of 5: my bug, see "A4 changes what it
  measures".

A4 counts across 5 runs (gate 0, gate 2 within 40 pixels of these): 18d 35170 to 35170, 18e 38803 to
38819, 18h 22169 to 22203, 20 48144 to 48173 with a neighbour moving. A3 on scene 20 ranged 59642 to
85892, because it counts the neighbour too.

Truth moved while observers ran (fresh frame versus truth frame, pixels): zero except scenes with
animation (6, 18e, 18h, 19, 20), the toast in 15a, and scene 12, where A4 itself is the cause.

## Scene 16: the camera ride

Packet only display entity, spectated, 5 blocks per second. "Stalls" is the share of samples with
under 20% of the commanded speed. "Still" is the share of frames with almost no pixels changed.

| Sampling | Runs per mode | Tick median speed, both | Per frame stalls, smooth | Per frame stalls, jerky | Still, smooth | Still, jerky |
|---|---|---|---|---|---|---|
| Uncapped, about 190 to 320 FPS | 5 | 4.94 to 5.0 | 0.02 to 0.04 | **0.92 to 0.93** | 0.00 to 0.02 | **0.70 to 0.72** |
| Capped 60 FPS | 3 | 4.98 to 5.17, one 0.0 | 0.02 to 0.16 | **0.67 to 0.74** | 0.00 to 0.05 | **0.53 to 0.61** |
| Gate 2, on demand about 120 Hz | 3 | 4.96 to 5.02 | 0.03 | **0.83 to 0.84** | 0.01 | **0.66 to 0.68** |
| Gate 2, on demand about 19 Hz | 1 | 4.96 to 5.0 | 0.03 | 0.14 | 0.00 | 0.09 |

- **Per tick sampling cannot tell.** A broken ride and a good ride look the same.
- **Per frame camera sampling tells cleanly at 60 Hz and up.** A1 and A2 read the same values here. A2
  reads `cameraRenderState.pos`, what the frame was actually drawn from. Rule that split every run:
  stalls above 0.5 means jerky.
- **Near the tick rate the signal is gone.** At 19 Hz (1 run) stalls are 0.14, so a ride check cannot
  be thinned out.
- A3 flow agrees, without knowing what a camera is, but needs textured content in view. **Inferred**:
  it goes blind over empty sky.
- A4 has no answer for motion.
- Sampling needs real frames during real wall clock time: a 3 s ride costs 3 s. Ties into the open
  question on tick clock versus wall clock in the README.

## Costs

Per check, median and p95 ms over 30 samples, one zombie, four labels, title, chat and bar on screen.
Load 33 to 37, the worst of the run. First run at load 20 to 22 gave about the same except PNG.

| Check | Gate 0 | Gate 2 |
|---|---|---|
| A1 held state | 2.7 / 4.4 | 0.3 / 1.0 |
| A2 draw one frame and read | 5.9 / 11.1 | 5.9 / 11.6 |
| A2 read latest frame, no draw | 1.9 / 4.1 | 0.5 / 1.3 |
| A3 grab | 8.9 / 11.8 | 11.6 / 16.4 |
| A3 diff only | 3.5 / 15.9 | 3.3 / 5.7 |
| A3 grab plus diff | 12.6 / 20.0 | 20.7 / 49.1 |
| A3 grab plus PNG | 316 / 438 | 278 / 454 |
| A4 text | 28.2 / 37.0 | 25.6 / 37.4 |
| A4 entity | 25.7 / 33.6 | 26.5 / 33.7 |
| A4 block | 62.6 / 82.2 | 50.2 / 61.0 |

- PNG was 109 to 117 ms at load 20 to 22. Encoding dominates and swings with load. A verdict never
  needs it: **raw A3 is 13 to 21 ms, not the 131 ms in `c-speed.md`**. C's number is 54 ms for 30
  settle frames plus PNG. Settle frames are the real price of a scene with a new block and are not in
  this table.
- Gate 2 costs the observers nothing. The render state they need comes from the frame on demand.
- A4 p95 in the battery is about 50 ms: a tick crossing voids the pair and it runs again.

Keeping them enabled, A2 off and on, four rounds of 8 s each:

| | FPS | Client CPU % | Hook time per frame |
|---|---|---|---|
| A2 off | 298, 326, 362, 333 | 118, 94, 69, 70 | 0.3 to 0.6 us |
| A2 on | 305, 339, 351, 349 | 85, 72, 64, 69 | 8.7 to 18.5 us |

- Load 25 to 33. **No FPS or CPU cost visible above noise.** The 9 to 18 us is under 1% of a 3 ms frame.
- A1, A3, A4: no per frame work until asked. Grabbing on every frame got 292 to 473 grabs in a ride
  where 573 to 952 frames were drawn without it (load 25). Grabs can be skipped under back pressure,
  so this is not a clean FPS number.

## A4 changes what it measures

- Hiding a block means a client side `setBlock` to air and back, with sync compile. That compiles the
  section, so a stale mesh gets repaired by the check: scene 12 is 0 pixels before and 35170 after,
  every run, both modes.
- A retry on a tick crossing then saw a world the first try had changed. That was the false positive.
  Blocks no longer retry; 5 of 5 correct since.
- **Rule: read A2 first, and A4 once, for a block.** Entities and text are suppressed at submit, so
  they leave the world alone.
- Block hide spans 4 frames, so it can cross a tick. With something moving nearby a block check needs
  a region. **Inferred**, not in the battery.

## Other A4 candidates

Time box spent on the differential, which answered every scene. None of these was built. All **inferred**
from reading 26.3 sources.

| Candidate | What it would take | Why not |
|---|---|---|
| ID pass | Replace the pipeline for each submitted model, block and text with a flat colour, second render target | Touches every feature renderer. Translucency needs its own answer. Days, not hours |
| Entity outline target | Mark the entity glowing, read the outline target | Vanilla outline is known not to depth test, so occlusion is lost. Entities only |
| Depth compare | Read the depth texture, compare to the thing's own depth | Needs the thing's geometry and a backend specific depth format |
| Gizmo proxy | `Gizmos.cuboid(AABB, GizmoStyle.fill(argb))`, depth tested, count the colour | Measures the box, not the model. Fair for blocks, which could avoid the mesh repair above. Worth trying if that repair bites |

## Flexibility

Brand new kinds, lines per observer:

| Kind | A1 | A2 | A3 | A4 |
|---|---|---|---|---|
| Boss bar text | 28: Java 12, accessor mixin 14, Python 2 | 0 | 0 | 0 |
| Sidebar | 22: Java 19, Python 3 | 0 | 0 | 0 |
| Framework change | New reader per kind, sometimes a mixin | None, adding the kind name to a list | None | None |

Results over 5 runs. Every observer was correct except A1:

| Scene | Truth | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| f1 boss bar | yes | ok | ok | ok | ok |
| f2 boss bar, HUD hidden | no | FP | ok | ok | ok |
| f3 sidebar title, f4 sidebar line | yes | ok | ok | ok | ok |
| f5 sidebar, HUD hidden | no | FP | ok | ok | ok |

- Limit: A2 and A4 read the bar's title, not its fill. A1 holds the progress value. A3 sees the fill as
  pixels against a reference. Fill in A2 needs a sprite and size in the element record: **inferred**
  under 10 lines.

Kind free checks, written once, then run on what the framework never saw:

| Scene: "any text containing X" | Truth | A1 | A2 | A3 | A4 |
|---|---|---|---|---|---|
| g1 action bar | yes | ? | ok | ok | ok |
| g2 sign text on the far side, seen from behind | no | ? | ok | **FP** | ok |
| g2b sign facing the player | yes | ? | ok | ok | ok |
| g3 entity name tag | yes | ? | ok | ok | ok |
| g4 label in a screen | yes | ? | ok | ok | ok |
| g5 sign facing the player, behind a wall | no | ? | **FP** | ok | ok |
| g6 nothing | no | ? | ok | ok | ok |
| t1 first Diamonds toast, unscoped diamond check, 1 run | yes | FN | ok | ok | ok |

- A2 and A4 correct 61 of 61 here. Check is 6 lines of Python for A2, one word for A4.
- A3 cannot read text. It can only report that an area changed.
- "This entity covers more than N visible pixels" is `vis` plus a comparison, one line: 18e gives
  38.8k, 18h gives 22.2k, so N = 30000 tells whole from half. That threshold is picked from this data.
- The only new code for these kinds is the scene's own arrange step (`boss`, `sidebar`).

## Recommendation

| Kind | Use | Evidence | Not clean |
|---|---|---|---|
| Title, subtitle, chat, action bar, boss title, sidebar, screen labels | A2 run: position, colour, alpha, share on screen, cover | 5 of 5 on 6 to 11, 17, 18, f, g | Cover assumes textured panels are opaque |
| Entity, display entity, name tag | A2 and A4 | 1, 3, 4, 5, 18, 19, 20 | Two lookups, 30 ms |
| World text legibility | A2 and A4 | 5b, g2, g5 | Text the colour of what sits behind it, no background: untested |
| Fake block | A2 first, then A4 once | 12, 13, 18d | A4 repairs a stale mesh |
| Sound | A2 only | 14, 18f | Computed values, nothing is heard. Truth is by design |
| Fake inventory | A2 item hook in the hotbar region | 15, t1 | Region needed, a toast icon fools the unscoped check |
| Camera ride, any motion | Per frame render state, at 60 Hz or more | Scene 16 | Wall clock cost |
| Whether it looks right | A3 frame, for a person or a golden | 17, axis F | Not a verdict on its own |
| Boss bar fill | A1 now, A2 with a small addition | f1 | A1 is fooled by HUD hidden |

- **"Seen" should be one primitive: A2 says it was drawn legibly, A4 says it owns visible pixels.**
- Keep A1 only for arranging and for naming the cause of a failure: the server did not send it, or the
  client held it and did not show it. Never as the verdict.
- A3 as a verdict needs a region and a still scene. Its value is the frame for recording and goldens.
- Gaps no scene covers: fog, blindness, darkness, glass and other translucent occluders, particles,
  text overlapping text. Expect A4 to handle occluders, by construction. **Inferred.**

## What surprised me

- **Looking at the frame found a truth I had wrong.** I marked g2 as visible. The frame showed a blank
  board: the text is on the far side. A2 and A4 were right, A3 agreed with my mistake.
- **An unplanned lie.** The first Diamonds advancement draws a diamond icon in a toast, which fooled
  every unscoped inventory check.
- **Join settle.** Frames keep changing for about 9 s after join, the whole sky, 870k pixels at 1 s,
  and 0 from 9.4 s on. **Inferred**: it passed the stability wait at 2 s because it is slow.
- **Gate 1 can leave a block undrawn.** Scene 12 stayed stale for over 2.3 s in 4 of 4 clean runs when
  nothing touched it (how long beyond that: not measured). A probe at another position healed in 16 to 64 ms in 6 of 8 and stayed stale in 2
  of 8. So it is a race, not a fixed delay.
- **Modes match to the pixel.** 27 of 33 gate 2 truth frames equal gate 0 within 8 of 255 per channel.
  The other 6 are moving things (6, 18e, 18h, 19, 20) and the toast (15a).

## What should change in the search

- **C**: drop gate mode 1. It loses world updates. Mode 2 passed everything here, with block scene 18d
  correct 5 of 5.
- **F**: try the pinned with and without pair for noise. A4 stays within 60 pixels with a moving
  neighbour. Wait out the join settle, or reset within a long lived client.
- **B**: raw grab is 9 to 12 ms. PNG is 110 to 320 ms. Encode away from the render thread.
- **G**: the requirement reads "seen" and the framework runs A2 and A4. Rides read a sampled path.
- **H**: must rerun A3 and A4 on Vulkan and llvmpipe. A2 sits on the extract and submit stages and
  **inferred** does not care about the backend.

## Reuse

- `Frames.grab` and `Frames.diff`: raw frame read back through the engine's GPU API, on any render
  target. `pix.stable` waits for a still frame.
- `Drawn`: per frame JSON of everything submitted. Hide switches suppress one thing by id or text.
- `DeltaPinMixin`: frozen partial tick, for pairs of frames.
- `Speed.drawThen`: run code after N whole frames in any gate mode.
- `SoundEngineMixin`: silence on top of the options, at the computed volume.
- `orchestrator/observe.py` `scene_list`: the battery, each scene with a truth. Reuse it to check any
  new observer or renderer.

## Rerun

From the worktree root, build:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

From `prototypes/game-verification`. Each stops its Paper and client, launches silently:

```
python3 orchestrator/observe.py battery --reps 5 --shots --wait-toast 10
python3 orchestrator/observe.py battery --gate 2 --reps 5 --shots --wait-toast 10
python3 orchestrator/observe.py ride --reps 5 --shots
python3 orchestrator/observe.py ride --reps 3 --fps 60
python3 orchestrator/observe.py ride --reps 3 --gate 2 --draw-hz 500
python3 orchestrator/observe.py cost --rounds 4 --seconds 8
python3 orchestrator/observe.py flex --shots --wait-toast 10
python3 orchestrator/observe.py flex --reps 5 --wait-toast 10
python3 orchestrator/observe.py probe --reps 8 --join 30
python3 orchestrator/observe.py report
```

## Evidence

Under `prototypes/game-verification/runs/`, gitignored:

- `a-observers.jsonl`: final rows, every verdict with detail and timing. `a-observers-run1.jsonl` and
  `a-observers-run2.jsonl`: earlier runs, source of the instability notes.
- `a-frames/s<id>.png`, `s<id>-gate2.png`, `s<id>-diffmask.png`: frame the truth comes from, last run.
  Flex scenes are `sf*`, `sg*`, `st1`. Ride is `s16-smooth-end.png`, `s16-jerky-end.png`.
- `a-battery5-gate0.log`, `a-battery5-gate2.log`, `a-flex5.log`, `a-cost.log`, `a-cost-run1.log`,
  `a-ride.log`, `a-ride-60.log`, `a-ride-gate2.log`.

Frames were looked at in the runs before the last. Scene code did not change between them, the final
pixel counts match, and the gate 2 frames were compared pixel by pixel with gate 0.
