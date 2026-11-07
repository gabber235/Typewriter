# Golden frames on the devenv Mesa (proto/gv-goldens)

Question: do spike F's exact golden frames stay deterministic on the renderer the devenv e2e profile
provides (Mesa 26.2.5 from the pinned nixpkgs `674a2028`), instead of Ubuntu's apt Mesa 25.2.8?

## Answer

- **Yes, on both backends.** Every scene got **one hash** across repeats, fresh clients, jobs and CPU
  models. **0 differing pixels in 18540 identical pairs** on Mesa 26.2.5.
- **Vulkan through lavapipe** holds across **6 x86 CPU models**; OpenGL through llvmpipe across 4 (the
  run that would have added the other two failed on an assertion bug, see Surprises).
- **Exact comparison still catches every small break**: one letter, colour off by 3, one pixel lower,
  and the other four of spike F. 60480 of 60480 comparisons caught, the same pixel counts as on 25.2.8.
- **A Mesa upgrade changes every golden.** All 18 golden hashes (2 backends, void, terrain, 7 breaks)
  differ between 26.2.5 and 25.2.8. The change is small: 1260 to 1578 pixels in void, 2533 to 2849 in
  terrain, almost all off by 1 level.
- **Same code, Ubuntu Mesa still gives spike F's frames exactly**: the apt control on this branch
  matched spike F's frames at 0 pixels, so the prototype changes after F did not move a pixel.

## Setup

- GitHub free runner `ubuntu-24.04`, x86, 4 vCPU. 854x480, GUI scale 2, render distance 2 in void and
  5 in terrain, spike F's options and knob set `all`, render barrier over two frames 110 ms apart.
- **devenv jobs**: `devenv --profile e2e shell` provides Xvfb 21.1.24, Mesa 26.2.5, LLVM 21.1.8,
  libglvnd 1.7.0, vulkan-loader 1.4.363 and the JDK (25.0.4). Only the orchestrator's numpy and Pillow
  come from apt; no Mesa package is installed by apt.
- **apt control**: spike F's workflow, same commit, Ubuntu Mesa `25.2.8-0ubuntu0.24.04.4`, LLVM 20.1.2.
- Renderer asserted per client: backend asked equals backend got, llvmpipe or lavapipe, and the Mesa
  version in the driver string equals 26.2.5 on devenv jobs.

| Job kind | Renderer string (gpu, driver) |
|---|---|
| devenv, Vulkan | `llvmpipe (LLVM 21.1.8, 256 bits)`, `1.4.354 llvmpipe Mesa 26.2.5 (LLVM 21.1.8)` |
| devenv, OpenGL | `llvmpipe (LLVM 21.1.8, 256 bits)`, `4.6 (Core Profile) Mesa 26.2.5` |
| apt, Vulkan | `llvmpipe (LLVM 20.1.2, 256 bits)`, `1.4.318 llvmpipe Mesa 25.2.8-0ubuntu0.24.04.4 (LLVM 20.1.2)` |
| apt, OpenGL | `llvmpipe (LLVM 20.1.2, 256 bits)`, `4.5 (Core Profile) Mesa 25.2.8-0ubuntu0.24.04.4` |

Per job and backend: two fresh void clients (4 and 3 golden runs, 2 and 1 runs of each break, one
regions reference) and two fresh terrain clients (3 golden runs each).

## Determinism on Mesa 26.2.5

| Backend | Scene | Frames | Jobs | Clients | CPU models | Distinct hashes | Identical pairs | Pairs that differ |
|---|---|---|---|---|---|---|---|---|
| Vulkan | void | 144 | 16 | 32 | 6 | **1** | 10296 | **0** |
| Vulkan | terrain (water) | 96 | 16 | 32 | 6 | **1** | 4560 | **0** |
| OpenGL | void | 72 | 8 | 16 | 4 | **1** | 2556 | **0** |
| OpenGL | terrain (water) | 48 | 8 | 16 | 4 | **1** | 1128 | **0** |

Identical pairs by class, Vulkan void: same client 256, fresh client same job 320, same CPU model other
job 1782, other CPU model 7938. Every class 0 pixels. Each break frame also got one hash per backend
across all jobs.

CPU models: Vulkan on EPYC 7763, EPYC 9V45, EPYC 9V74, Xeon Platinum 8370C, Xeon Platinum 8573C,
Xeon 6973P-C. OpenGL on the first three and Xeon Platinum 8573C.

Apt control (25.2.8, this branch): 1 hash per scene and backend over 3 jobs, 6 clients, EPYC 9V74 and
Xeon 6973P-C (a CPU model spike F did not see).

## Breaks, exact comparison, Mesa 26.2.5

Each break frame against every void golden of its own backend, same and other jobs.

| Break | Vulkan caught | OpenGL caught | Pixels changed (26.2.5) | Pixels changed (25.2.8) |
|---|---|---|---|---|
| `text` (one letter) | 6912 of 6912 | 1728 of 1728 | 320 | 320 |
| `color3` (green 3 lower) | 6912 of 6912 | 1728 of 1728 | 18880 | 18880 |
| `dy1px` (title one pixel lower) | 6912 of 6912 | 1728 of 1728 | 2400 | 2400 |
| `color10` | 6912 of 6912 | 1728 of 1728 | 18880 | 18880 |
| `block` (stone to andesite) | 6912 of 6912 | 1728 of 1728 | 1808 | 1809 |
| `entity` (quarter block) | 6912 of 6912 | 1728 of 1728 | 5426 | 5426 |
| `item` (missing slot) | 6912 of 6912 | 1728 of 1728 | 552 | 552 |

## Mesa 26.2.5 against 25.2.8

One golden per group; every group is a single hash, so these numbers hold for every pair.

| Scene | Pair | Pixels differing | Largest delta | Over 8 |
|---|---|---|---|---|
| void | Vulkan 26.2.5 vs Vulkan 25.2.8 | 1351 | 12 | 1 |
| void | OpenGL 26.2.5 vs OpenGL 25.2.8 | 1260 | 12 | 1 |
| terrain | Vulkan 26.2.5 vs Vulkan 25.2.8 | 2729 | 185 | 22 |
| terrain | OpenGL 26.2.5 vs OpenGL 25.2.8 | 2533 | 185 | 22 |
| void | OpenGL vs Vulkan, 26.2.5 | 354 | 1 | 0 |
| terrain | OpenGL vs Vulkan, 26.2.5 | 345 | 18 | 2 |
| void | OpenGL vs Vulkan, 25.2.8 (spike F: 304) | 304 | 1 | 0 |
| terrain | OpenGL vs Vulkan, 25.2.8 (spike F: 377) | 377 | 18 | 2 |
| void, terrain | apt this branch vs spike F run, each backend | 0 | 0 | 0 |

- Golden hashes changed by the upgrade: **18 of 18** (void, terrain, 7 breaks, both backends).
- Where (diff masks looked at full size, `results-mesa/void-diff.png`, `results-mesa/terrain-diff.png`):
  isolated single pixels over the world geometry (grass, water, stone, hills), 2690 of 2729 terrain
  pixels at 1 level. The 14 pixels at 20 or more (up to 185) sit on far silhouette edges where hills
  meet the water. Title, chat, hotbar and hand: unchanged.
- A tolerance does not bridge the upgrade either: `t8>20` would pass void (1 pixel over 8) and alarm
  on terrain (22 over 8), the same pattern spike F saw across architectures.

## Capture time

Render barrier plus the final grab, freeze wait not included. Median, p90 and max in seconds.

| Source | Backend | Void | Terrain |
|---|---|---|---|
| devenv 26.2.5 | Vulkan | 0.195, 0.25, 0.35 (n 144) | 0.53, 0.83, 1.01 (n 96) |
| devenv 26.2.5 | OpenGL | 0.192, 0.24, 0.35 (n 72) | 0.46, 0.76, 0.87 (n 48) |
| apt 25.2.8, this branch | Vulkan | 0.185, 0.22, 0.28 (n 27) | 0.52, 0.73, 0.88 (n 18) |
| apt 25.2.8, this branch | OpenGL | 0.184, 0.22, 0.29 (n 27) | 0.51, 0.77, 0.96 (n 18) |

No barrier timed out (0 unstable of 450 golden captures). Whole plan per job: 7 to 9 min on devenv,
7.7 min on apt, on the same CPU model (EPYC 9V74) 469 s against 464 s.

## Surprises

- **Shell setup dominates the job**: `.github/actions/devenv` with the e2e profile took 300 to 480 s
  per job on this branch (untrusted, so no Cachix push, every path pulled), against 12 s for the apt
  install. The base shell (Flutter, Rust and the rest) comes along with the e2e profile.
- **The pinned Mesa reports OpenGL 4.6**, apt's reports 4.5; the OpenGL vendor field is the bare word
  `Mesa`. A version check must read the driver string only: the first run's regex matched
  `Mesa 4.6` across the vendor and driver fields and failed every OpenGL client of run 42343076555
  (renderer was correct). Fixed in run 42344338415.
- **The runner's apt index was stale**: installing Pillow without `apt-get update` hit a 404 and
  killed all 8 devenv jobs of run 42342581580 before they measured.
- **The profile was missing for the game client** (added on this branch only): `libglvnd` (LWJGL
  dlopens `libGL.so.1`, which Nix's Mesa does not ship), vulkan-loader, libX11, libXext, libXcursor,
  libXi, libXrandr, libXfixes, libXScrnSaver, libXtst and libxkbcommon on `LD_LIBRARY_PATH`, and
  `ALSOFT_DRIVERS=null`. With them, no OpenGL client fell back to Vulkan or to another Mesa.

## Evidence

- Branch `proto/gv-goldens`. Runs: [42342581580](https://github.com/gabber235/Typewriter/actions/runs/42342581580)
  (apt control 8 only; devenv jobs died at apt), [42343076555](https://github.com/gabber235/Typewriter/actions/runs/42343076555)
  (8 devenv Vulkan, OpenGL failed on the assertion bug, apt control 18),
  [42344338415](https://github.com/gabber235/Typewriter/actions/runs/42344338415) (8 devenv both
  backends, apt control 28). Spike F frames from run 42118497980 (jobs 0, 1, 4).
- Analysis: `orchestrator/mesa.py` over every session dir; output `results-mesa/mesa-analysis.json`.
