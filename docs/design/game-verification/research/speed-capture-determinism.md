# Speed, capture and determinism research

Technical facts for prototype candidates that make real Minecraft client tests fast, deterministic
and recordable. Target: Paper server, Fabric client, MC 1.21.4, Linux CI (4 vCPU, 16 GB, no GPU,
Mesa llvmpipe on Xvfb) and local Apple Silicon. Researched 2026-11-05 by reading only; nothing was
downloaded or run.

Labels:

- **[verified]**: read in source or official docs.
- **[log]**: read from a public CI log (real run, one sample).
- **[reported]**: stated by a third party or project, not checked.
- **[inferred]**: reasoned from verified facts, not tested.

Client code citations are a community decompiled 1.21.4 mirror with Mojang names (`KernelDotDLL/mcp-1.21.4`),
because Mojang publishes no source. Line anchors refer to that mirror. Yarn name in brackets where useful.

## A. Time dilation

Names:

- Mojang `TickRateManager` is Yarn `TickManager`; `ServerTickRateManager` is Yarn `ServerTickManager`. There is no `ClientTickRateManager`: `ClientLevel` holds a plain `TickRateManager`. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/multiplayer/ClientLevel.java#L190
- The packets are `ticking_state` (rate, frozen) and `ticking_step` (steps). **[verified]** https://minecraft.wiki/w/Java_Edition_protocol/Packets

The client clock:

- **The client clock can only go slower than 20 TPS, never faster.** `getTickTargetMillis` returns `Math.max(50, millisecondsPerTick)` while running normally, and the plain 50 ms when frozen. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L2763
- Wiki confirms: "Rates above the default do not speed up players". **[verified]** https://minecraft.wiki/w/Commands/tick
- Mojira MC-267511 asks why, closed as Works As Intended. **[reported]** https://bugs-legacy.mojang.com/browse/MC-267511
- Consequence at rate above 20: server world, mobs and plugin tasks run fast, while the local player, title timers, chat fades and entity interpolation run at 20 TPS. A plugin sequence and the visuals it drives drift apart compared with normal play. **[inferred]**
- Below 20 the whole client follows the server, so slow motion works without a mod. **[verified]** same line.
- A one method mixin removes the ceiling; two public mods do exactly this. **[verified]** https://github.com/Mat0u5/TickRatePlayers/blob/main/src/main/java/net/mat0u5/tickrateplayers/mixin/MinecraftClientMixin.java and https://github.com/Moulberry/Flashback/blob/master/src/main/java/com/moulberry/flashback/mixin/MixinMinecraft.java
- **The client runs at most 10 ticks per frame and drops the rest.** `for (j < Math.min(10, i))` with the residual already consumed. So a sped up client needs at least `TPS / 10` frames per second or it silently loses ticks (20 FPS for 200 TPS). **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L1175
- Client ticks only happen inside the frame loop, on the render thread. Render cost directly limits logic speed. **[verified]** same line.

Scope and Paper:

- Rate and freeze are server wide: `broadcastAll`. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/server/ServerTickRateManager.java
- The client value is per `ClientLevel` and set by a packet, so one client can be given its own rate or freeze by sending it the packet alone. A Paper plugin does per player client tick rate. **[verified]** handler https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/multiplayer/ClientPacketListener.java#L633; **[reported]** plugin https://hangar.papermc.io/GodModed/TickRateChangerSkriptAddon
- World change is safe: `PlayerList.sendLevelInfo` resends tick state after a respawn or dimension change. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/server/players/PlayerList.java#L659
- Paper keeps it: `org.bukkit.ServerTickManager` has `setTickRate` (1 to 10000), `setFrozen`, `stepGameIfFrozen`, `requestGameToSprint`, `stopSprinting`, `isFrozen(Entity)`. **[verified]** https://jd.papermc.io/paper/1.21.4/org/bukkit/ServerTickManager.html
- Paper's tick loop patch keeps the sprint branch, gated on `!isPaused()`. Set `pause-when-empty-seconds=0` or sprint stops when no player is online. **[verified]** https://github.com/PaperMC/Paper/blob/ver/1.21.4/paper-server/patches/sources/net/minecraft/server/MinecraftServer.java.patch and https://minecraft.wiki/w/Server.properties
- **Bukkit tasks and connections keep running during freeze.** `tickRateManager.tick()` then `tickChildren` is unconditional, and `mainThreadHeartbeat` is the first line of `tickChildren`. So a frozen server still runs the plugin under test, and tick counted tasks still count. **[verified]** same patch.
- Sprint is server only. It sends no rate to the client, which stays at its clock and receives a burst. Good for setup, not for visual steps. **[inferred]** from https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/server/ServerTickRateManager.java
- Step is not a lockstep barrier: server and client each count down `frozenTicksToRun` on their own clock. **[inferred]** from https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/world/TickRateManager.java

Effects on what is drawn:

- Interpolation: entity move and teleport handlers call `lerpTo(..., 3)`, so entities settle over 3 **client** ticks (150 ms at 20 TPS) whatever the server rate. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/multiplayer/ClientPacketListener.java#L578
- Titles: `Gui.tick` is only gated by `pause`, not by freeze, and decrements `titleTime` each client tick. **Titles keep fading and expire during `/tick freeze`.** A 70 tick title lasts 3.5 s real time even with the server at 200 TPS. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L1664 and https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/gui/Gui.java#L1137
- Chat age follows the same GUI tick count. **[inferred]** same file.
- `pause` needs a singleplayer server, so a multiplayer client never truly pauses. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L1251

Does freeze give a stable frame? **Mostly for the world, no for the HUD.** Stable while frozen **[verified]**:

- Partial tick is pinned to 1.0 for callers passing `false` (sky, clouds, GUI, frozen entities). The camera and lightmap update pass `true` and keep a live value, harmless for a still camera. https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/DeltaTracker.java and https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/GameRenderer.java#L637
- Non player entities skip client tick, unless a player rides them. https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/world/TickRateManager.java
- Animated textures, `animateTick` particles, particle ticks, cloud `ticks` and client day time stop. https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L1674 and https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/LevelRenderer.java#L1016

Still moving while frozen **[verified]**:

- Players keep ticking, including packet based player NPCs, which are `Player` instances on the client (the Typewriter NPC case, **[inferred]**).
- `lightTexture.tick()` is not gated (flicker, see F). https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/GameRenderer.java#L190
- Enchant glint, HUD timers, toasts, text cursor (wall clock, see F).

Upper limit:

- Command cap 10000 TPS. **[verified]** https://minecraft.wiki/w/Commands/tick
- Useful limit is set by the slowest of server tick time, client tick plus frame time (`10 ticks per frame` rule) and the packet limiter. Paper's limiter defaults to 500 packets per second averaged over 7 s, then KICK. A client at 10x sends roughly 10x its movement and `client_tick_end` packets, so raise it for tests. **[verified]** defaults https://docs.papermc.io/paper/reference/global-configuration/; **[inferred]** the interaction.
- No published number for useful rate with real clients. Must be measured.

## B. Client frame capture

Replay Mod:

- Source: https://github.com/ReplayMod/ReplayMod, default branch `stable`, release 2.6.28 on 2026-10-18, GPL-3.0. A `versions/1.21.4` target exists, plus 1.21.5 to 1.21.11 and 26.1 to 26.3. **[verified]**
- Packet capture: netty level, `onPacket` saves each received packet; the recording player is synthesised as spoofed packets. **[verified]** https://github.com/ReplayMod/ReplayMod/blob/stable/src/main/java/com/replaymod/recording/handler/RecordingEventHandler.java
- Render: **offline fixed timestep.** `VideoRenderer` drives a `ReplayTimer`, sets `tickDelta` and tick length, calls `sendPacketsTill(replayTime)` and `mc.tick()` itself, frame count is `duration * fps`. **[verified]** https://github.com/ReplayMod/ReplayMod/blob/stable/src/main/java/com/replaymod/render/rendering/VideoRenderer.java
- Capture: `glReadPixels` as BGRA, synchronous or two swapped PBOs. **[verified]** https://github.com/ReplayMod/ReplayMod/blob/stable/src/main/java/com/replaymod/render/capturer/PboOpenGlFrameCapturer.java and https://github.com/ReplayMod/ReplayMod/blob/stable/src/main/java/com/replaymod/render/capturer/OpenGlFrameCapturer.java
- ffmpeg: spawned process, frames over stdin, `-y -f rawvideo -pix_fmt bgra -s WxH -r FPS -i - ...`, presets include `libx264 -preset ultrafast`. **[verified]** https://github.com/ReplayMod/ReplayMod/blob/stable/src/main/java/com/replaymod/render/FFmpegWriter.java and https://github.com/ReplayMod/ReplayMod/blob/stable/src/main/java/com/replaymod/render/RenderSettings.java#L87
- Limits: a replay reconstructs the view from packets plus synthetic self packets. It is not literally the frame the player saw if a client mod or local state differs. **[inferred]**
- GPL only binds on distribution. A test only tool not shipped to users is fine; do not link it into shipped code. **[inferred]** Needs a maintainer decision.

Flashback (modern alternative):

- Active, 1.21.4 to 1.21.10 builds, ffmpeg writer inside the JVM. **[verified]** https://modrinth.com/mod/flashback/version/latest and https://github.com/Moulberry/Flashback/blob/master/src/main/java/com/moulberry/flashback/exporting/AsyncFFmpegVideoWriter.java
- **License: "Do not redistribute. All rights reserved."** Read as design reference only. **[verified]** https://github.com/Moulberry/Flashback/blob/master/LICENSE.md

In process capture options:

- `Screenshot.takeScreenshot(RenderTarget)` binds the color texture and calls `glGetTexImage` synchronously via `NativeImage.downloadTexture`, then `flipY`. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Screenshot.java and https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/com/mojang/blaze3d/platform/NativeImage.java#L376
- The GUI is drawn into `mainRenderTarget` before the blit to the window, so reading it gives exactly what the player sees, without touching the window system. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L1217
- Fabric's client gametest does this, and re renders with a constant tick delta and a chosen framebuffer size per screenshot. **[verified]** https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/context/ClientGameTestContextImpl.java#L374
- PBOs help on real GPUs by avoiding the flush, and stall if mapped too early. **[reported]** https://community.khronos.org/t/using-pbo-and-fbo-for-pixel-readback/62353
- On llvmpipe the "GPU" is the CPU and the frame is in RAM, so a PBO saves little beyond the copy, and the wait for the rasterizer must happen anyway. No llvmpipe specific source found. **[inferred]**
- Copy cost: 854x480 BGRA is 1.64 MB per frame, well under 1 ms at memcpy speed. The real cost is the encoder competing for 4 cores. **[inferred]** arithmetic.

x11grab versus in process:

- x11grab samples on a wall clock at a given `-framerate`, with `-draw_mouse 0` available. **[verified]** https://ffmpeg.org/ffmpeg-devices.html
- It has no idea of game frames or ticks. Under time dilation, dropped ticks or a stalled frame it records wall clock video, frames cannot be labelled with ticks, and it needs an X server (nothing on Mac). **[inferred]**
- Its one strength: proof of the final composited window, independent of mods. **[inferred]**
- ffmpeg rawvideo over stdin is the same path Replay Mod uses. It carries no timestamps, frame rate is declared up front, so a constant virtual fps fits well and variable frame timing needs a separate sidecar. **[verified]** command above; **[inferred]** the timing point. The ffmpeg formats page failed to load, so the rawvideo demuxer docs were not re read.

macOS:

- ScreenCaptureKit and CoreGraphics capture sit behind the Screen Recording TCC permission, and without it capture is black or empty. **[reported]** https://developer.apple.com/forums/thread/760483 and https://docs.rs/crate/car-desktop/latest/source/src/macos/permissions.rs
- **Reading the game's own framebuffer in process does not use any capture API, so no permission should apply.** No Apple statement found. **[inferred]**, trivial to check on a Mac.
- GLFW throttles swaps of an occluded Cocoa window with `usleep` only when swap interval is above 0, so `enableVsync:false` avoids the 60 FPS cap on a hidden window. **[verified]** https://github.com/glfw/glfw/blob/master/src/nsgl_context.m

## C. Rendering cost

Real numbers:

- **No published Minecraft FPS on llvmpipe was found.** Must be measured on the runner. **[verified]** absence after several searches.
- MineRL docs: xvfb software rendering is 2 to 3x slower than GPU. **[reported]** https://minerl.readthedocs.io/en/latest/notes/performance-tips.html
- A forum user's 6 FPS on xvfb was traced mainly to their CPU training loop, not rendering; hello_world reached 70+. Not a clean number. **[reported]** https://discourse.aicrowd.com/t/env-step-slowly-with-xvfb-run/1623
- Closest same shape data: Fabric API's own client gametests on `ubuntu-24.04`, which is 4 vCPU 16 GB, on 26.3 with **Vulkan on Mesa llvmpipe (lavapipe) 25.2.8**. The suite with 17 joins ran in 2m49s on one client JVM, about 10 s per world cycle including server start and stop, with six "Can't keep up" warnings of 2 to 3 s. **[log]** https://github.com/FabricMC/fabric/actions/runs/41610335595 and runner spec https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- That job's "opengl" variant failed with `Couldn't find matching GLX visual` and silently fell back to Vulkan. So CI can claim OpenGL and not run it; assert the renderer string in the harness. **[log]** same run.

Mesa:

- llvmpipe advertises OpenGL 4.6. **[verified]** https://mesamatrix.net/
- 1.21.4 requests core profile 3.2, forward compatible, native context. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/com/mojang/blaze3d/platform/Window.java#L86
- So `MESA_GL_VERSION_OVERRIDE` is unnecessary on llvmpipe. **[inferred]**
- `LP_NUM_THREADS` sets render threads, 0 disables threading; `LIBGL_ALWAYS_SOFTWARE=true` forces software; `GALLIUM_DRIVER` picks llvmpipe. `MESA_SHADER_CACHE_DIR` sets the shader cache location. **[verified]** https://docs.mesa3d.org/envvars.html
- llvmpipe uses up to 32 threads; `LP_NATIVE_VECTOR_WIDTH` overrides vector width. **[verified]** https://docs.mesa3d.org/drivers/llvmpipe.html
- On a 4 core runner, server, client logic, chunk meshing, llvmpipe and encoder all compete. `LP_NUM_THREADS` is the budget lever. **[inferred]**

Sodium:

- Officially supports drivers with OpenGL 4.5, llvmpipe passes on version. Translation layers are unsupported; llvmpipe is not one. **[verified]** https://github.com/CaffeineMC/sodium
- No report of Sodium on llvmpipe found. Whether it helps is unmeasured. It changes the terrain pipeline, so goldens with and without it will differ, and it moves away from a stock player's render path. **[inferred]**

Settings. `options.txt` keys verified in **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Options.java

- Scene cost: `renderDistance:2` (range 2 to 32), `simulationDistance:5`, `graphicsMode:0`, `ao:false`, `particles:2`, `renderClouds:"false"`, `biomeBlendRadius:0`, `entityShadows:false`, `mipmapLevels:0`, `entityDistanceScaling:0.5`, `menuBackgroundBlurriness:0`.
- Pacing: `maxFps:260` (260 means no limiter, code checks `k < 260`), `enableVsync:false`, `inactivityFpsLimit:"minimized"`. Default `afk` drops to 30 FPS after 60 s without input and 10 after 10 min, which will silently slow any long CI run. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/com/mojang/blaze3d/platform/FramerateLimitTracker.java
- Fill rate scales with window pixels, so window size is the largest lever on llvmpipe. Default Fabric test size is 854x480. **[inferred]** fill rate; **[log]** size.
- Fabric's own test defaults: clouds off, tutorial none, view distance 5, onboarding off. **[verified]** https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/context/ClientGameTestContextImpl.java#L86

Skipping frames while ticking:

- **Vanilla has the switch: public field `Minecraft.noRender`.** When true `gameRenderer.render` is skipped, ticks still run, blit and swap still happen. Set from a mod, no mixin needed. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L1217
- So render on demand is feasible: `noRender = true` between checkpoints, render only for a frame capture or for video. Rendering stays real when it counts. **[inferred]**
- HeadlessMC patches LWJGL or uses hmc-optimizations to skip all rendering. That removes the rendering this project wants to see, so only useful as a comparison baseline. **[reported]** https://github.com/headlesshq/headlessmc
- Malmo has the same idea: `TimeHelper.displayGranularityMs` limits how often the window updates. **[verified]** https://github.com/microsoft/malmo/blob/master/Minecraft/src/main/java/com/microsoft/Malmo/Utils/TimeHelper.java
- `pauseOnLostFocus`: under Xvfb there is no window manager to focus the window. `GameRenderer.render` calls `pauseGame` after 500 ms of no focus, opening the pause screen even in multiplayer. **Set `pauseOnLostFocus:false`.** **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/GameRenderer.java#L429; CraftGround fixes this with a mixin, **[verified]** https://github.com/yhs0602/CraftGround/blob/main/minecraft/mc121/src/main/java/com/kyhsgeekcode/minecraftenv/mixin/ClientIsWindowFocusedMixin.java
- Minimised window: 10 FPS limit, blit skipped. **[verified]** tracker above and Minecraft.java#L1225.
- Headless without X: GLFW has a Null platform with EGL hooks, opt in by init hint. That would remove Xvfb and its image copy, if the LWJGL version and Mesa surfaceless EGL cooperate. Untested for 1.21.4. **[verified]** https://github.com/glfw/glfw/blob/master/docs/intro.md and https://github.com/glfw/glfw/blob/master/src/null_init.c; **[inferred]** feasibility.

Horizon warning:

- Vulkan became the default in snapshot 26.4; the fallback no longer happens automatically. **[reported]** https://www.playnews.gg/en/guides/minecraft-snapshot-26-4-vulkan-rendering-how-to-enable-it-and-check-it-with-f3
- Fabric's CI matrix tests `opengl` and `vulkan` already. **[verified]** https://github.com/FabricMC/fabric/blob/26.3/.github/workflows/build.yml
- Anything hooking raw GL (`glReadPixels`, PBOs, GL queries) is a short lived seam. Hook at `RenderTarget` level and game render classes instead. Replay Mod already has a separate `GpuBuffer` path for new versions. **[inferred]**

## D. Startup

Java versions:

- MC 1.21.4 minimum Java 21. **[verified]** https://minecraft.wiki/w/Java_Edition_1.21.4
- Paper 1.21.4 `Main` only refuses pre release JDKs (bypass `Paper.IgnoreJavaVersion`); there is no upper version cap in the check. Whether it actually runs on 26 is untested. **[verified]** https://github.com/PaperMC/Paper/blob/ver/1.21.4/paper-server/src/main/java/org/bukkit/craftbukkit/Main.java#L214

AOT:

- JEP 483 (JDK 24): 42% on Spring PetClinic, 4.486 s to 2.604 s, 130 MB cache. Needs same JDK, OS, architecture; classpath of JARs only; ZGC unsupported at that version. **[verified]** https://openjdk.org/jeps/483
- JEP 514 (JDK 25): one step `-XX:AOTCacheOutput`, needs about double heap during training. **[verified]** https://openjdk.org/jeps/514
- **JEP 483: classes from user defined class loaders are not cached, and classes that depend on them are not AOT linked.** **[verified]** same JEP.
- **Fabric loads Minecraft and mods through Knot, a custom class loader** (`knot//com.mojang...` in stack traces). So the classes that dominate client boot are excluded. AOT will not transform client boot on Fabric. **[log]** https://github.com/FabricMC/fabric/actions/runs/41610335595; **[inferred]** consequence. No report of a Fabric client with AOT found.
- Same reason limits plugin classes on Paper, which use `PluginClassLoader`. Server classes are fine. **[inferred]**
- AppCDS: `-XX:+AutoCreateSharedArchive -XX:SharedArchiveFile=x.jsa` since JDK 19, archive needs same JDK and unmodified JARs. **[verified]** https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html
- **PaperMC `tack`: official launcher managing AOT caches.** "In general, the AOT cache will cut the server startup time in half", 33% less JIT work. **Minimum Java 26**, because 24 and 25 "have issues with how they record". Any jar or JVM arg change re records. Has `--only-record` and `--require-aot` for CI. LGPL-3.0, 31 stars, active. Seconds not published. **[reported]** https://github.com/PaperMC/tack

Snapshots:

- CRaC needs apps to release sockets, files and timers through a `Resource` API, and a CRaC enabled JDK (OpenJDK CRaC builds, Zulu, Liberica, Ubuntu). **[verified]** https://crac.org/
- CRIU refuses apps with connections outside the dumped set unless told, and **"apps connected to a real X server can't be dumped"** because state lives in the server. Any opened device blocks dumps. **[verified]** https://criu.org/What_cannot_be_checkpointed
- No report of Paper or a Minecraft client restored by CRIU or CRaC found. **[verified]** absence.
- Paper snapshot: plausible but high effort (Netty epoll, region files, logs, Linux only). Client snapshot with GL context: only conceivable with Null platform plus software EGL. llvmpipe JITs shaders for the CPU it ran on and JVM picks intrinsics by CPU, while GitHub runners vary, so restore on another CPU can crash. No Mac. **Do not prototype now.** **[inferred]**

Reported times:

- Real client boot, CI: "Loading Minecraft" to backend created 11 to 13 s, atlases 19 s, first world server start 25 s, with Fabric testmods, 4 vCPU. **[log]** https://github.com/FabricMC/fabric/actions/runs/41610335595
- **Warm JVM restart is nearly free.** In the same JVM, dedicated server `Done (0.127s)`, `Done (0.141s)`, `Done (0.304s)`, spawn prep 125 to 1440 ms. Most boot cost is class load and JIT, not world work. **[log]** same run. In process server on Fabric, so a ratio hint, not a Paper number.
- Implication: one long lived client and one long lived server beat every boot trick. **[inferred]**

Paper boot settings:

- `-Dpaperclip.patchonly=true` patches and downloads without starting, so build it into the image once. **[verified]** https://docs.papermc.io/paper/reference/system-properties/
- `paper.disableOldApiSupport` skips Commodore rewriting; `paper.disableWorldSymlinkValidation` skips a folder walk; `paper.disableStartupVersionCheck`; `com.mojang.eula.agree=true`. **[verified]** same page.
- `spawnChunkRadius` game rule exists from 1.20.5 and is removed in 1.21.9, so it applies to 1.21.4 now and dies later. **[verified]** https://minecraft.wiki/w/Game_rule
- Paper `WorldCreator.keepSpawnLoaded(TriState)` is the runtime switch. **[verified]** https://jd.papermc.io/paper/1.21.4/org/bukkit/WorldCreator.html
- `paper-global.yml`: `chunk-system.io-threads`, `worker-threads`, `spark.enabled`; `server.properties`: `level-type=flat`, `generate-structures=false`, `online-mode=false`, `sync-chunk-writes=false`, `network-compression-threshold=-1`, `spawn-protection=0`, `view-distance=3`, `simulation-distance=3` (minimum 3), `pause-when-empty-seconds=0`. **[verified]** https://docs.papermc.io/paper/reference/global-configuration/ and https://minecraft.wiki/w/Server.properties
- Pregenerated world in the image avoids world gen and saves level.dat conversion. **[inferred]**

## E. Isolation on one server

Worlds:

- `createWorld` is synchronous on the main thread, ends in `console.initWorld`, and Paper has a commented out guard against creating while ticking. **[verified]** https://github.com/PaperMC/Paper/blob/ver/1.21.4/paper-server/src/main/java/org/bukkit/craftbukkit/CraftServer.java#L1288
- Cost per world, reported: 1593 ms with WorldGuard on a real server; about 30 ms average for **loading** per a plugin author. **[reported]** https://github.com/TheNextLvl-net/worlds/issues/3
- Fabric logs show 125 to 140 ms spawn prep for a flat world. **[log]**
- World creation blocks all other tests on the single main thread, so it is a stop the world per test. **[inferred]**
- Each world also spawns a thread, per a fork maintainer. **[reported]** https://github.com/sparklypower/sparklypaper/issues/25
- Unload can hang on save for about a minute on some setups. **[reported]** https://www.github.com/PaperMC/Paper/issues/8300
- Hundreds of worlds per run is not obviously viable; a pool reused and wiped is likely better. Must measure. **[inferred]**

Regions in one world:

- Fast and cheap, but shares time, weather, world border and all global server state. Bleed risk for anything world scoped. **[inferred]**
- Per player hiding exists: `Player.hidePlayer`, `hideEntity`, `canSee`, and `sendBlockChange` for per player blocks. **[verified]** https://jd.papermc.io/paper/1.21.4/org/bukkit/entity/Player.html
- `hideEntity` affects tracking, not server logic: collisions and AI still interact. **[inferred]**
- Tick rate and freeze are server wide, so a parallel run on one server cannot have per test server time. **[verified]** A above. This is the strongest argument against sharing a server while using dilation. **[inferred]**

Moving a client:

- Same server, new world: `handleRespawn` creates a new `ClientLevel`, shows `ReceivingLevelScreen` until the player chunk arrives. No fixed minimum seen, 30 s timeout. Tick state resent. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/multiplayer/ClientPacketListener.java#L1178 and https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/gui/screens/ReceivingLevelScreen.java
- Full reconnect: "Connecting" to "logged in" took 0.7 s and 1.3 s, same client JVM, 4 vCPU, local dedicated server. **[log]** https://github.com/FabricMC/fabric/actions/runs/41610335595
- Configuration re entry: `start_configuration` puts the client back into configuration without a socket reconnect. **[verified]** https://minecraft.wiki/w/Java_Edition_protocol/Packets
- Paper's API `PlayerGameConnection.reenterConfiguration` exists on the current branch, and the file does not exist on `ver/1.21.4`, so 1.21.4 would need NMS or a packet. **[verified]** https://github.com/PaperMC/Paper/blob/main/paper-api/src/main/java/io/papermc/paper/connection/PlayerGameConnection.java
- Transfer packet (1.20.5) needs `accepts-transfers=true` and does a full new login, so no time gain over reconnect, and client state resets the same. Its use here is switching to another server process. **[verified]** https://minecraft.wiki/w/Server.properties; **[inferred]** cost.
- A clean client session between tests needs resets for: chat history, boss bars, toasts, tab list, sidebar. Reconnect gives this for free at about 1 s. Respawn does not reset all of them. **[inferred]**

## F. Determinism for goldens

Precedents to copy:

- **Fabric client gametest API already exists for 1.21.4 and owns most of this.** Tick phases with semaphores (client and server tick in step, tasks in sequence, test code while both wait), network synchronizer, `waitForChunksRender`, flat world defaults (`doDaylightCycle`, `doWeatherCycle`, `doMobSpawning` off), `takeScreenshot`, `assertScreenshotEquals`, `assertScreenshotContains`. **[verified]** https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/threading/ThreadingImpl.java and https://docs.fabricmc.net/develop/automatic-testing
- Its lockstep assumes the server is in the same JVM (`MinecraftServerMixin`, `ServerMainMixin`). A real Paper server in another JVM cannot join it, so the harness needs its own barrier across the network. **[inferred]**
- Default compare: Mean Squared Difference at 0.005, or exact, on RGB or grayscale, with subimage search. **[verified]** https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/screenshot/TestScreenshotComparisonAlgorithm.java
- Malmo and CraftGround control the clock too: `TimeHelper.serverTickLength` plus an overclocking coremod, and `MinecraftServer_tickspeedMixin`. **[verified]** https://github.com/microsoft/malmo/blob/master/Minecraft/src/main/java/com/microsoft/Malmo/Utils/TimeHelper.java and https://github.com/yhs0602/CraftGround/blob/main/minecraft/mc121/src/main/java/com/kyhsgeekcode/minecraftenv/mixin/MinecraftServer_tickspeedMixin.java

**Single seam for wall clock: `Util.timeSource` is a public static mutable field.** `getMillis` and `getNanos` read it. One assignment makes glint, cursor blink, toasts and heart blink follow a virtual clock, and the frame timer too if it is fed from it. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/Util.java#L102

Noise sources:

| Source | Mechanism | Control | Label |
|---|---|---|---|
| Block light flicker | `LightTexture.tick` uses `Math.random`, ungated by freeze, feeds lightmap | mixin to zero, or no block light in golden scenes | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/LightTexture.java#L50) |
| Enchant glint | `Util.getMillis() * glintSpeed` | `glintSpeed:0` or virtual clock | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/RenderStateShard.java#L340) |
| Clouds | `ticks + partial`, stops on freeze | `renderClouds:"false"` | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/LevelRenderer.java#L490) |
| Sky and day cycle | server time packet, client `tickTime` | rule off and fixed `/time set` | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/multiplayer/ClientLevel.java#L227) |
| Ambient particles | `animateTick` with `Level.random`, unseeded `RandomSource.create()` | `particles:2`, seed `Level.random` for tests | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/world/level/Level.java#L107) |
| Block textures per position | `state.getSeed(pos)` seeds the model pick, so stable per position | none needed, keep positions fixed | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/block/BlockRenderDispatcher.java#L51) |
| Chunk pop in | async section compile | Fabric `waitForChunksRender` equivalent | verified [src](https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/context/TestClientWorldContext.java) |
| Animated textures, water | `textureManager.tick`, stops on freeze | freeze, or fixed tick | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Minecraft.java#L1674) |
| Entity idle animation | client ticks, age, `Player` never freezes | capture at fixed client tick, mask, or use semantics | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/world/TickRateManager.java) |
| Hearts and HUD jiggle | seeded by `tickCount * 312871` | fixed tick count, or full health | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/gui/Gui.java#L787) |
| View bob, FOV, tilt | camera | `bobView:false`, `fovEffectScale:0`, `damageTiltStrength:0`, `screenEffectScale:0` | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Options.java) |
| Mipmaps | filter choice varies by driver | `mipmapLevels:0` | inferred |
| GUI scale | layout | fixed `guiScale` and window size | inferred |
| Font | vanilla default is bitmap glyph quads; `§k` picks a random glyph | keep `forceUnicodeFont:false`, avoid `§k` | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/gui/Font.java#L372) |
| MSAA | no option exists in vanilla | none | verified [src](https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/Options.java) |
| Tutorial, toasts, onboarding | overlays | `tutorialStep:none`, Fabric's defaults | verified [src](https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/context/ClientGameTestContextImpl.java#L86) |

Cross platform:

- Goldens across llvmpipe and Apple GPU will differ. Treat each renderer as its own baseline, or make Linux llvmpipe the only golden owner and Mac video plus semantics only. **[inferred]** Playwright: "run tests in the same environment where the baseline screenshots were generated". **[verified]** https://playwright.dev/docs/test-snapshots
- Playwright recommends a Docker image for consistent screenshots and `workers: 1` on CI "to prioritize stability and reproducibility". **[verified]** https://playwright.dev/docs/ci
- Pin Mesa and LLVM exactly. Runners mix CPUs, so fix `LP_NATIVE_VECTOR_WIDTH` too. **[inferred]** from https://docs.mesa3d.org/drivers/llvmpipe.html. Mesa's own trace checksum file could not be read (bot protection).
- Minecraft GUI is bitmap fonts and nearest filtered quads, so GUI goldens might match across renderers far better than browser text. Worth a test. **[inferred]**
- Flutter: default font is Ahem (squares), custom fonts differ across OS and Flutter versions. **[verified]** https://api.flutter.dev/flutter/flutter_test/GoldenFileComparator-class.html
- Alchemist keeps two golden kinds: platform readable (not committed) and CI with blocks (committed), threshold default 0.0. **[reported]** https://pub.dev/packages/alchemist
- Chromium Skia Gold: default exact match, **several approved baselines per test**, GPU specific where needed, inexact opt in per test via `matching_algorithm`, fuzzy and Sobel (edge ignoring) with `MaxDifferentPixels`, `PixelDeltaThreshold`. **[reported]** https://chromium.googlesource.com/chromium/src/+show/a8a80098708d058ba05d76dcde910fd8615eb264/docs/gpu/gpu_pixel_testing_with_gold.md and https://pkg.go.dev/go.skia.org/infra/gold-client/go/imgmatching/sobel
- Lesson: exact hash first (cheap and strict), small set of approved digests, fuzzy per test by exception. Golden count stays small; screenshots are costly to triage. **[inferred]**

Diff tools:

| Tool | Use from | License | Notes | Label |
|---|---|---|---|---|
| pixelmatch | JS | ISC | perceptual delta, AA detection, new `windowSize` (compact regressions versus scattered dither noise) and `ignoreMask`; basis of Playwright | verified [repo](https://github.com/mapbox/pixelmatch) |
| dify | Rust | MIT | pixelmatch port, updated 2026 | verified [repo](https://github.com/jihchi/dify) |
| odiff | CLI, server mode | MIT | Zig SIMD, AA ignore, milliseconds, long lived server | verified [repo](https://github.com/dmtrKovalenko/odiff) |
| dssim | Rust CLI | **AGPL-3.0** | multi scale SSIM in Lab; avoid linking | verified [repo](https://github.com/kornelski/dssim) |
| image-compare | Rust | MIT | SSIM, RMS, hybrid | verified [repo](https://github.com/ChrisRega/image-compare) |
| ssimulacra2 | Rust | BSD-2 | perceptual metric | verified [repo](https://github.com/rust-av/ssimulacra2) |
| butteraugli | C++ via libjxl | Apache-2.0 | original repo stale since 2022 | verified [tool](https://github.com/libjxl/libjxl/blob/main/tools/butteraugli_main.cc) |
| VMAF | ffmpeg, C | BSD-style | needs frame aligned reference video, trained for compression quality, poor pass or fail fit | inferred [repo](https://github.com/Netflix/vmaf) |
| Fabric MSD | JVM, in client | Apache-2.0 | already there, grayscale and subimage search | verified above |

No maintained JVM pixelmatch library stood out. A pixelmatch style compare is small enough to own in Kotlin or Rust. **[inferred]**

## G. Render semantic observation

Precedents:

- **HeadlessMC `hmc-specifics`: `render` "Dumps all strings rendered by Minecraft's FontRenderer"; `gui` "Lists all currently displayed gui elements"; `click`, `text`.** Direct precedent for draw call text capture, in real client CI. **[verified]** https://github.com/headlesshq/hmc-specifics
- `mc-runtime-test` wraps the client with Xvfb for CI and runs game tests. **[verified]** https://github.com/headlesshq/mc-runtime-test
- **Malmo `ColourMapProducer`: a full separate render pass that gives each entity and block type a flat colour, hooking the render manager to know the current entity.** The precedent for segmentation. **[verified]** https://github.com/microsoft/malmo/blob/master/Minecraft/src/main/java/com/microsoft/Malmo/Utils/TextureHelper.java and https://github.com/microsoft/malmo/blob/master/Minecraft/src/main/java/com/microsoft/Malmo/MissionHandlers/ColourMapProducerImplementation.java
- CraftGround (MC 1.21, 26.2, LGPL readme, GPL per GitHub metadata, so check): `FramebufferCapturer`, `GameRendererDepthCaptureMixin`, depth capture and zero copy to GPU memory. **[verified]** https://github.com/yhs0602/CraftGround and https://github.com/yhs0602/CraftGround/blob/main/minecraft/mc121/src/main/java/com/kyhsgeekcode/minecraftenv/mixin/GameRendererDepthCaptureMixin.java
- Replay Mod's Blender export hooks chunks, entities, particles and items by render: a tested list of render seams to read. **[verified]** https://github.com/ReplayMod/ReplayMod/tree/stable/src/main/java/com/replaymod/render/blend/exporters
- Fabric `clickScreenButton` by translation key uses GUI semantics, not pixels. **[verified]** https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/util/ClientGameTestImpl.java
- No project found doing an entity visibility list in a test suite. RL projects read state, not draw calls. **[verified]** absence within this search.

Hook points in 1.21.4:

- Text: `GuiGraphics.drawString` (Yarn `DrawContext.drawText`) has many overloads, all reach `Font.drawInBatch`. Hook `Font`. World text (signs, name tags, text displays) goes through `Font` too, so capturing that needs context to separate HUD from world. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/gui/GuiGraphics.java#L227 and https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/gui/Font.java#L68; **[inferred]** the split.
- Entities: `EntityRenderDispatcher.render` is one seam, `shouldRender(entity, frustum, ...)` is frustum only. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/entity/EntityRenderDispatcher.java#L146 and https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/LevelRenderer.java#L754
- **"Drawn" does not mean "visible".** A mob behind a wall in a rendered chunk is still dispatched. Visibility needs depth, an ID pass or a raycast. **[inferred]** from frustum only check.
- Vanilla ID pass base: `entityOutlineTarget` is a separate colour target for glowing outlines, per entity flat colour. A cheap base for an entity ID buffer without Malmo's full second pass. Outline uses depth rules of its own, so check occlusion behaviour. **[verified]** https://github.com/KernelDotDLL/mcp-1.21.4/blob/origin/src/main/java/net/minecraft/client/renderer/LevelRenderer.java#L125; **[inferred]** ID use.
- `Fabric` tick locked `waitForChunksRender` is a semantic readiness signal, far better than sleeping. **[verified]** F above.

RL numbers. All on a real GPU, none on llvmpipe:

| Setup | Resolution | FPS | Hardware | Label |
|---|---|---|---|---|
| Malmo (MineRL) render | 64x64 | 57.7 | Threadripper 3960X, RTX 3090 Ti, VirtualGL | reported |
| CraftGround render | 64x64 | 160.7 to 279.8 | same | reported |
| Malmo render | 640x360 | 55.9 to 57.2 | same | reported |
| CraftGround render | 640x360 | 110 to 141 | same | reported |
| CraftGround render | 640x360 | 111.5 to 134.5 | Apple M1 Pro | reported |

- Source: https://github.com/yhs0602/minecraft-simulator-benchmark. The README lists memory as a metric but has no memory table.
- Malmo's 57 FPS at any resolution looks like a logic or sync limit, not a fill rate one: 64x64 and 640x360 match. **[inferred]**
- Memory: MineRL launch uses `-Xmx2G` in `launchClient.sh`, 4 G in docs example. **[verified]** https://github.com/minerllabs/minerl/blob/dev/minerl/Malmo/Minecraft/launchClient.sh
- **Craftium is not Minecraft.** It runs on Luanti (formerly Minetest), C++, and explicitly rejects Java. Claimed 2747 steps per second versus 72 for MineDojo. Not comparable for this project. **[reported]** https://github.com/mikelma/craftium and https://www.alphaxiv.org/overview/2407.03969
- Baritone is a pathing mod with no render observation role; nothing relevant. **[inferred]**

## Open numbers a spike must measure

None of these has a usable public number; all need the real runner.

- FPS of 1.21.4 on llvmpipe at 854x480 and 427x240, per `LP_NUM_THREADS`, void world.
- Client ticks per second with `noRender = true`, and the highest stable TPS with the clock mixin.
- Paper cold boot, with `tack` on Java 26 (does 1.21.4 even run there), against a warm reuse.
- `createWorld` ms on Paper with a void generator, and reconnect against respawn to level ready.
- Frame to frame identity on llvmpipe with all controls on, across runs and across runner CPUs.
- Encode cost share at 854x480 20 FPS on 4 cores (`libx264 ultrafast`, or frames kept in a ring buffer and encoded only on failure).
