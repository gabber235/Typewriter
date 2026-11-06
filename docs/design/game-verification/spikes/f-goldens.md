# F: can golden frames be stable

## Answer

- **Yes, to the exact pixel, on one pinned platform.** With seven knobs on, a golden scene (title, chat line,
  hotbar with an enchanted item, packet only zombie, fake block, water, lava, fire, torch, sky) rendered
  **byte identical** across repeated runs in one client, across fresh clients, and across **four x86 CPU
  models on the free runner** (Xeon 8370C, EPYC 7763, EPYC 9V45, EPYC 9V74). Terrain in the default world at
  render distance 5 is identical too. 265 identical scene pairs on a pinned platform, **0 differing pixels**.
- **Exact comparison caught every deliberate break, 1400 of 1400**, including a colour change of 3 levels
  that every tolerant method missed. No tolerance is needed where identity holds, and any tolerance gives away
  real misses.
- **The platform is part of the golden.** OpenGL against Vulkan on the same runner: the same 304 pixels, 1
  level. arm against x86: the same 82045 pixels every time, mostly 1 to 2 levels, 3 pixels above 8. Mac
  (OpenGL on Metal) against the runner: 77k to 110k pixels. Each of these is constant, not noise, so the
  answer is a golden per platform, approved from that platform's frames.
- **Recommended platform: x86 `ubuntu-24.04`, Vulkan through lavapipe, Mesa 25.2.8, 854x480, the spike's
  options.** It matches H's renderer choice, and its frames are the same on every CPU model the fleet gave.
- **The knobs that matter**: freeze the client level before arranging the scene, reset sprite animations to
  frame 0, pin the light flicker, vignette off, enchantment glint speed 0, spend advancement and recipe toasts
  once per session, and a render barrier whose two frames span a client tick. Pinning the partial tick, view
  bob off, and the render gate had no measurable effect on a still scene.
- **Comparison cost is no concern**: equality of two raw frames 0.04 ms, a SHA-256 0.55 ms, a full per pixel
  count 2.6 ms. Golden on disk: PNG 237 KB for the void scene, 311 KB for terrain, region crops 0.8 to 35 KB,
  or 32 bytes as a hash.
- **For the developer's decision**: on the pinned platform the numbers support failing a test on a golden
  mismatch (0 false alarms in 265 identical pairs, 0 misses in 1400 break comparisons). The open risks are
  scenes the knobs do not cover yet (moving camera, things spawned before the freeze) and platform upgrades,
  which change every golden at once (inferred). See "Fail or report".

Machines: the developer's M1 Max (OpenGL 4.1 on Metal, true 854x480 framebuffer, load 13 to 34), and the
GitHub free runner run [42118497980](https://github.com/gabber235/Typewriter/actions/runs/42118497980): 7 jobs,
`ubuntu-24.04` and `ubuntu-24.04-arm`, Mesa `25.2.8-0ubuntu0.24.04.4` in every job, renderer
`llvmpipe (LLVM 20.1.2, 256 bits)` on x86 and `128 bits` on arm, Vulkan `1.4.318`, OpenGL `4.5 Core`. Every
frame is 854x480, GUI scale 2, render distance 2 in void and 5 in terrain, options from `run.py`
(`options_txt`: particles minimal, no clouds, no AO, biome blend 0, mipmaps 0). Measured unless marked
**inferred**.

## The scene and the breaks

Void world, a diorama built by the plugin (`gscene`): grass floor, water and lava pools, stone brick wall,
fire on netherrack, a torch, leaves. Camera fixed at (0.5, 65, 0.5), yaw 0, pitch 20, creative mode. Each run
is one golden requirement: reset (`arena`), 0.2 to 1.0 s of random wait standing for the requirement before,
knobs, arrange (title `Quest Complete` in `#FFAA00`, chat line, hotbar `DIAMOND IRON_INGOT BREAD OAK_LOG
REDSTONE EXPERIENCE_BOTTLE`, packet only zombie at x = -1.5, fake `STONE` at (1, 66, 9)), render barrier, grab.

| Break | What changes | Pixels it changes, same platform |
|---|---|---|
| `text` | `Quest Complete` to `Quest Completa` | 320 |
| `color10` | title `#FFAA00` to `#FFA000` (green 10 lower) | 18880, all by 10 |
| `color3` | title `#FFAA00` to `#FFA700` (green 3 lower) | 18880, all by 3 |
| `dy1px` | title one framebuffer pixel lower (`TitleShiftMixin`, 0.5 GUI units) | 2400 |
| `block` | fake `STONE` to `ANDESITE` | 1818 |
| `entity` | zombie a quarter block to the side | 5426 |
| `item` | `BREAD` missing from slot 3 | 552 |

Each break was looked at in a side by side crop with its diff mask: the right letter, the whole title one row
down, the stone texture against andesite, the zombie shifted, one empty slot.

## F2: which knobs bring a frame to identity

Ablation within one client: each set is "all knobs minus one", 3 runs per set, pairs within a set. 63 pairs
per set over 21 sessions (Mac 3, runner 18), 30 for sets only run in the full sessions. "Fired" counts pairs
where exact comparison saw any difference.

| Set | Fired | Pixels differing | Largest delta | Where (frame looked at) | Cost in lines |
|---|---|---|---|---|---|
| **all** | **0 of 63** | 0 | 0 | | |
| no `freeze` | 30 of 30 | 10 to 36885 | 253 | water, lava, fire, zombie | 1: `mc.level.tickRateManager().setFrozen(true)`, then wait 150 ms |
| no `anim0` | 58 of 63 | 0 to 40790 | 253 | water, lava, fire textures | 48 (3 accessor mixins) plus 16 |
| no `early` | 61 of 63 | 0 to 1170 | 150 | zombie arms (idle swing from its age) | 0, an ordering rule |
| no `glint` | 30 of 30 | 437 to 450 | 102 | experience bottle in the hotbar | 1: `glintSpeed` 0 |
| no `vignette` | 20 of 30 | 0 to 155472 | 3 | whole frame outside a central ellipse | 1: `vignette` off |
| no `flicker` | 20 of 30 | 0 to 554 | 1 | grass lit by the torch | 21 (`FlickerMixin`) |
| no `pin` | 0 of 30 | 0 | 0 | | 0 needed |
| no `bob` | 0 of 30 | 0 | 0 | | 0 needed |
| no `gate` | 0 of 30 | 0 | 0 | | 0 needed |
| no `hud` | 0 of 30 | 0 | 0 | | see toasts below |
| none | 30 of 30 | 920 to 37026 | 253 | everything above | |

Terrain (default world, seed 20261105, spawn, flying, rd 5), 3 sessions on the Mac and 7 on the runner:

| Set | Pairs | Fired | Pixels | Largest delta |
|---|---|---|---|---|
| all | 33 | **0** | 0 | 0 |
| none | 33 | 33 | 155768 to 324428 | 2 to 46 |

What each knob is:

- `freeze`: the client's own tick freeze (`TickRateManager.setFrozen` on the client level, no server change).
  Vanilla then stops texture animation, particles, `animateTick` and entity ticks, and returns partial tick 1.0
  for the level (`Minecraft.java:1173`, `DeltaTracker.java`). The local player keeps ticking.
- `anim0`: every animated sprite set to frame 0 and uploaded (`Golden.animationsToStart`). Freeze alone keeps
  whatever phase the water had, which differs per run.
- `early`: freeze before arranging. An entity added while frozen has age 0; one added before the freeze has
  swung its arms for some ticks. This is the realistic order problem: a requirement that spawns an entity and
  then captures will not be identical (inferred fix: reset entity ages at capture, not built).
- `flicker`: `LightmapRenderStateExtractor.blockLightFlicker` is a random walk every client tick, even
  frozen (`GameRenderer.tick` is not gated).
- `vignette`: `Hud.vignetteBrightness` eases toward the light level by 1 percent per GUI tick
  (`Hud.java:1053`), so it drifts for tens of seconds after join or a light change. **Inferred**: this is most
  of A's "join settle" of about 9 s.
- `glint`: the glint scrolls with `Util.getMillis`; speed 0 stops it.
- `hud`: clearing chat and toasts. It shows 0 here only because session prep already spent the toasts.

Found before the ablation, each seen by eye at full size:

- **Toasts.** The first give of a diamond or iron ingot made `Advancement Made` and `New Recipe(s)
  Unlocked` toasts and chat lines slide in. Fix in session prep: `advancement grant <player> everything`,
  `recipe give <player> *`, `show_advancement_messages false`, then clear toasts and chat (5 lines in the
  plugin).
- **Light after the frame barrier.** The first run after the floor was built differed from every later run in
  151 grass pixels by 1 level: the new floor's light arrived after two identical frames. Building the scene once
  in prep and waiting 3 s removed it. Product consequence: a fresh build needs a light settle, not only a
  frame settle.
- **The barrier must span a client tick.** With the partial tick pinned, two frames inside one tick are always
  identical, so the first barrier passed while the player still drifted after a teleport: terrain run 1
  differed from runs 0 and 2 in 61145 pixels. Sleeping 110 ms between the barrier's two grabs fixed it: 0 in
  every later terrain pair.

## F1 and F4: across clients, runners, CPUs, renderers, architectures

Golden of one session against another session's, all knobs, full frame. Each job ran two fresh clients per
backend, so "fresh client" pairs come from every job and the Mac.

| Pair | Pairs | Exact fired | Pixels | Largest delta | Over 8 |
|---|---|---|---|---|---|
| Fresh client, same machine (Mac, every runner) | 24 | **0** | 0 | 0 | 0 |
| x86 Vulkan, same CPU model, other runner (EPYC 7763 x3) | 24 | **0** | 0 | 0 | 0 |
| x86 Vulkan, other CPU model (4 models) | 96 | **0** | 0 | 0 | 0 |
| x86 OpenGL, other CPU model (7763, 9V74) | 8 | **0** | 0 | 0 | 0 |
| OpenGL against Vulkan, x86 | 96 | 96 | 304, always the same | 1 | 0 |
| arm against x86, Vulkan | 48 | 48 | 82045, always the same | 252 | 3 |
| Mac against runner | 108 | 108 | 77496 to 109875 | 60 to 252 | 3 to 6 |
| Terrain, x86 Vulkan, other CPU model | 12 | **0** | 0 | 0 | 0 |
| Terrain, OpenGL against Vulkan | 12 | 12 | 377 | 18 | 2 |
| Terrain, arm against x86 | 8 | 8 | 98314 to 98320 | 196 | 79 to 82 |
| Terrain, Mac against runner | 18 | 18 | 112891 to 140338 | 196 | 82 to 152 |

- SHA-256 of the RGB frame confirms it: `afc241cd...` on all six x86 Vulkan jobs, `e2fb0745...` on both
  OpenGL jobs, `7a509c5c...` on arm, `92c97dc7...` on the Mac.
- **Inferred**: llvmpipe generates the same 256 bit code on every x86 model here (the renderer string is the
  same), so the CPU model does not reach the pixels. A Mesa or LLVM update is the likely thing that would; not
  tested.
- The GL against VK pixels are isolated single pixels over the whole frame. The arm pixels cover every
  textured surface at 1 to 2 levels, with 3 edge pixels far off (frame and mask looked at).

## Comparison methods, regions and breaks

Rules fixed up front: `exact` any pixel differs; `t8` any channel over 8; `t8>20` more than 20 such pixels;
`t16>20`; `blur4` and `blur8` 3x3 box blur first, then over 4 or 8; `ssim<0.99` minimum local SSIM on 7x7
luminance windows.

Same platform, all knobs. False alarms over 265 identical pairs, misses over 200 comparisons per break (each
break frame against every golden of its own platform, same and other client):

| Method | False alarms | text | color10 | color3 | dy1px | block | entity | item |
|---|---|---|---|---|---|---|---|---|
| **exact** | **0** | caught | caught | **caught** | caught | caught | caught | caught |
| t8, t8>20, blur4, blur8, ssim<0.99 | 0 | caught | caught | **missed 200 of 200** | caught | caught | caught | caught |
| t16>20 | 0 | caught | **missed** | **missed** | caught | caught | caught | caught |

Across platforms, where identity does not hold, a tolerance is the only option. False alarms per method on
identical scenes:

| Pair | exact | t8 | t8>20 | blur8 | ssim<0.99 |
|---|---|---|---|---|---|
| OpenGL against Vulkan, void (96) | 96 | 0 | 0 | 0 | 0 |
| arm against x86, void (64) | 64 | 64 | 0 | 64 | 64 |
| Mac against runner, void (108) | 108 | 108 | 0 | 12 | 108 |
| OpenGL against Vulkan, terrain (12) | 12 | 12 | 0 | 0 | 12 |
| arm against x86, terrain (8) | 8 | 8 | **8** | 8 | 8 |
| Mac against runner, terrain (18) | 18 | 18 | **18** | 18 | 18 |

- `t8>20` survives across architectures in the void scene and misses only `color3`. In terrain it alarms on
  every cross architecture pair. A tolerance tuned on one scene does not carry to another.

F3, region against full frame. Regions are the boxes the requirement names, taken with A4 (`vis`) on the
golden itself plus 4 pixels: title 608x80, zombie 85x119, slot 36x38, block 52x53.

| | Full frame | Region |
|---|---|---|
| Same platform, false alarms (exact) | 0 of 265 | 0 of 504 (126 per region) |
| Same platform, breaks caught (exact) | 1400 of 1400 | 1400 of 1400 |
| Same platform, `color3` with t8 | missed | missed |
| arm against x86, exact, pixels in the region | 82045 | title 12538, zombie 1244, block 635, slot 9; all at most 2 levels |
| Mac against runner, t8 | 108 of 108 alarm | title, block, slot 0; zombie 108 of 108 (2 pixels at 60) |
| Catches a change the requirement did not name (leftover block, stray entity) | yes | no, by construction (inferred) |

- On the pinned platform a region adds nothing for noise: the full frame is already exact. It only narrows
  what a failure means. Across platforms it shrinks the noise but does not remove it.

## Cost and size

Mac, load 13, numpy, one 854x480 RGB pair, median of 10 to 200 repetitions:

| Step | ms |
|---|---|
| Bytes equal, identical frames | 0.036 |
| `np.array_equal` | 0.056 |
| SHA-256 of the raw frame | 0.55 |
| Count differing pixels | 2.6 |
| t8 count | 4.3 |
| Blur then threshold | 32 |
| SSIM 7x7 | 26 |
| Title region: exact 0.016, SSIM 3.3 | |
| PNG decode | 5 |
| PNG encode, default 16, optimised 76 | |
| Readback of the frame (`g.grab`, client side), Mac void | 10 |
| Readback, runner Vulkan void 13.6, terrain 46 | |

Capture of one golden, render barrier included: Mac 0.05 s void (barrier without the tick gap), 0.13 s terrain
(both barriers); runner 0.18 s void, 0.55 s terrain (median, Vulkan, with the 110 ms gap and the 150 ms freeze wait).

| Golden on disk | Bytes |
|---|---|
| Full frame PNG, void scene | 232k to 238k (runner), 236k (Mac) |
| Full frame PNG, terrain | 311k (runner), 331k (Mac) |
| Region crops: title, zombie, block, slot | 35k, 6k, 2k, 0.8k |
| SHA-256 of the frame, when identity holds | 32 |

## Fail or report (for the developer's decision)

| | Fail the test on mismatch | Report on the pull request |
|---|---|---|
| False alarms measured | 0 of 265 identical pairs, platform pinned | same |
| Misses measured | 0 of 1400 (exact) | same |
| What causes a false alarm | a noise source no knob covers yet (new effect, moving camera, entity spawned before the freeze), or a platform change | same causes, but nothing goes red |
| Platform update (Mesa, LLVM, Minecraft) | every golden fails at once; needs a bulk approve (inferred, not tested) | a large report, nothing blocks |
| Developer's Mac | cannot reproduce a runner golden (77k to 110k pixels off) | same; approval comes from the runner's frame |

- Recommendation: fail on an exact mismatch on the pinned platform, show golden, frame and diff mask on the
  pull request, and approve a new golden from the runner's own frame. A golden whose two captures differ in one
  run, or whose barrier times out, is a framework error, not a test failure: it means a knob is missing.
  Recommendation, not a measurement; in the test review the developer chose "PR evidence only" for panel
  stories.

## Surprises

1. **x86 Vulkan frames are byte identical across four CPU models** that H measured at over 2 times FPS
   spread. The lottery fleet does not matter for pixels.
2. **The vignette** eases 1 percent per tick, so a frame keeps changing for tens of seconds with nothing
   moving. Most likely the cause of A's 9 s join settle.
3. **A pinned partial tick fools a frame stability barrier**: two frames in one tick are always equal.
4. **Light arrives after the frames look settled** when blocks are new (151 pixels, 1 level).
5. **The first item give fires toasts and chat lines** (advancements, recipes) that slide in by wall clock.
6. **A 3 level colour change is invisible to every tolerant method**, including SSIM.
7. **Platform differences are constant, not noise**: GL against VK is the same 304 pixels in every pair, arm
   against x86 the same 82045.
8. Pinning the partial tick, view bob and the render gate change nothing in a still scene, because the
   client's own freeze already returns partial tick 1.0 for the level and the player stands still.

## What this means for the search (for the README keeper)

- **F**: goldens are exact, not fuzzy, on one platform: x86, Vulkan, Mesa 25.2.8. Store a hash plus a PNG
  for people. Approve from runner frames; the Mac cannot produce them.
- **H**: Vulkan on x86 gets a third reason. Pin the Mesa version in the workflow and record it with every
  golden; a Mesa change should invalidate goldens explicitly rather than fail them one by one.
- **E**: a render barrier for pixels needs more than a fact barrier (B) and more than two equal frames: the
  pair must span a client tick, and a new build needs its light. Joins need the vignette off or settled.
- **A**: A3 pixels in a frozen scene are exact, so a region check on a golden is as strict as a fact. A
  freeze could also clean A3's noise from water and moving neighbours (inferred).
- **B**: a demo video stays unfrozen; goldens come from the gated run, frozen at capture.
- **G**: a requirement that names a golden must arrange its scene after the freeze, or the framework must
  reset entity ages at capture (inferred, not built). Moving camera goldens are untested.
- **C**: a golden costs about 0.2 s in void and 0.55 s in terrain on the runner, inside the 3 s statement.

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, one at a time (`SDL_MAC_BACKGROUND_APP=1`):

```
python3 orchestrator/goldens.py session --label mac-a --runs 3 --break-runs 2
python3 orchestrator/goldens.py session --label mac-b --runs 3 --sets all,no-anim0,no-early --break-runs 1
python3 orchestrator/goldens.py terrain --label mac-t3 --runs 3
python3 orchestrator/goldens.py analyse runs/f-goldens/<dir> [<dir> ...] --out runs/f-analysis.json
```

`analyse` takes any mix of session and terrain dirs, Mac and CI, and prints one line per pair kind, set or
break, region and pair class; the JSON holds every pair. Labels of CI dirs carry arch, backend, CPU and job.

CI: matrix rows `{ plan: goldens, backend: vulkan|opengl|both, runner: ubuntu-24.04|ubuntu-24.04-arm, repeat: N }`
in `.github/workflows/game-verification-prototype.yml`, plan `goldens` in `orchestrator/ci.py` (one full
session, one fresh session, one terrain session per backend; a Vulkan only job took 5 to 6 min, a `both` job
10 to 11 min). The workflow uploads
`runs/f-goldens.jsonl` and `runs/f-goldens`. Then:

```
gh run download 42118497980 -D runs/ci-f
python3 orchestrator/goldens.py analyse runs/ci-f/*/f-goldens/* runs/f-goldens/mac-* --out runs/f-analysis-all.json
```

The branch was left with the `smoke` row (pushed with `[skip ci]`).

## Evidence

- Run [42118497980](https://github.com/gabber235/Typewriter/actions/runs/42118497980), artifacts `h-goldens-*`
  (14 days, expire around 2026-11-19). Run 42117801001 was cancelled by the barrier fix push.
- Local, gitignored: `runs/f-goldens/mac-*` (frames and `meta.json` with every run's knobs, settle and
  timing), `runs/ci-f/` (the downloaded artifacts), `runs/f-analysis-all.json` and `.txt` (every pair),
  `runs/f-goldens.jsonl`.
- Frames looked at full size: Mac and runner golden, each break with its diff mask, each ablation mask
  (vignette, toasts, flicker, glint, early, anim0), the terrain drift, the GL against VK and arm against x86
  masks.
- Mac load during runs: 18 to 34 (1 minute average), 13 during the cost table; the machine was shared with
  other work.

## Reuse

- Client `probe-mod/.../golden/Golden.java`: `g.knobs` (`freeze`, `anim0`, `flicker`, `pin`, `vignette`,
  `bob`, `glint`, `hud`, `titleDy`), `g.grab` (raw RGBA to a file, 1 ms write), `g.same`. Mixins:
  `FlickerMixin`, `TitleShiftMixin` (a break, not a knob), and accessors for the atlas animation state.
- Plugin `probe-plugin/.../Golden.java`: `gscene` (the diorama), `gterrain`, `ghotbar`, `gprep` (spend
  toasts), `gfreeze` (server tick freeze, not used).
- `orchestrator/goldens.py`: `Golden.settle` (tick spanning render barrier), `metrics` and `METHODS`, `box`
  and `ssim_min` in plain numpy, `pair_class`, the break list.
- `Frames.Diff.json` is now public.
