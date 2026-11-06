# H: does a real client plus real Paper hold on the free runner

## Answer

- **Yes, on both x86 and arm, with both renderers.** Real Minecraft 26.3 client plus real Paper 26.3 on `ubuntu-24.04` and `ubuntu-24.04-arm`, 4 vCPU, 16 GB, no GPU.
- **The 3 second statement is safe for reset, render and observation.** Trivial requirement: **0.100 s** at 20 TPS, **0.010 s** at server rate 200 gated, **0.005 s** direct gated. Same as the M1 Max within noise. Requirement duration remains the open unknown (see C).
- **Frame on demand, including the PNG: 0.07 to 0.12 s in a void scene (10 frames, always clean), 0.13 to 0.19 s in terrain (3 frames, see the note on noise).**
- **Flakes: 0** failed joins out of 238 client starts, 0 crashes, 0 wrong verdicts in 44000 requirements, 0 dirty cleanups, over 22 jobs on fresh runners. One infrastructure outlier: apt took 9 min 13 s once.
- **Recommended: x86 `ubuntu-24.04`, Vulkan through lavapipe, render gate on, `ALSOFT_DRIVERS=null`, renderer asserted.** OpenGL is a fine second, see "Which renderer".

Machine for every number: GitHub hosted runner, 4 vCPU, about 16 GB, Ubuntu 24.04.5, Temurin 25.0.5, Mesa 25.2.8 (`25.2.8-0ubuntu0.24.04.4`), LLVM 20.1.2. Renderer strings: x86 `llvmpipe (LLVM 20.1.2, 256 bits)`, arm `llvmpipe (LLVM 20.1.2, 128 bits)`; driver `4.5 (Core Profile) Mesa 25.2.8...` for OpenGL, `1.4.318 llvmpipe Mesa 25.2.8...` for Vulkan. Each table states the runner CPU. Framebuffer true 854x480 in all runs unless stated (`fbWidth`, `fbHeight` from the client), Xvfb has no high density scaling. Load 1 minute average 2 to 4. Steal 0.0 in every window measured. Options as in `run.py` (`options_txt`: no clouds, no AO, no shadows). Client and Paper Xmx 1g.

## Evidence

| Run | What |
|---|---|
| [42035165842](https://github.com/gabber235/Typewriter/actions/runs/42035165842) | Smoke: setups, both arches, one frame per backend (cold Gradle cache) |
| [42036899158](https://github.com/gabber235/Typewriter/actions/runs/42036899158) | 17 jobs: FPS, throughput, flakes, several clients |
| [42039542479](https://github.com/gabber235/Typewriter/actions/runs/42039542479) | 5 jobs: backends on one runner, several clients after a harness fix, frame in terrain |
| [42032658381](https://github.com/gabber235/Typewriter/actions/runs/42032658381) | Harness bug, plus the 9 min apt outlier |
| [42032359485](https://github.com/gabber235/Typewriter/actions/runs/42032359485) | Paper download 403 |

Artifacts per job: `h.jsonl` (each row carries CPU, Mesa, renderer), `c-speed.jsonl`, `shots/`, `h-evidence/` (log tails). 14 day retention, so the first three expire around 2026-11-19.

## 1. Does it run, and what setup

Measured on x86 and arm, same result. Client alone to the title screen, 12 to 18 s.

| Variant | Asked | Got | Note |
|---|---|---|---|
| Plain, Xvfb `+extension GLX` | opengl | **Vulkan** | `Couldn't find matching GLX visual`, silent fallback |
| `SDL_OPENGL_FORCE_SRGB_FRAMEBUFFER=skip` | opengl | OpenGL | A patch around Xvfb's GLX having no sRGB visual |
| `SDL_VIDEO_FORCE_EGL=1` | opengl | OpenGL | Same result without GLX |
| No extra setting | vulkan | Vulkan | Nothing else needed |
| No flag | default | Vulkan | OpenGL fails first, then falls back |

Needed setup:

```
apt: xvfb libgl1-mesa-dri libglx-mesa0 libegl1 libegl-mesa0 libgbm1 mesa-vulkan-drivers libvulkan1
     libx11-6 libxext6 libxcursor1 libxi6 libxrandr2 libxss1 libxfixes3 libxkbcommon0 libxkbcommon-x11-0 libasound2t64
Xvfb :N -screen 0 1280x1024x24 +extension GLX +render -noreset -nolisten tcp
env:  DISPLAY=:N SDL_VIDEODRIVER=x11 SDL_AUDIODRIVER=dummy ALSOFT_DRIVERS=null
      LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
      SDL_OPENGL_FORCE_SRGB_FRAMEBUFFER=skip  (OpenGL only)
```

- **Silent fallback is real; every session in `ci.py` asserts** backend, a software renderer, and volumes 0. 0 assertion failures.
- **Arm has no Fabric or LWJGL surprise.** Same Gradle build, no change at all.
- Sound: 0 proven by the mod's `master` and `music` facts in every session. Without a device `Failed to open OpenAL device` turns the sound system off, so a sound observer would see nothing. **`ALSOFT_DRIVERS=null` gives `OpenAL initialized on device No Output`, `Sound engine started`.** Measured in the log only; a sound event reaching an observer was not tested.
- Frames viewed at full size: OpenGL and Vulkan, void and default world. World, terrain, water, HUD, hotbar, hand, title, chat, per player block and packet only entity all drawn correctly.

## 2. Time

Seconds, tuned Paper, void world, 100 sessions of the flake jobs.

| | Paper to Done | Client to first world frame |
|---|---|---|
| x86, median (range) | 10.3 (8.0 to 16.6) | 16.0 (12.0 to 24.2) |
| arm, median (range) | 11.2 (10.2 to 13.9) | 16.3 (14.5 to 19.4) |

First session of a job, on a cold JVM and disk: Paper 12.9, client 19.6, worst client 29.0.

**Job start to first in world, warm Gradle cache: 77.6 s median on x86 (57.5 to 107.6, n=15), 77.4 s on arm (74.7 to 81.3, n=4).** Queue time and Set up job (1 to 2 s) not included. Parts: checkout and JDK 1 to 5 s, apt 11 to 45 s (median 14), cache restore 7 to 25 s, Gradle 9 to 27 s, Paper then client 25 to 45 s. Cold cache: Gradle step 49 to 119 s.

Inferred, not run: starting Paper and client together would save about 10 s. Caching the apt packages would save about 10 s, and remove the outlier in section 5.

## 3. FPS

Rendering on, Paper alongside, 10 s window after up to 17 s in the world. Client TPS and server ticks per s were 20 in every cell, mspt 1.4 to 3.4. Each column is one job on one CPU, so **do not compare columns for backend** (see next table).

| World, size, render distance, `LP_NUM_THREADS` | OpenGL, EPYC 9V74 | Vulkan, EPYC 7763 | OpenGL arm, Neoverse-N2 |
|---|---|---|---|
| Void, 854x480, 2, default | 144 | 129 | 98 |
| Default, 854x480, 2, default | 57 | 49 | 39 |
| Default, 854x480, 2, 2 | 53 | 42 | 29 |
| Default, 854x480, 5, default | 27 | 22 | 18 |
| Default, 854x480, 5, 2 | 23 | 21 | 14 |
| Default, 427x240, 2, default | 98 | 83 | 64 |
| Default, 427x240, 2, 2 | 91 | 74 | 54 |
| Default, 427x240, 5, default | 36 | 30 | 22 |
| Default, 427x240, 5, 2 | 33 | 27 | 19 |

- Render distance matters more than pixels: rd 5 to 2 gives 2.1 to 2.9 times, 854x480 to 427x240 gives 1.3 to 1.7 times.
- `LP_NUM_THREADS=2` costs 7 to 27 percent FPS and frees 0.1 to 0.7 vCPU (client 240 percent to 180 percent, rd 2).
- An uncapped rendering client with default threads burns most of the machine: 1.9 to 3.2 vCPU busy, client 170 to 300 percent, Xvfb 0 to 6 percent.
- **Runners differ more than backends.** Six CPU models across 22 jobs: EPYC 7763, 9V74, 9V45, Xeon 8573C, Xeon 6975P, Neoverse-N2. Same void cell, OpenGL: 119 to 136 on 7763, 137 to 179 on 9V74, 288 on 9V45. Default world rd 5 on x86: 23 to 41. The renderer string is the same for all five x86 models. **FPS must never be a test threshold on this runner.**

### Which renderer

Same runner, alternating, 2 rounds per backend. 854x480.

| CPU | Void FPS, GL / VK | Default rd 5 FPS, GL / VK | R4 rate 200, s, GL / VK | R3 rate 200, s, GL / VK | Client RSS terrain MB, GL / VK |
|---|---|---|---|---|---|
| EPYC 9V74 | 179, 170 / 155, 143 | 31, 31 / 27, 28 | 0.030, 0.030 / 0.031, 0.030 | 0.164, 0.170 / 0.105, 0.107 | 1700 / 1430 |
| EPYC 7763 | 119, 122 / 112, 104 | 23, 23 / 19, 21 | 0.041, 0.042 / 0.047, 0.042 | 0.214, 0.225 / 0.152, 0.144 | 1665 / 1530 |
| EPYC 7763 | 135, 136 / 127, 127 | 26, 25 / 22, 23 | 0.037, 0.035 / 0.037, 0.037 | 0.197, 0.194 / 0.125, 0.136 | 1720 / 1460 |

- OpenGL gives 6 to 17 percent more FPS. Vulkan uses 130 to 270 MB less and is about 35 percent faster at R3 ungated (arrange 80 to 110 ms against 130 to 180 ms; cause not looked at).
- Frame on demand in terrain is close: equal at 1 frame, Vulkan up to 22 percent slower at 3 to 5 frames in some runs, see section 4.
- Pixels, same runner, same scene: void frames differ by at most 2 of 255 (0 pixels over 8). Terrain 3528 to 4250 pixels over 8, a little above the frame noise of one renderer below (2.0k to 2.4k), so not separated.
- **Recommendation: Vulkan.** It needs no patch environment variable, it is the backend the client picks by itself here, and 26.4 snapshots reportedly default to it (not checked here). OpenGL with the sRGB skip is a working second when rendered FPS matters. With the gate on, the choice hardly affects throughput. Recommendation, not a measurement.

## 4. Throughput

`speed.py c3`, every 20th requirement broken. Seconds per passing requirement, median and p95.

| Recipe | n | OpenGL, EPYC 7763 | Vulkan, EPYC 9V45 | OpenGL arm, Neoverse-N2 | Client CPU % rendering or gated |
|---|---|---|---|---|---|
| R4 tick, gate 0 | 200 | 0.100, 0.109 | 0.100, 0.105 | 0.100, 0.117 | 260 to 292 |
| R4 tick, gate 2 | 200 | 0.100, 0.101 | 0.100, 0.101 | 0.100, 0.102 | 24 to 49 |
| R4 direct, gate 2 | 1000 | **0.0052**, 0.0076 | **0.0048**, 0.0067 | **0.0055**, 0.0079 | 75 to 87 |
| R4 tick, rate 200, gate 2 | 1000 | **0.0100**, 0.0147 | **0.0100**, 0.0115 | **0.0100**, 0.0149 | 44 to 88 |
| R4 tick, rate 200, gate 0 | 200 | 0.043, 0.059 | 0.029, 0.051 | 0.049, 0.064 | 241 to 264 |
| R3 tick, rate 200, gate 0 | 200 | 0.201, 0.393 | 0.073, 0.211 | 0.181, 0.255 | 187 to 221 |
| R3 tick, rate 200, gate 2 | 200 | 0.051, 0.085 | 0.045, 0.072 | 0.045, 0.071 | 62 to 99 |
| R3 tick, rate 200, gate 2, uncapped | 200 | 0.052, 0.118 | 0.045, 0.069 | 0.048, 0.075 | 85 to 99 |

- **Gated, the runner matches the M1 Max**: 0.0052 against 0.0056; 0.010 against 0.0102. Rendered, the gate is worth far more here: at rate 200 it is 3 to 5 times faster and the client uses 3 to 6 times less CPU. Observe time on the 7763: 2.3 ms gated against 15.6 ms rendered.
- Fail decision by barrier: 2 to 3 ms gated, 7 to 19 ms rendered.
- Wrong verdicts and dirty cleanups in this table: 0.

### Gate against CPU

`c1 cpu`, 2 rounds, 8 s windows, void. Client percent; send to seen median ms.

| Mode | EPYC 7763 OpenGL | EPYC 9V45 Vulkan | Neoverse-N2 OpenGL |
|---|---|---|---|
| Unlimited | 282, 311; 13.7 ms; 115 to 154 FPS | 258, 274; 9.4 ms; 181 to 254 FPS | 287, 306; 18.2 ms; 88 to 114 FPS |
| 60 FPS | 134, 126; 32.8 ms | 89, 81; 32.9 ms | 193, 167; 32.8 ms |
| 20 FPS | 56, 46; 51.1 ms | 33, 31; 50.7 ms | 93, 59; 51.2 ms |
| Gate 2 | **10, 8; 2.3 ms** | **8, 7; 2.3 ms** | **10, 8; 2.3 ms** |

Same content in every mode in every round, 20 client TPS. **A gated client costs 10 percent of one vCPU against 3 vCPU, and its latency is 4 to 8 times better.**

### Frame on demand

`c1 frame`, gate 2, 3 rounds. Draw k frames, write a PNG, compare 0.8 s later with the gate open. Medians. Pixels over 8 of 255.

| Frames | Void: 7763 GL drawn, written ms; pixels | Void: 9V45 VK | Void: N2 GL | Terrain rd 5: 7763 GL drawn, written ms; pixels |
|---|---|---|---|---|
| 1 | 11, 47; 11k to 37k | 8, 31; 48k | 12, 40; 11k to 48k | 37 to 42, 84 to 103; 14k to 50k |
| 2 | 15, 48; 44k to 49k | 14, 37; 37k to 49k | 27, 54; 11k to 37k | 76 to 78, 122 to 131; 4k to 42k |
| 3 | 22, 57; 7k to 11k | 16, 40; 11k | 31, 58; 0 to 11k | 121, 167 to 176; 1k to 4k |
| 5 | **45, 78; 0** | 24, 49; 0 to 12k | 46, 76; 11k | 192 to 203, 237 to 257; 3k to 5k |
| 10 | 69, 102; 0 | **48, 71; 0** | **92, 121; 0** | 374 to 404, 420 to 461; 2k to 5k |
| 30 | 205, 238; 0 | 131, 155; 0 | 270, 298; 0 | 1117 to 1261, 1162 to 1325; 1k to 4k |

- **Pixel checks on this runner: about 0.1 s in a void scene, 0.13 to 0.19 s in terrain.** Fine against 3 s, but frames per requirement matter: 30 frames in terrain is over 1 s.
- Draw to PNG is 24 to 63 ms, less than the Mac's 80 ms (inference: the frame is already in RAM).
- Terrain never reached 0 pixels: 1k to 5k remain at every k (inference: water and hand animation over the 0.8 s, not looked at). A real golden needs F's control of animation. A counted frame is unreliable at low k here too; in void, 10 frames gave 0 in every run.
- Vulkan in terrain, 2 CPUs, 3 jobs: 33 to 40 ms for one frame, 72 to 87 ms written, about the OpenGL figures. At 3 to 5 frames up to 22 percent slower in some runs.

### Barrier trap

`--late-ticks 1`: **95 of 95 wrong in 3 of 3 jobs** (285 of 285), 220 of 300 cleanups dirty, as on the Mac. With `--fail timeout --obs-timeout 150`: 0 wrong, decision at 151 ms.

## 5. Stability

From runs 42036899158 and 42039542479, 22 jobs, each on a new runner. Flake jobs (10; 6 OpenGL x86, 2 Vulkan x86, 2 OpenGL arm): three cycles each of R4 tick 100, R4 rate 200 gate 2 500, R3 rate 200 100, each with a fresh Paper and client, then a terrain frame.

| Event | Count |
|---|---|
| Client starts, each to a world frame | 238 (217 sessions, 21 in the several client runs) |
| Failed joins | **0** |
| Crashes, `hs_err` files | **0** |
| Renderer or silence assertion failures | **0** |
| `c3` requirements, without the deliberate trap | 34200 |
| Wrong verdicts, dirty cleanups | **0, 0** |
| Several client requirements after the fix | 9800; **0, 0** |
| `Can't keep up` in Paper | **0** |
| Leaked processes | **0** |

- **4 wrong verdicts were my harness, not the runner**: 4 of 4900 in the first several client run, all at 4 clients. It reused ping numbers across phases, so a barrier could count as passed already and fail a requirement before its effect arrived. Unique rising pings gave 0 of 9800 on 2 more jobs. **Lesson for E: a barrier id must never repeat on a connection.**
- 9 of the R3 sessions had errors in Paper's log, none in any other kind of session. The 4 logs kept (a repeated label overwrites) are all Paper's watchdog printing a 10 s thread dump at `poolInit`, when 8 pool worlds took long on the main thread (measured 4.0 to 14.6 s). Not a crash; the requirements after it passed.
- **Infrastructure: 1 of 21 x86 jobs spent 9 min 13 s in the apt step** (run 42032658381; where inside the step was not timed in that run). The same step was 11 to 45 s otherwise, and 14 to 27 s in 7 arm jobs. A suite time limit must allow for it, or the packages should be cached.
- Not covered: requirements other than trivial ones, a single client living long (longest session a few minutes), hours of soak.

## 6. Memory and several clients (first look at D)

One client plus Paper: **client RSS 1.3 to 1.5 GB in void, 1.4 to 1.8 GB in terrain; Paper 0.9 to 1.2 GB. Machine 3.0 to 3.8 GB used of 16 GB** including about 1.3 GB at idle. Gated CPU is a tenth of a vCPU plus Paper.

N clients on one Paper, each with its own Xvfb, its own region, void, rd 2, OpenGL, started together. Two jobs: EPYC 9V74, EPYC 9V45.

| N | All joined s | Rendered FPS each | Busy vCPU rendered | Machine GB | Req/s, gate 0, 20 TPS | Req/s, gate 2, 20 TPS | Req/s, gate 2, rate 200 | Busy vCPU, gate 2 rate 200 | p95 s at rate 200 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 19.5, 16.4 | 174, 288 | 3.1, 3.2 | 3.4, 3.6 | 9.9, 10.0 | 10.0, 10.0 | 99, 100 | 0.95, 0.36 | 0.010, 0.011 |
| 2 | 29.6, 21.4 | 85, 133 | 3.4, 3.3 | 4.7, 4.7 | 19.9, 19.9 | 20.0, 20.0 | 198, 200 | 0.81, 0.87 | 0.011, 0.011 |
| 4 | 65.9, 47.0 | 41 to 51, 62 to 67 | 4.0, 4.0 | 7.3, 7.5 | 35.9, 37.7 | 40.0, 40.0 | 387, 396 | 1.89, 1.14 | 0.013, 0.011 |

- **Gated, throughput scales linearly up to 4 clients, with vCPU to spare.** 8 clients are memory possible (inference, about 13 GB), not run.
- Rendered, FPS divides by N, and at 4 clients the machine saturates: p95 per client at 20 TPS 0.118 to 0.165 s, median 0.100 to 0.106 s.
- Joining together takes 3 times longer with 4 clients. Inference: they all render during the join. Staggering or gating during join may help; not tried.
- Rate is server wide, so these share one rate. Trivial requirements only.

## First look at F, uncontrolled (not a golden test)

Same seed, camera, OpenGL, default world rd 5. Toast gone, but water and hand are not frozen. 10 frames, pairs.

| Pair | Pixels differing at all, median | Over 8 of 255, median |
|---|---|---|
| Same x86 CPU model | 12.7k to 13.0k | 2.3k to 2.4k |
| Different x86 CPU models, 4 models | 11.8k to 14.1k | 1.3k to 3.2k |
| arm with arm | 13.0k | 2.0k |
| arm with x86 | **about 98k** | 1.2k to 3.3k |

- **No visible difference between x86 CPU models at this noise level, despite the mixed fleet. Arm with x86 shows many tiny differences** (inference: vector width 128 against 256). Goldens: pick one architecture and pin it. Whether exact identity holds across x86 models is for F, with animation controlled.

## Surprises

1. Throughput is the same as a 10 core M1 Max once gated. The software renderer stops being a cost because nothing is rendered.
2. The x86 fleet is a lottery: five CPU models in 18 jobs, FPS varies over 2 times between them under one renderer string.
3. Arm worked unchanged, with a single CPU model in 4 of 4 jobs, at about 0.6 times x86 FPS and the same gated speed.
4. OpenGL fails by default under Xvfb and falls back to Vulkan silently, as predicted.
5. A client with no audio device has its sound system off, which would blind a sound observer; one environment variable fixes it.
6. `settledAt` never arrived in the default world: 0 of 50 sessions (4 waited 45 s, 46 waited 15 s), against 19 of 19 in void. Inference: `isSectionCompiledAndVisible` is false for occluded sections around the feet. It is only proven in void. The note in C ("`settledAt` for pixels in the same world") holds for flat scenes only. Matters for E and F.
7. Paper's download host answers 403 to Python's default client name and 200 to a descriptive `User-Agent`.

## What this means for the search (for the README keeper)

- **H removes the fear that CI is the limit.** 4 vCPU without a GPU holds one to four gated clients at Mac speed. Rendered time is now a budget per frame, not a property of the whole run.
- **C**: the gate is not an optimisation on CI, it is the default. Requirement duration remains the only real unknown.
- **D**: on this first look 4 clients are linear when gated, so D is limited by rate sharing and isolation, not resources.
- **E**: barrier ids must be unique. Do not rely on `settledAt` outside flat scenes.
- **F**: a mixed x86 fleet does not visibly disturb frames, arm with x86 does. Pin the architecture, and test x86 identity once animation is controlled.
- **B**: terrain rendered at 22 to 41 FPS at 854x480 rd 5 (60 needs rd 2 and a good CPU), so per requirement capture likely needs a fixed step or low rate. Encoder cost is not measured.
- **Sound**: `ALSOFT_DRIVERS=null` should keep a sound observer possible on CI; prove it in A.
- Timing thresholds: use tick or fact based waits, never FPS or wall clock limits tuned on one runner.

## Rerun

Change `matrix.include` in `.github/workflows/game-verification-prototype.yml`, push to the prototype branch, then:

```
git push origin HEAD:feat/game-verification-prototypes
gh run list --branch feat/game-verification-prototypes --limit 1
gh run download <id> -D <dir>
```

A push cancels the run in progress. Plans in `orchestrator/ci.py`:

| Matrix row | What | Time |
|---|---|---|
| `{ plan: smoke, backend: both, runner: ubuntu-24.04, repeat: 0 }` | Setups, frames, short c3 | 10 min |
| `{ plan: fps, backend: opengl, ... }` | The FPS table, one backend | 10 to 12 min |
| `{ plan: speed, backend: vulkan, ... }` | Throughput, trap, `c1 frame`, `c1 cpu` | 10 to 13 min |
| `{ plan: flake, backend: opengl, ..., repeat: N }` | 3 full cycles; add rows for more | 7 to 9 min |
| `{ plan: multi, backend: opengl, ... }` | 1, 2, 4 clients | 5 min |
| `{ plan: compare, backend: both, ... }` | Backends on one runner, frame in terrain. One job came within 3 min of the timeout | 17 to 22 min |

`runner` is `ubuntu-24.04` or `ubuntu-24.04-arm`. `repeat` only makes a row unique. Job timeout 25 min; `ci.py` stops starting steps at 21 min so the artifact still uploads. The branch is left with one `smoke` row.

## Reuse in later spikes

- `orchestrator/ci.py`: `Xvfb`, `Cfg` (backend, size, render distance, world, `LP_NUM_THREADS`, GL setup, audio), `assert_renderer`, `CiSession` (replaces `speed.Session`, so any `speed.py` command runs unchanged through `run_speed`), `Usage` (CPU from `/proc`, machine vCPU busy, lowest free memory), `capture`, `Multi`, `step`, `record`.
- `ps -o time=` has 1 s resolution on Linux, too coarse for short runs. `ci.py` replaces `speed.cpu_seconds` with `/proc`.
- Small edits to existing files: `Client(width, height)` and `options_txt(width, height)` in `run.py`, a client name for the Paper download, Maven for the annotations jar in `probe-plugin/build.gradle`, fake blocks and entities per player in the plugin's `Speed.java`.
- Run dirs hold symlinks to the whole Paper cache. Never upload `runs/` as a whole: `upload-artifact` follows them. The workflow lists only `h.jsonl`, `c-speed.jsonl`, `shots`, `h-evidence`.
- Workflow notes: a failed job skips the cache save, hence `continue-on-error` on Measure, so read the `end` row of `h.jsonl` for failures rather than the job colour.
