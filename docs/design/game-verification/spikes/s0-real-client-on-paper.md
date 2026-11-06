# S0: real 26.3 client on external Paper

## Answer

- **Yes.** A real Minecraft 26.3 Fabric client joins a separately started Paper 26.3 (build 242) by address, offline, and plays.
- **Yes, a client mod reports what the player perceives.** Title, subtitle, action bar, chat, per player block, packet only entity and hidden entity reached the facts file in all 49 scene runs that got to the scene. Screenshots of the render target show all of them drawn.
- **Cost:** Paper Done in 7 to 9 s, client in the world in 11 to 13 s, about 1.15 GB RSS each. A scene item shows up in client facts 5 to 8 ms after the plugin sends it.

Machine for every number: M1 Max, 10 cores, 64 GB, JBR 25.0.3. Load average at the start of client runs was 9 to 23, mean 13, because other builds and the developer's apps ran at the same time. No build overlapped a timing run from this spike. Rendered numbers are OpenGL 4.1 on Metal unless stated.

## What was built

All in `prototypes/game-verification/`, gitignored output in `cache/`, `runs/`, `.mc-sources/`, `.gradle/`, `build/`.

| Part | Path | What |
|---|---|---|
| Client mod | `probe-mod/` | Facts as JSON lines per tick and per frame, events, screenshot on request, stop file, watchdog, mouse grab cancelled |
| Paper plugin | `probe-plugin/` | HTTP on localhost: title, chat, action bar, per player block, packet only TextDisplay, hidden real TextDisplay, status, stop. Compiled against the patched Paper jar, so NMS is direct |
| Orchestrator | `orchestrator/run.py` | Python classes `Paper`, `Client`, `FactReader`; commands `prepare`, `sources`, `boot`, `menu`, `scene`. Always stops both processes, checks with pgrep |

## Rerun

From the worktree root:

```
python3 prototypes/game-verification/orchestrator/run.py prepare
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain :probe-mod:genSources :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
python3 prototypes/game-verification/orchestrator/run.py sources
python3 prototypes/game-verification/orchestrator/run.py boot --world void --mode fresh --repeat 2
python3 prototypes/game-verification/orchestrator/run.py menu --label x
python3 prototypes/game-verification/orchestrator/run.py scene --world void --rd 2 --xmx 1g --rounds 10 --fps-seconds 15 --keep
```

Useful flags on `scene`: `--backend opengl|vulkan`, `--launcher gradle`, `--window-clear 0x2000`, `--facts changes`, `--server-xmx`. Results append to `runs/results.jsonl`. `--keep` keeps the run dir and takes `client/scene.png`.

Versions: Gradle wrapper 9.8.2 (Loom 1.19 refuses 9.6.1), Loom 1.19-SNAPSHOT, loader 0.20.1, Fabric API 0.165.0+26.3.

## Paper boot to Done

Wall seconds from process start, Xmx 1g, 3 repeats per row, load 6 to 16. Paper's own figure is 0.3 s lower, except cold where it is 3.2 s lower.

| World | Cold: paperclip downloads and patches, new world | Patched, new world | Patched, existing world (second boot) |
|---|---|---|---|
| Default | 11.4, 11.5, 11.7 | 8.9, 9.0, 9.3 | 6.8, 7.7, 8.1 |
| Flat | not run | 7.6, 7.9, 8.1 | 7.3, 7.5, 8.1 |
| Void | not run | 7.6, 8.1, 8.7 | 7.1, 7.4, 7.6 |

- World type buys about 1 s, only on a new world. Inference: most of the boot is JVM, server class loading and plugin setup.
- Patching itself: 3 s once, with a fast network.

## Client start

Seconds from process spawn, 3 repeats, load 8 to 15.

| Step | Direct `java` | Gradle `runClient`, up to date, daemon alive |
|---|---|---|
| JVM running | 0.03 | 3.3 |
| Mod init | 5.9 to 6.4 | 9.4 to 9.6 |
| First frame | 8.1 to 8.4 | 11.3 to 11.9 |
| Title screen | 9.7 | 12.5 to 13.2 |
| Loading overlay gone | 11.7 | 14.5 to 15.2 |

Joining with `--quickPlayMultiplayer`, server already up, load 10 to 12, 3 repeats:

| Step | Direct | Gradle |
|---|---|---|
| Connect screen | 9.6 to 11.2 | 13.2 to 15.1 |
| Joined, level ready | 11.1 to 12.6 | 14.6 to 16.5 |
| First world frame with player section compiled | 11.5 to 13.0 | 15.0 to 16.9 |

- Connect to level ready takes 1.4 s; level ready to first world frame takes 0.4 s.
- Gradle adds about 3.3 s per start and **holds the xtask heavy lock for the whole game**. Later spikes use direct launch: `probe-mod/build/client-launch.json` holds main class, classpath and JVM args (from `writeClientLaunch`), and `Client` in `run.py` uses it.
- Vulkan: the very first Vulkan run reached the connect screen at 14.3 s; later ones at 9.5 to 11.9 s, the same as OpenGL within noise. Cause of the first slow run not looked at.

## Memory

RSS and physical footprint in MB at steady state after the scene. Void world, render distance 2, unless stated. Heap used was 230 to 400 MB in every run.

| Client Xmx | RSS | Footprint | GC pauses in about 30 s | Max pause | Full GC | Trouble |
|---|---|---|---|---|---|---|
| 2g | 1140 to 1145 | 1141 to 1154 | 44 to 51 | 16 ms | 0 | None |
| 1g | 1130 to 1158 | 1204 to 1230 | 47 to 52 | 22 ms | 0 | None |
| 768m | 1123 to 1127 | 1137 to 1212 | 58 to 61 | 23 ms | 0 | None |
| 512m | 1119 to 1129 | 1147 to 1199 | 69 to 78 | 20 ms | 0 | None |
| 384m | 1108 to 1140 | 1102 to 1122 | 95 | 21 ms | 0 | None |
| 256m | 979 to 984 | 982 to 1058 | 165 | 81 ms | 2 | Runs, stutters |
| 512m, default world, rd 5 | 1170 | 1478 | 92 | 24 ms | 0 | None |

- **Client Xmx 512m is safe for these scenes; 384m also passed.** RSS barely moves, so most of the 1.1 GB is outside the heap (inference: metaspace, code cache, native graphics and texture memory).
- Vulkan: RSS about 1200 to 1240, footprint 1345 to 1400 in void and 1600 to 1690 in the default world.
- Without `-Xmx` a JVM on this machine would be allowed 16 GB. Always set it.

| Server Xmx | RSS | Result |
|---|---|---|
| 1g, default world | 1322 to 1443 | Fine, TPS 19.8 to 20 |
| 1g, void | 1196 to 1251 | Fine, TPS 19.8 to 20 |
| 768m, void | 1219 | Fine |
| 512m, void | 1167 | Fine |
| 384m, void | 1026 | Fine |
| 256m, void | none | **Did not reach Done in 240 s.** Cause not looked at |

## FPS and backend

Frames counted over 15 s, 2 runs per cell unless stated, `--facts changes`, window 854x480 logical, framebuffer 1708x960 (see Retina below). Noise is high because of machine load.

| World, render distance | OpenGL 4.1 Metal | Vulkan through MoltenVK 1.4.2 |
|---|---|---|
| Void, 2 | 327, 337, later 450, 473, 485 | 210, 222 (one more run: 120) |
| Void, 5 | 437, 540 | 120, 120 |
| Default, 2 | 341, 350 | 120, 120 |
| Default, 5 | 279, 327 | 120, 120 |

- Real 854x480 through `--window-clear 0x2000`: void rd 2 403, 463, 593; default rd 5 303; Vulkan 120. No clear gain over 1708x960 on this GPU.
- Writing a fact on every frame versus on change only: one run 370 at load 18 versus 327 to 337 at load 10, so no visible cost at this precision.
- Client TPS 20.0 in all runs.
- Vulkan held exactly 120 in most runs even though the client asks for IMMEDIATE, then MAILBOX, then FIFO (`GpuSurface.java:41`). Inference: MoltenVK locks to the display refresh; why two runs passed 200 is unknown.
- Renderer strings. OpenGL: `Apple M1 Max`, `4.1 Metal - 91.7`. Vulkan: `Apple M1 Max`, `1.2.350 MoltenVK 1.4.2`. Both are in the `renderer` event of the facts file.

Backend selection in 26.3:

- `options.txt` key `preferredGraphicsBackend`, values `default`, `opengl`, `vulkan`. Launch argument `--graphicsBackend` overrides it.
- `default` and `opengl` try OpenGL first, then Vulkan; `vulkan` tries Vulkan first, then OpenGL. So **a failed backend falls back silently; assert the renderer fact**.
- After an unclean shutdown during startup, the client changes the preference itself (Vulkan to default, default to OpenGL). Do not kill a client during startup and then reuse its game dir.

## Scene to facts latency

From plugin `sentMicros` to the first client fact showing it, same clock. Median per run, void, OpenGL, 10 rounds, direct launch, 3 runs, load 10 to 11.

| Item | Median ms |
|---|---|
| Title | 5.3 to 7.4 |
| Chat | 5.1 to 8.4 |
| Action bar | 5.0 to 7.8 |
| Per player block | 6.1 to 7.5 |
| Packet only entity | 5.1 to 6.9 |
| Hidden real entity | 5.9 to 8.3 |

- Largest single sighting per run across all items: 31 to 35 ms. The first use of an item is the likely cause (inference).

- Default world, rd 5, OpenGL: about 15 to 25 ms. Vulkan: 14 to 36 ms. Inference: frame time plus load.
- With few rounds the first hidden entity takes 30 to 75 ms.
- Nearly every first sighting was a frame fact, not a tick fact. Inference: an observer limited to ticks adds up to 50 ms.
- Title lifetime seen by the client for fades 10, 40, 10 ticks: 2.95 to 3.01 s against 3.0 s expected.
- Server side check: packet only entities are absent from the world on Paper (0), hidden ones are present (10), and the client sees both. The per player block check reads air on Paper in void.
- The 8 runs flagged false in `all_ok` are all default world runs where the test position was already terrain on Paper. The precondition check failed, not the client sighting.

## 1.21.4 claims against 26.3 sources

Sources: Loom `genSources` took 1m16s on a first run, 7301 classes. Jar: `prototypes/game-verification/.gradle/loom-cache/minecraftMaven/net/minecraft/minecraft-merged-1b0498e74c/26.3/minecraft-merged-1b0498e74c-26.3-sources.jar`. Extracted by `run.py sources` to `.mc-sources` (47 MB). Search with an explicit path: `rg -n noRender prototypes/game-verification/.mc-sources`.

| Claim | 26.3 | Where |
|---|---|---|
| `Minecraft.noRender` skips rendering while ticking | **Gone.** No match in the whole source tree | `Minecraft.renderFrame`, `net/minecraft/client/Minecraft.java:1227`, called from `runTick` at `:1205` |
| `Util.timeSource` public static mutable | **Changed.** Field is private; public static setter does the same job. Moved to `net.minecraft.util`. The client installs the SDL clock at startup, so a virtual clock goes in after that | `net/minecraft/util/Util.java:114`, `:171`, `:185`; `Minecraft.java:462` |
| Client clock caps at 20 TPS through `Math.max(50, mspt)` | **Holds**, written as `Math.max(defaultTickTargetMillis, manager.millisecondsPerTick())` with default 50 from `Timer(20.0F, ...)` | `Minecraft.java:291`, `:2930`; `DeltaTracker.java:62` |
| Max 10 ticks per frame | **Holds.** Ticks above 10 are dropped because the residual is already subtracted | `Minecraft.java:1179`; `DeltaTracker.java:65` |
| `mainRenderTarget` includes GUI | **Holds**, now on `GameRenderer`. Also observed: a PNG from it shows HUD, title, chat, and toast | `GameRenderer.java:114`, `:508`; blit at `Minecraft.java:1299` |
| Where backend selection lives | New `PreferredGraphicsApi`, chosen in the `Minecraft` constructor | `PreferredGraphicsApi.java:36`; `Minecraft.java:467` to `:489`; `Options.java:137`, `:1534`; `client/main/Main.java:84` |

Consequence of `noRender` being gone: `renderFrame` also holds frame counting, real time delta, `gui.update`, `level.update`, `gameRenderer.update` and `extract` (`Minecraft.java:1264` to `:1339`). Skipping the whole method would stop those. A render on demand mixin should gate only `gameRenderer.render()`, blit and present (`:1294` to `:1322`). Not tried.

## Options for a quiet client

`options_txt` in `run.py`. Names checked against `Options.java`:

- `version:5023` first; without it the data fixers run on the file (`Options.java:1785`).
- All `soundCategory_*:0.0`; the mod records master and music in the `renderer` event, always 0.0.
- `pauseOnLostFocus:false`, `inactivityFpsLimit:"minimized"` (same name as 1.21.4; values `minimized`, `afk`), `maxFps:260`, `enableVsync:false`.
- `graphicsPreset:"custom"`. **`"fast"` applies its own bundle at load and put render distance back to 8.**
- `onboardAccessibility:false`, `tutorialStep:none`, `narrator:0`, `skipMultiplayerWarning:true`, `joinedFirstServer:true`, `realmsNotifications:false`.
- Launch arguments: `--username`, `--offlineDeveloperMode` (no Microsoft account; skips the services discovery and user API, `Minecraft.java:413`, `:826`), `--gameDir` per client, `--width`, `--height`.

Input and focus: env `SDL_MAC_BACKGROUND_APP=1` plus a mixin cancelling `MouseHandler.grabMouse`. Across all runs the frontmost app was always one of the developer's apps, never the client. No control run without the hint, on purpose, because it could steal focus. Whether the hint or the missing activation is what keeps focus is not separated. `Window.isFocused()` stays true in these runs because the field defaults to true and no focus event arrives (`Window.java:68`), so do not treat it as evidence.

## What surprised

- **`noRender` is gone**, see above.
- Client state already lied once. A TextDisplay with yaw 0 in front of the player: the facts said the client knew the entity and its text, and the screenshot showed nothing, because the fixed text faces away. Turned to yaw 180 it was drawn. This is a ready scene for axis A.
- Retina doubles the framebuffer: 854x480 gives 1708x960 because `Window.java:152` passes high pixel density (flags 8224, 0x2000 is the bit). Linux on Xvfb will not do that. `--window-clear 0x2000` gives true 854x480. Matters for axis F.
- `hasRenderedAllSections()` is true at level ready, before sections exist. `isSectionCompiledAndVisible` under the player and the exit from `LevelLoadingScreen` are the useful signals; they came within 50 ms of each other in the runs where both were logged. Matters for axis E.
- `white-list=true` in the server.properties Paper 26.3 generates. It must be set to false.
- A toast "Chat messages can't be verified" appears because `enforce-secure-profile=false`. It sits in the top right of early frames and would break goldens.
- With quick play the client is in the world before the loading overlay is gone: `load_finished` comes after `first_world_frame`. Goldens must wait for it.
- 26.x moved names: title state in `Hud`, not `Gui`; `Gui.screen()` and `Gui.overlay()` replace `Minecraft.screen` and `Minecraft.overlay`; `EntityTypes.TEXT_DISPLAY`; `com.mojang.renderpearl` for the GPU API.
- Fabric API cannot be left out by filtering the classpath; Loom's transformed Minecraft jar references it (`ClassNotFoundException: AttachmentTarget`). Removing it needs a Gradle change, so its startup cost is not measured.

## What went wrong in this spike

- A Gradle task dependency mistake ran `runClient` for about 5 minutes (18:46 to 18:51) with default options: **sound and menu music on**, on the developer's machine, without the background hint. It was stopped when noticed. The dependency is fixed, every orchestrated client asserts zero volume, and `runClient` now seeds a silent `options.txt` if none exists. The seed itself was not exercised.

## Reuse in later spikes

- `Paper(run_dir, world, xmx)`: `start`, `wait_done`, `cmd`, `status`, `stop`.
- `Client(game_dir, server, backend, xmx, rd, watch, window_clear)`: `start`, `wait_event`, `events`, `stop`.
- `FactReader(path)`: `poll`, `first`, `wait`, on raw lines.
- `shot(client, name)`: writes a path into `<gameDir>/probe.shot`; the mod saves `mainRenderTarget` as PNG at the next tick. Screenshots from the last runs: `runs/shots/opengl.png`, `runs/shots/vulkan.png`.
- Facts: `k` is `e`, `t` or `f`; `at` is epoch microseconds, same clock as the plugin's `sentMicros`; add a field in `Probe.perceived`.
- Plugin: add a case in `ProbePlugin.run`; NMS compiles directly.
- A stop file and a watchdog in both processes (client 600 s, server 900 s) stop leaks if the orchestrator dies.
- The Gradle daemon stays idle until its own timeout. It is not a game process.

## What this means for the search (for the README keeper)

- **C1 changes**: render on demand now needs a mixin, not a field.
- **C3 looks required**: 11 to 13 s client start and 7 to 9 s server start cannot sit inside a 3 s per test budget, while seeing an effect costs milliseconds. Reset cost is the question.
- **C4 world choice buys about 1 s**; look at JVM level options such as class data sharing (not tried here).
- **A**: the facing away TextDisplay is the first lying scene.
- **D**: about 1.15 GB per client at Xmx 512m means memory is unlikely to be the limit on this machine (inference); CPU and GPU contention are untested.
- **F4 and H**: this Mac defaults to OpenGL on Metal, Fabric's CI to Vulkan on lavapipe. Compare with framebuffer size forced equal.
