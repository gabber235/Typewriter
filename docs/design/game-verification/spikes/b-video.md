# B: video of what the client player saw

## Answer

- **Use B1: in-client readback of `mainRenderTarget` through the engine's GPU API, piped as raw RGBA
  into an ffmpeg process, with one sidecar line per video frame naming the fact frame and client
  tick.** Render thread cost per captured frame: 0.35 ms on the Mac, 0.17 to 0.24 ms on the runner with
  Vulkan, but **2.3 to 7.1 ms with OpenGL on llvmpipe**. No FPS loss visible at 30 fps. x264 `veryfast`
  takes 9 percent of a core on the Mac, 18 to 19 on the runner. It needs no window, no screen
  permission, and works unchanged on OpenGL and Vulkan.
- **Video is a "demo run" of the same requirement after the gated one, and it reaches the same
  verdict**: 728 of 728 requirements (328 on the Mac, 400 on the runner, both backends, void and
  terrain, real time and fixed step), 0 wrong verdicts.
- **On CI, record in fixed step (B4) at server rate 10, on Vulkan.** Terrain renders at 22 to 25 FPS, so
  real time 30 fps video repeats 20 to 25 percent of its frames and stutters; step at rate 10 gives the
  same motion as an uncapped Mac (7.5 px per frame, no still frame) at twice the wall time.
- **A clip lines up with the facts to the frame.** At 30 fps the first video frame with the effect
  in pixels is the frame the facts name: title and chat 0 frames off in 50 of 50, block 0 or 1, display
  entity 1. Recording every rendered frame: title, chat, entity 0 frames, block 2 frames (meshing).
- **A failure points at a frame**: the barrier frame of a failing requirement maps to one video frame
  through the sidecar; that frame shows the screen without the effect.
- **Previews fit**: a requirement clip is 18 KB mp4 and 27 to 33 KB webp; 100 requirements (85 s) as
  one webp preview is 2.9 MB at quality 35.
- **B4 fixed step works and is needed for a slow renderer.** With the client clock driven per frame
  and the server at a lower tick rate, a 20 FPS renderer gives 30 fps video whose motion equals the
  uncapped reference (28 frames, 0 still frames, 7.5 px per frame). Real time at 20 FPS instead
  repeats a third of all frames and shows 9 still frames in the same 28 frame move. The rule:
  **server rate at most 20 x renderer FPS / output fps**, or the client falls behind (rate 20 at 20
  FPS: 2.1 s behind after 6 s, a 36 px jump).
- **B2 window capture works on Linux only and cannot sync**: same CPU as B1 (17 percent), same picture,
  but facts map through wall clock, and on the runner that was off by up to 16 frames, with 25 frames
  dropped by ffmpeg. On the Mac it would need the Screen Recording permission (not tried).
- **B3 offline render from packets is not worth building**: Replay Mod (GPL 3, has 26.3 builds) and
  Flashback (all rights reserved, "Do not redistribute") both render with exactly B1 plus B4, need a
  window, and are started by a person in a GUI. Research only.

Machine for Mac numbers: M1 Max, 10 cores, JBR 25.0.3, OpenGL 4.1 on Metal, true 854x480 framebuffer
(`--window-clear 0x2000`), render distance 2 in void, 5 in the default world with seed 20261105,
ffmpeg from the system profile (libx264, VideoToolbox). Load is the 1 minute average; it was 7 to 25
during this spike because other work ran. Measured unless marked **inferred**.

## B1 as built

`probe-mod/src/main/java/probe/mod/video/Video.java`, about 300 lines.

- **Seam**: right after `GameRenderer.render()` inside `Minecraft.renderFrame` (the existing
  `RenderGateMixin` redirect), so the frame holds world and GUI and nothing of the swapchain.
- **Readback**: `CommandEncoder.copyTextureToBuffer(mainRenderTarget color, buffer, callback)` into a
  ring of 4 persistent `GpuBuffer`s (`USAGE_MAP_READ | USAGE_COPY_DST`). The callback runs in
  `RenderSystem.executePendingTasks` a frame or two later, maps the buffer and copies 1.6 MB into a
  pooled `byte[]`. This is the pattern of the engine's own `TracyFrameCapture`, and what Replay Mod and
  Flashback do on 26.x. Backend neutral by construction: no GL call anywhere.
- **Encode**: a writer thread writes to ffmpeg's stdin:
  `ffmpeg -f rawvideo -pix_fmt rgba -s 854x480 -framerate 30 -i pipe:0 -vf vflip -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p out.mp4`.
  Rows arrive bottom up, so `vflip`; bytes are RGBA in memory.
- **Slots**: real time mode gives every frame a slot `round((t - t0) * fps)`; a frame whose slot is taken
  is not read back at all, a missed slot repeats the previous frame (marked `dup`), so the file keeps
  real time. Every frame mode captures each rendered frame. Step mode is every frame plus B4.
- **Sidecar** `out.mp4.frames.jsonl`: `v` video frame, `f` fact frame (the `frame` in facts and
  `observe` replies), `t` client tick, `at` epoch micros, `ping` last barrier, `virtMs` client clock.
- **Live commands**: `rec?path=&fps=&mode=rt|all|step&enc=x264|vt|null|raw&preset=&crf=&scale=&speed=`,
  `recStop` (stats), `mark` (current video slot, frame, tick, time).
- One change to facts: a tick's snapshot now names the next frame (`Speed.publish(frames + 1, ...)` in
  `Probe.onTick`), because that is the first frame that draws the tick's state. Without it every tick
  sighting would map one frame early.

## Cost (Mac)

Client uncapped, standing still, 8 s windows. FPS and client CPU swing with load, so look at the
spread of the `none` rows before reading a difference. Client CPU excludes ffmpeg.

| Config | Void FPS | Default rd 5 FPS | Client CPU % | ffmpeg CPU % | Render thread ms per capture | kB/s, still scene |
|---|---|---|---|---|---|---|
| none | 368 to 451 (5) | 243 to 286 (4) | 50 to 72 | | | |
| readback 30/s, no encode | 421 | | 61 | | 0.40 | |
| readback every frame, no encode | 354 | 244, 276 | 68 to 84 | | 0.34 to 0.38 | |
| **x264 veryfast, 30 fps** | 432 | 283, 307 | 53 to 77 | **9** | **0.35 to 0.36** | 3.2 void, 8.0 terrain |
| x264 ultrafast, 30 fps | 414 | 283, 309 | 55 to 77 | 7 to 8 | 0.32 to 0.38 | 6.8, 37 |
| x264 veryfast, 60 fps | 406 | 278, 297 | 53 to 72 | 17 to 18 | 0.34 to 0.39 | 5.8, 12.7 |
| x264, scaled to 426 wide by ffmpeg | 400, 406 | | 53, 68 | 5 | 0.38, 0.40 | 1.5 |
| VideoToolbox h264, 2 Mbit/s | 391, 416 | 278, 297 | 49 to 68 | 6 | 0.37 | 150, 290 (bitrate bound) |
| x264 veryfast, every frame | 336, 340 | 225, 253 | 66 to 74 | 63 to 93 | 0.35 to 0.39 | 39 to 73 |

- **Render thread cost is 0.35 ms per captured frame** (0.21 to 0.25 ms to issue the copy, 0.13 to 0.25
  ms in the callback for map and memcpy), stable across load, world and encoder. Measured with
  `System.nanoTime` around the mod's own code; GPU time of the copy is not in it.
- **At 30 fps there is no FPS loss above noise**; capturing every frame costs about 10 to 20 percent
  FPS and, with x264, 0.6 to 0.9 of a core. Every frame recording dropped 2 to 14 frames per 8 s when
  the 12 buffer pool ran out (marked as `dup`).
- Pipe bandwidth: 49 MB/s at 30 fps of 854x480 RGBA. Every frame at 350 FPS would be 570 MB/s.
- x264 `veryfast` crf 23 beats `ultrafast` on size (4 to 5 times smaller in terrain) for 1 percent
  more CPU. VideoToolbox saves 3 points of CPU and is bitrate bound; not worth a Mac only path.
- File size per second depends on motion. Still scenes above. The 100 requirement demo run (titles,
  chat, blocks, text, cleanup): **7.5 kB/s**, 639 KB for 85 s. The step clips with a moving text:
  9 kB/s at crf 20.
- Quality: frames extracted at full size from the x264 veryfast and ultrafast terrain videos, plus
  title and fact frames from the replay runs, were looked at: text sharp, terrain textures intact,
  ultrafast slightly softer on stone. Colours and orientation correct.

## B3': does the recorded demo run reach the gated verdict?

Requirement as in C (R4 tick at 20 TPS, cycle title, chat, per player block, packet only text
display; every 20th broken, barrier fail). Each run does the list gated (gate 2) first, then the same
list rendered and recorded, with a 0.15 s settle before and a 0.6 s linger after each requirement so
the clip is watchable.

| Run | n | Verdicts equal | Wrong gated, demo | Dirty | Pixels agree with verdict | Requirement s, gated, demo | Demo wall s | Video |
|---|---|---|---|---|---|---|---|---|
| Real time 30 fps | 100 | **100/100** | 0, 0 | 0, 0 | 100/100 | 0.050, 0.045 | 85 | 2551 frames, 639 KB |
| Every frame | 40 | **40/40** | 0, 0 | 0, 0 | 40/40 | 0.050, 0.046 | 22 | 7255 frames, 1.0 MB |
| Step, 30 fps, server rate 10, renderer capped at 20 | 40 | **40/40** | 0, 0 | 0, 0 | 40/40 | 0.100, 0.046 | 40 | 601 frames, 224 KB |
| Earlier runs without the settle | 148 | 148/148 | 0, 0 | 0, 0 | 8/8, 95/100, 38/40 | | | |

"Pixels agree": the clip has a frame that differs from the frame before the requirement (more than 60
pixels at half size over 40 of 255) exactly when the verdict is pass. Load 10 to 25.

- **Verdicts reproduce in every mode tried.** The verdict comes from the same facts and barrier; the
  renderer only changes when packets are handled (once per frame).
- Load 25 at the end of the 100 run made no difference.
- **Inferred**: requirements with timing windows near a frame time could differ between gated (packets
  handled every 2 ms) and a demo at 20 to 30 FPS (every 33 to 50 ms). Not seen here; C's barrier trap
  applies equally to both.

### Sync with facts

Off = first video frame whose pixels show the effect, minus the video frame the sidecar names for the
fact frame. Counts per kind, runs with the settle.

| Kind | Real time 30 fps (25 each) | Every frame (10 each) | Step rate 10 (10 each) |
|---|---|---|---|
| Title | 0 in 25 | 0 in 10 | 0 in 10 |
| Chat | 0 in 25 | 0 in 10 | 0 in 10 |
| Per player block | 0 in 15, 1 in 10 | **2 in 10** | **2 in 10** |
| Packet only text display | **1 in 20** | 0 in 8 | 0 in 8 |

- Title and chat: frame exact. Looked at by eye: fact frame shows the title, the frame before does not.
- **Block: 2 rendered frames late**, every time. The client holds the block, the section is meshed over
  the next frames. Same cause as A's scene 12, now measured.
- **Display entity: client state is up to one tick ahead of pixels.** `Display.tick()` builds the render
  state (`Display.java:171`), so a new display entity is not drawn until the next client tick.
  At 30 fps that is one video frame in 20 of 20. Why every frame mode shows 0 is not separated
  (**inferred**: there the sighting comes from a tick snapshot more often).
- **Failure frame**: for every failing requirement, the barrier frame maps to one video frame;
  `fail-frame.png` of requirement 19 (broken entity) shows the empty scene, looked at by eye.

### A leftover only pixels see

Without the 0.15 s settle, the first 1 or 2 frames of a requirement following a block requirement still
show the previous fake block, after the cleanup barrier and the client state both said clean. Seen by
eye (lapis block in frames 1238 and 1239, gone in 1240). It made the pixel check disagree with the
verdict in 7 of 148 and moved sync offsets by up to minus 18 frames. **A clip, or a golden, that starts
right after a cleanup barrier shows the previous requirement.** Demo mode needs a render barrier
(a frame drawn after the clean state, sections meshed), not a fact barrier. The settle is a patch for
the spike; the cause is that "clean" is decided on client state.

## B4: fixed step

`Video` step mode, about 40 lines:

- `Util.setTimeSource(() -> virtNanos)` at start; `virtNanos += 1e9 / fps` at the head of every
  `Minecraft.runTick` (mixin). Restored at stop as `System.nanoTime() + offset`, so time never goes back.
- The client tick target is fixed at 50 ms of virtual time (`TickCapMixin`), so 20 client ticks per
  video second whatever the server rate.
- Real time pacing: each frame waits until `start + n / fps / speed`, `speed = server rate / 20`.
  Behind schedule it counts lag frames.
- Every frame is read back and the render thread waits for a free buffer instead of dropping.

Title 10/40/10 then a text display interpolating 6 blocks over 20 ticks, recorded at 30 fps. "Capped"
uses the client's frame limit to stand in for a slow software renderer. Motion is the x centroid of
the text per video frame, from first to last movement. Load 14 to 19.

| Case | Renderer FPS | Video frames | Repeated frames | Move frames, expected 30 | Still frames inside the move | px per frame | Client ticks, server ticks | Lag |
|---|---|---|---|---|---|---|---|---|
| Real time, uncapped (reference) | about 400 | 191 | 0 | 28 | **0** | 7.5 | 126, 128 | |
| Real time, capped 20 | 20 | 190 | **63** | 28 | **9** | 11.5 | 126, 128 | |
| **Step, server rate 10, capped 20** | 20 | 189 | 0 | 28 | **0** | 7.5 | 126, 127 | 0 |
| Step, server rate 20, capped 20 | 20 | 127 | 0 | 28 | 1, one 36 px jump | 7.5 | **84, 128** | 2.1 s |

- **Step at a safe rate is indistinguishable from the uncapped reference** in this measure, and takes
  twice the wall time (12.6 s against 6.3 s).
- **Too high a rate breaks it quietly**: the client handles every packet on arrival but ticks on the
  virtual clock, so it falls behind (84 against 128 ticks) and game time in the video is compressed
  (title 67 frames against 84). A stepped recording must assert lag 0 and equal tick counts.
- Title frames counted by pixels were 84 of 90 expected in both good cases; the fade frames under the
  threshold make up the difference.
- Server rate is server wide (C), so a stepped demo run needs its own server or a quiet one.
  Server side wall clock behaviour (legacy cinematics, C2) would run at real speed while the world is
  slowed: a stepped video would show it wrong. Same open question as C.
- Precedent, research: Replay Mod drives `getVideoTime() = framesDone * 1000 / fps` through its own
  timer; Flashback sets `deltaTracker` fields per frame; Minema (2016 to 2022) used a `FixedTimer` plus
  a tick synchronizer for the integrated server. All three pipe or encode frames read back through
  PBOs. None is driven without a person.

## B2: window capture

- **Mac**: ffmpeg's `avfoundation` screen input needs the Screen Recording permission for the
  terminal or the JVM. Not tried, on purpose. It would also capture whatever covers the window and
  the Retina framebuffer. **Inferred**: not usable unattended.
- **Linux**: see CI.

## B3: packet capture and offline render (research, not built)

| | Replay Mod | Flashback |
|---|---|---|
| License | GPL 3 or later | "Copyright 2024 Moulberry / Do not redistribute. / All rights reserved." |
| 26.3 | 2.6.28 (2026-10-18) | 0.43.6 (2026-09) |
| Records | Client side, every packet from join; works on any server | Client side packets plus an initial snapshot, can start mid session |
| Renders | Real window (polls `glfwWindowShouldClose`), PBO readback via `copyTextureToBuffer` on 26.x, raw BGRA piped to an ffmpeg process, fixed timestep | `copyTextureToBuffer` readback, JavaCV with bundled ffmpeg in process, fixed timestep |
| Automation | Started in the GUI; maintainers say a client is needed (issue 982) | GUI only (ImGui); no command or API found |

Sources: github.com/ReplayMod/ReplayMod (`FFmpegWriter.java`, `PboOpenGlFrameCapturer.java`,
`VideoRenderer.java`, issue 982), github.com/Moulberry/Flashback (`LICENSE.md`, `ExportJob.java`,
`SaveableFramebuffer.java`), Modrinth version APIs, github.com/daipenger/minema. Collected by a
research agent; the license wording and the readback calls were taken from source.

- **Inferred**: a replay holds what the client received, so per player fake blocks and packet only
  entities replay as that client saw them; mod side overlays and anything before recording do not.
- **Why not**: rendering a replay is B1 plus B4 run again later, in a second client, with a GUI to
  automate and a license to respect. Rendering on demand only the failed requirement is the one gain,
  and B3' gives it without a replay format: rerun the requirement in demo mode (verdicts reproduced in
  every run above).
- Other precedent: one public template records Fabric client game tests to MP4 with Xvfb and x11grab
  plus PulseAudio, with tick and frame metadata (github.com/brainage04/MinecraftModConventions). Wall
  clock, no fixed step.

## CI

Run [42111131229](https://github.com/gabber235/Typewriter/actions/runs/42111131229), two jobs, both on
EPYC 7763, 4 vCPU, llvmpipe (LLVM 20.1.2, 256 bits), Mesa 25.2.8, one job OpenGL and one Vulkan. Load 2.6
to 5.6. 0 failed steps, 0 leaked processes, 17 minutes per job. Artifacts `h-video-*` (14 days):
`b-video.jsonl`, all videos, clips, previews and frames.

### Cost

8 s windows, uncapped, standing still. FPS of the `none` rows is the noise.

| Config | Void FPS, GL / VK | Terrain rd 5 FPS, GL / VK | Render thread ms per capture, GL / VK | ffmpeg CPU % | Repeated frames per 8 s in terrain |
|---|---|---|---|---|---|
| none | 142, 159 / 162, 174 | 24.9, 25.1 / 22.4, 23.0 | | | |
| readback every frame, no encode | 139 / 156 | 24.9 / 22.7 | **2.6, 7.1 / 0.17, 0.24** | | 0 |
| readback 30/s, no encode | 147 / 156 | 24.9 / 22.6 | 2.9, 7.1 / 0.20, 0.22 | | 49 / 58 |
| **x264 veryfast, 30 fps** | 138 / 150 | 24.6 / 22.6 | 2.8, 3.2 / 0.19, 0.22 | **18 to 19** | 45 / 59 |
| x264 ultrafast, 30 fps | 141 / 153 | 24.6 / 22.7 | 2.3, 3.4 / 0.19, 0.21 | 15 to 16 | 44 / 57 |
| x264, 426 wide | 142 / 161 | 25.0 / 22.8 | 3.5 / 0.18, 0.19 | 11 to 12 | 40 / 57 |
| x264 veryfast, every frame | **108 / 124** | 25.3 / 22.0 | 2.3, 3.9 / 0.17, 0.21 | 14 to 73 | 0 |
| **B2 x11grab 30 fps, x264 veryfast** | | 24.4 / 22.0 | 0 | **17** | ffmpeg: 0 / 25 dropped in the replay run |

- **OpenGL readback on llvmpipe costs 10 to 30 times more render thread time than Vulkan** (2.3 to 7.1 ms
  against 0.17 to 0.24 ms per capture). **Inferred**: the GL path maps synchronously in Mesa's software
  driver. At 30 captures per second that is up to 21 percent of the frame budget. Vulkan matches the Mac.
- Encoding costs about a fifth of a core (twice the Mac), x11grab the same. The client itself uses 2 to 3
  vCPU when rendering uncapped, so on 4 vCPU recording every frame loses 25 to 30 percent FPS in void.
- **Terrain renders 22 to 25 FPS, so a real time 30 fps file repeats 20 to 25 percent of its frames.**
- kB per second, still scene: 3.1 void, 7.3 to 7.8 terrain (veryfast), 37 (ultrafast).
- Frames looked at full size: B1 terrain (Vulkan), x11grab terrain (Vulkan, window at 0,0 on an 854x480
  Xvfb screen), a stepped title over terrain (OpenGL). All correct; B1 and x11grab frames look the same.

### Requirements, gated against recorded

| Run | n per job | Verdicts equal, GL / VK | Wrong | Pixels agree, GL / VK | Sync title, chat, block, entity (GL / VK) | Repeated frames | Video |
|---|---|---|---|---|---|---|---|
| B1 real time, void | 60 | **60/60 / 60/60** | 0 | 60/60 / 60/60 | 0, 0, 0 to 1, 0 to 1 (one minus 2) / same | 1 to 2 | 1531 frames, 390 KB, 51 s |
| **B2 x11grab, void** | 60 | 60/60 / 60/60 | 0 | **48/60 / 57/60** | GL: 1, 1 to 2, 1 to 2, entity never found. VK: **minus 1 to plus 16** for every kind | | 335 to 390 KB |
| B1 step, rate 10, terrain | 40 | **40/40 / 40/40** | 0 | 38/40 / 40/40 | 0, 0, 2, minus 2 (GL) / 0, 0, 2, 0 | 0 | 600 frames, 340 KB |
| B1 real time, terrain | 40 | 40/40 / 40/40 | 0 | 40/40 / 40/40 | minus 1 to 0 for most kinds, block 1 to 3 | **216 / 272 of 1050** | 480 KB |

- **Verdicts reproduce on the runner too**: 400 of 400 across both backends, 0 wrong.
- **B2 cannot place a fact on a frame.** It maps facts through ffmpeg's first frame time and wall
  clock; on Vulkan the error ran up to 16 frames (half a second) and ffmpeg dropped 25 frames, on OpenGL
  it was a steady 1 to 2 frames late and the small text display was never found in its span. B1 needs
  no mapping: the sidecar names the fact frame.
- In terrain, sync offsets of minus 1 are water animation crossing the pixel threshold before the effect
  (**inferred**); the stepped run, which is slower and smoother, came out clean on Vulkan.
- "Dirty 40 of 40" in both terrain runs, gated and recorded: the leftover check expects air at the fake
  block position, which is terrain in the default world (S0 saw the same). A harness artefact, not a leak.
- Clips: requirement mp4 18 to 47 KB, webp 19 to 78 KB. The whole 60 requirement void run as one webp
  is 2.4 MB at quality 60; the terrain runs 2.0 to 2.3 MB.

### Fixed step on the real slow renderer

Terrain, rd 5, renderer 22 to 25 FPS on its own, no cap. Motion from the offline check
(first to last movement of the text, expected 30 frames).

| Case | Repeated frames | Move frames | Still frames in the move | px per frame | Client ticks, server ticks | Lag |
|---|---|---|---|---|---|---|
| Real time, rate 20 (GL / VK) | 49 / 53 | 72 / 27 | **25 / 7** | 2.5 / 10.2, jumps to 59 | 128, 129 / 127, 168 | |
| Step, rate 20 | 0 | 28 / 33 | 0 / 1 | 6.1 / 7.4, jumps to 23 / 16 | **101 / 91** against 128 / 167 | **1.3 / 1.8 s** |
| **Step, rate 10** | 0 | 27 / 28 | **0** | **7.5** | 125 / 126 | 0 |
| **Step, rate 5** | 0 | 27 | **0** | **7.5** | 126 / 125 | 0 |

- **Step at rate 10 on the runner gives the same motion as the uncapped Mac reference** (7.5 px per
  frame, no still frame), at 2 times wall time; rate 5 at 4 times. Rate 20 falls behind as on the Mac.
- The rule holds with measured FPS: rate 20 needs 30 FPS, rate 10 needs 15, and the runner gives 22 to 25.
- Server tick counts above 127 in the Vulkan job are Paper catching up after the rate 20 case stalled
  (**inferred**); client ticks were right in every good case.

## Surprises

1. **The clip can show the previous requirement** after every fact barrier said clean (block leftover
   for 1 to 2 frames). Demo mode and goldens need a render barrier.
2. **Display entities lag client state by up to a tick** (`Display.tick` builds the render state).
   Another small A1 lie, now with a frame count.
3. **A too fast server in step mode fails silently**: smooth looking video, compressed game time.
   Lag and tick counts must be asserted.
4. The engine already contains the async readback pattern (`TracyFrameCapture`), so B1 needed no GL.
5. `scale=427:-2` makes x264 refuse odd widths; use even sizes.
6. **OpenGL readback on llvmpipe is 10 to 30 times dearer than Vulkan** on the same runner.
7. **x11grab's wall clock mapping drifted up to 16 frames** on the runner; ffmpeg dropped frames silently.
8. A webp preview is 5 times larger than the mp4 of the same clip (340 KB against 60 KB for 6 s).

## What this means for the search (for the README keeper)

- **B**: choose B1 plus a demo rerun. Video is never recorded during the gated suite; a requirement that
  fails, or one marked for evidence, reruns rendered with recording. Verdict reproduction held in 728
  of 728. Cost of a demo: the requirement's own game time, times 2 in step at rate 10, plus about 1 s of
  settle and linger for a watchable clip.
- **B4 is required on CI terrain** (22 to 25 FPS here): pick the server rate from the measured FPS, assert
  lag 0 and equal tick counts. It shares C's open question on wall clock behaviour.
- **H**: Vulkan is now recommended for a second reason: OpenGL readback costs 2.3 to 7.1 ms per frame on
  llvmpipe.
- **B2 is out** for requirement clips: no frame sync. The panel's recorder can stay as it is for panel
  stories.
- **E**: add a render barrier (frame drawn after the clean state, sections meshed) for anything that
  looks at pixels after a cleanup. The fact barrier is not enough for frames.
- **A**: new numbers for "drawn later than held": block 2 rendered frames, display entity up to one tick.
- **F**: goldens can take a frame straight from the B1 path (raw RGBA, no PNG) and know its fact frame.
- **G**: a requirement report can carry `clip.mp4`, a 30 KB preview, and a still at the failing frame.

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

From `prototypes/game-verification`, one at a time:

```
python3 orchestrator/video.py cost --reps 2 --settle 14 --keep-frame
python3 orchestrator/video.py cost --world default --rd 5 --reps 2 --settle 14 --keep-frame --configs none,all-null,rt30-x264,rt30-x264uf,rt60-x264,rt30-vt,all-x264,none
python3 orchestrator/video.py reqs --n 100 --settle 14
python3 orchestrator/video.py reqs --n 40 --mode all --settle 14 --linger 0.3
python3 orchestrator/video.py reqs --n 40 --mode step --rate 10 --cap 20 --settle 14
python3 orchestrator/video.py step --settle 14
python3 orchestrator/video.py reanalyse runs/video/<reqs dir>
```

Results append to `runs/b-video.jsonl`; videos, clips, previews and frames go to `runs/video/<label>-<time>/`.
CI: matrix row `{ plan: video, backend: vulkan|opengl, runner: ubuntu-24.04, repeat: 0 }` in
`.github/workflows/game-verification-prototype.yml` (the workflow installs `ffmpeg` from apt and uploads
`runs/b-video.jsonl` and `runs/video`), plan `video` in `orchestrator/ci.py`, about 17 minutes. The
branch was left with the `smoke` row (pushed with `[skip ci]`, so no run).

## Reuse

- `Video.java`: the readback ring, the ffmpeg pipe, the sidecar, step mode. Turning it into a product
  means: a render barrier before marks, a bounded queue that never blocks the render thread outside
  step mode, and the ffmpeg process owned by the harness rather than the client.
- `video.py`: `frames` (decode to numpy), `still`, `cut` (clip plus webp under 3 MB), `sidecar`,
  `v_of_frame`, `analyse_sync`, `cmd_reanalyse`.
- `ci.py`: `X11Grab` (B2 with the first frame time from ffmpeg's log), `Xvfb.size`, plan `video`.
- Facts: a tick snapshot names the next frame (`Probe.onTick`); `Probe.frames()`, `Probe.ticks()`.
