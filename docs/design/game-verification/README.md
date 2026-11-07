# Game verification: prototype search

Living record of the prototype search for in-game verification. Read this file first after a
context reset. It holds the goal, the search map, and one line per result; details live in
`spikes/` and `research/`. Prototype code lived in `prototypes/game-verification/` and was removed when the search ended
(kept in history at `86724c794`); what survives is this record.

## Goal

Choose how Typewriter proves what a player experiences in a real Minecraft client, by trying
several approaches per question and measuring them. Not an implementation plan yet.

Judged on, in the developer's order:

| Criterion | Meaning |
|---|---|
| Flexible | Any new kind of behaviour can be checked without a new framework feature |
| Accurate | Checks what the player perceives; never packet sequences. A deliberately broken behaviour must fail |
| Recordable | Video of what the player saw, and comparison against approved references |
| Performant | Hundreds of requirements in minutes. "if one tests takes already 3 seconds we are in big trouble" |

## Facts that frame the search

- **Target is Paper 26.3 on Java 25** (`services/runtime/engine/runtimes/paper/build.gradle.kts:57`).
  The plan text and some research assumed 1.21.4. The loader still compiles against the 1.21.4 API
  (`services/libs.versions.toml:13`). Research citations to 1.21.4 client code must be rechecked
  against 26.3 sources before relying on them.
- 26.3 clients use SDL and can render through OpenGL or Vulkan. 26.4 snapshots reportedly default
  to Vulkan. Keep capture behind the engine's render target, not raw GL.
- The panel records video (Linux only, Xvfb and x11grab) but **compares nothing**. There is no
  golden mechanism to copy.
- Real v1 behaviour testable today is tiny: one action (message), one event (chat contains text),
  one trigger relation. Everything richer needs probe plugins that imitate the legacy mechanics.
- Precedent: only one rendered pattern exists publicly (Fabric client game tests, Xvfb, llvmpipe).
  Nobody publishes it against external Paper with goldens or with several rendered clients.

Sources: `research/prior-decisions.md`, `research/real-client-precedent.md`,
`research/speed-capture-determinism.md`.

## Settled before this search

Real clients only, no packet level tier (rejected twice). Stimuli are player input or API, not chat
commands. Full suite on every pull request. The framework holds no Typewriter code and may later
move out. Goal numbers in the old plan (1 s, 45 s, 350 in 3 min) are agent estimates, not
requirements; the hard statement is the 3 second quote and "if this takes 5 hours, then it's not
worth it".

## The search map

Each axis is tried separately, so a result on one does not depend on the others. A spike is small
and is deleted after it answers its question.

| Id | Question | Candidates to try | How we decide |
|---|---|---|---|
| **S0** | Does a real 26.3 client play on external Paper at all? | Fabric client mod plus connect by address | It joins and reports facts; start time and memory |
| **A** | How do we observe what the player perceives? | A1 client state; A2 what was actually drawn (text runs, entities submitted, sounds); A3 pixels in a region; A4 ID pass for real visibility | A "lying" battery: scenes built so that a weak observer is fooled |
| **B** | How do we make video? | B1 in-client frame readback to ffmpeg; B2 window capture; B3 packet capture and offline render on demand | Frame cost, quality, per-test clip sync, works on Mac and CI |
| **C** | How do we make it fast? | C1 render only when needed; C2 run the client clock faster than 20 TPS; C3 long lived client with fast reset (world swap, region, reconnect); C4 micro server: smallest and fastest Paper boot | Seconds per requirement, what breaks |
| **D** | How many clients? | D1 one client in sequence; D2 N clients on one Paper; D3 one Paper per few clients | Requirements per minute, memory, interference |
| **E** | How do we know a world is ready, and when a step is done? | E1 echo barrier through a plugin channel; E2 chunks rendered; E3 polling observed facts | Flake rate over repeats |
| **F** | Can goldens be stable? | F1 same scene N times, measure noise; F2 frozen tick; F3 region versus full frame; F4 Mac versus Linux | Pixel noise floor versus smallest real change we must catch |
| **G** | How does a requirement read? | G1 windows; G2 await style; G3 timeline checked after the run. Also where logic runs: Paper, client, or a test JVM | Same scenarios side by side; developer preference |
| **J** | Can a test drive real player input reliably and fast? | Input through the OS or window system, through the client's input callbacks, through the game's own actions; packets only as a baseline | Same server event as a person's input, flake rate, cost gated and rendered |
| **K** | How do requirements that kill or restart Paper run with a warm client? | Restart the same Paper; a pre booted standby Paper; restart only the plugin | Seconds per restart requirement, verdicts after, leftovers |
| **N** | Can the test runner step ticks itself? | Paper's tick manager frozen and stepped from the runner; client time driven per step; Paper's wall clock timers (`currentTick`, block break) tied to the stepped tick | Verdicts exact without slowing down, throughput, what still runs on wall clock |
| **I** | Can coverage be attributed per requirement on a long lived Paper, cheaply? | I1 coverage agent with dump and reset between requirements; I2 one run per requirement group | Overhead per requirement, correct attribution on known scenes |
| **H** | Does it hold on CI? | Real free runner, 4 vCPU, no GPU; llvmpipe OpenGL versus lavapipe Vulkan | FPS, throughput, flakes, the renderer string |

Yardstick scenes, used across axes because they are the hard parts of the legacy behaviour:
title with fade, chat line, action bar, packet only entity seen by one player only, per player fake
block, camera ride on a packet only display entity with client interpolation, fake empty inventory,
and sound. The full behaviour list is in `research/prior-decisions.md`.

## Rules for running spikes

- Throwaway Paper instances are started only inside `prototypes/game-verification/`, on free ports,
  and are stopped after each run. This thread's prototyping is the one exception to the rule against
  starting Paper by hand, confirmed by the developer (2026-11-07): a prototype branch may use local
  throwaway Paper servers and CI, since results must hold on both. No k3d, no deploy.
- Gradle goes through `cargo xtask heavy`, so it queues behind other builds.
- Timing runs happen one at a time. Note machine load with every number.
- Every number names its machine and renderer. Evidence and inference stay labelled.

## Decisions from the developer

- Spike H may push this branch with a temporary workflow that runs only on this branch, to measure
  on GitHub's free runner. Remove the workflow before the search ends.
- v1 cinematics and sequences advance on the **tick clock**, not wall clock (2026-11-06). A faster
  server rate in tests speeds them up; under server lag they slow down instead of keeping pace.
  Legacy used wall clock (`PlayerSession.kt:61`); this is a deliberate change.
- Confirmed against the newer design docs (2026-11-06): **engine step timing counts ticks** (scenes,
  typing, grace), so `Running.startedAt: Instant` and `elapsed = now - startedAt`
  (`interactions.md:311`) and `optionDelay = 100.milliseconds` (`dialogue.md:96`) become ticks;
  authors may still write durations, converted at 20 ticks per second. The realm's clock stays wall
  time (`Due`, `stored-data.md:460`), and tests of realm timers need a realm clock the test can
  advance. Applied 2026-11-07: each engine keeps a live `StepClock` per step from the tick it saw
  the step start, and the stored rows carry no step time (`interactions.md`, `dialogue.md`).
- **Group behaviour must be testable** (group chat, shared audiences, world groups), and requirements
  share a **pool of 4 warm clients**: a requirement claims as many as it needs and the rest keep
  running other requirements (2026-11-06). Books scoped per player are expected to remove most
  conflicts. Fresh identity per requirement versus a wipe of the player's state is decided from
  spike K's numbers (see the K row).
- Each requirement gets a **full wipe** of its player (2026-11-07, replacing an earlier choice of a
  fresh identity): the realm gets a general "purge all data of this subject" operation, useful beyond
  tests, and the engine clears its live state for that player the same way. Spike K: a full wipe of
  17 kinds leaked 0 and costs about 9 s per 500 requirements on one client. Tweaks to the realm, the
  engine and Paper are allowed where they make tests controllable. Restart requirements run on a
  Paper of their own (kill and boot).
- **The test runner decides when a tick happens** (2026-11-07): Paper's own ticking is stopped and
  the runner steps ticks forward, so tests know exactly when things happen and need not slow down
  for wall clock timers such as Paper's block break timer. Proven or disproven by spike N.
- **Retries** (2026-11-07): a failed requirement is retried later, not immediately, up to 3 times,
  and a requirement that passes on a retry is reported as flaky. For inherently lossy inputs (tab
  suggestions) the framework may repeat the input within the window; the verdict still fails if the
  window closes without the fact.
- The **full framework is built first** (2026-11-07), before L3: pool, fresh identities, input,
  observers, windows, done signal, restarts, video, goldens and coverage, as its own work ahead of
  the layers.
- The done and fail signals use a **per subject view** (2026-11-07): engine and realm count queued
  and running chains and pending realm transactions per protagonist or group (group chains count for
  every member). A hung chain is reported by a wall clock limit on the test side, never cancelled by
  Typewriter. A future `Due` timer is not busy; a requirement waiting on one advances the realm
  clock. This replaces "counted dispatchers" from spikes I and D; the plan names the hook.
- Video clips on a pull request go to **failing requirements plus requirements the pull request
  touches** (2026-11-06). "Touched" comes from ordinary coverage: the lines each requirement covers,
  intersected with the diff. This needs coverage per requirement on a long lived Paper, which spike
  I measures.
- A frame that differs from its approved golden **fails the test** and the pull request shows golden,
  new frame and diff (2026-11-06). Goldens are exact on the pinned runner platform (spike F).
- Requirements are written as **G1 windows plus the recorded timeline** (2026-11-06): every check sits
  in a `within(n.ticks)` window that opens at the last stimulus and passes the moment it holds; order,
  gaps and motion are read from the run's recorded timeline after a window. Drafts in
  `spikes/g-requirement-shape.md`.
- Requirement code runs in a **test JVM** (2026-11-06). The client streams what its player perceived,
  loop by loop, with the window barrier inside that stream; Paper and the client hold no requirement
  code. The stream's size is not measured yet.
- A window counts from the **last player action or probe call**, with an optional named start
  (`within(40.ticks after left)`) for the rare case (2026-11-06).
- `never` checks are **broad** (`anyChat()`, `anyTitle()`), and the framework **refuses** a requirement
  whose checks are all `never` or all client state: it needs one positive check (2026-11-06).
- A requirement that needs rendered frames **declares it** (`player(frames = 60.hz)`), so the runner
  groups such requirements at a fitting server rate before it starts (2026-11-06).

## Open questions for the developer

- "Micro server" is read as the smallest, fastest booting Paper. They may correct this.

## Status

The search is finished (2026-11-07). After checking the record against the newer design docs, gap
spikes J (real player input), K (restarts and isolation) and N (runner stepped ticks) ran and are
recorded below with the developer's later decisions above. The prototype code and the temporary
workflow are removed again; they remain in git history at commit `86724c794`
(`prototypes/game-verification/` and `.github/workflows/game-verification-prototype.yml`), which the
Rerun and Reuse sections of J, K and N refer to; spikes before J refer to `9c9275f22`. Spikes L (a
1.21.4 client next to 26.3) and M (dialogue redraws on the chat screen) are deferred past the first
working version of the framework and run once their layers exist. Next
is the framework plan, built in full before L3.

## Results

One line per finished spike, newest last. Details in `spikes/`.

| Spike | Result | Consequence |
|---|---|---|
| S0 | Yes. Real 26.3 client plays on external Paper. All scene kinds reach client facts and pixels. Paper boot 7 to 9 s, client in world 12 s, each about 1.2 GB RSS, 300 to 500 FPS on Metal, scene to fact 5 to 25 ms. Rerun and frame checked by the coordinator. | Restarts are unaffordable per requirement, so long lived clients with fast reset (C3). `noRender` is gone in 26.3, so C1 needs a mixin. First lying scene: an entity the client knows but does not draw. |
| A | No single observer is honest. On 33 lying scenes, 5 runs: client state 14 correct and 16 false positives; what was drawn 30 and 3; pixels 27 and 3; visibility pair 29 and 1. Drawn plus visibility pair got all 330 verdicts right, with and without rendering gated. Cost: drawn 5.9 ms, pair about 26 ms per check. New kinds (boss bar, sidebar) took 0 lines for drawn, 22 to 28 for client state. Frames checked by the coordinator. Mac, OpenGL only. | "Seen" should be one primitive: drawn legibly plus owns visible pixels. Client state only arranges scenes and names causes. Pixels serve frames and goldens, not verdicts. Camera smoothness needs per frame samples at 60 Hz or more, so it costs wall clock. |
| C | Reset, render and observation are not the limit. Trivial requirement: 0.100 s with real ticks at 20 TPS, 0.010 s at server rate 200 with rendering gated, 0.060 s with full world isolation at rate 200. No wrong verdicts in 18050. Gating drops client CPU to 13%, a frame on demand costs 131 ms. Mac only, facts only, trivial scenes. | The real unknown is requirement duration. A fast fail gave 95 of 95 wrong fails when the effect came one tick late, so requirements must declare a window. Rate is server wide. Fresh server per test is never affordable. |
| H | Yes on the free runner (4 vCPU, no GPU), x86 and arm, OpenGL and Vulkan through llvmpipe. Gated throughput equals the Mac: 0.0052 s direct, 0.010 s at rate 200. 0 failed joins in 238 client starts, 0 wrong verdicts in 44000. Frame on demand 0.1 s void, 0.13 to 0.19 s terrain. Rendered FPS 22 to 41 in terrain at 854x480 rd 5, and the x86 fleet mixes five CPU models with over 2 times FPS spread. 4 gated clients scale linearly on one Paper. Frames checked by the coordinator. | CI is not the limit; the render gate is the default. Recommend x86, Vulkan, renderer asserted (OpenGL silently falls back to Vulkan under Xvfb), `ALSOFT_DRIVERS=null` or the sound system is off. Never use FPS or wall clock as a threshold. Barrier ids must never repeat. `settledAt` only works in flat scenes. Goldens must pin one architecture (arm against x86 differs in about 98k pixels). Real time video in terrain needs a fixed step or low rate. |
| B | In-client readback (B1) of the engine's render target piped to ffmpeg, with a sidecar line per video frame naming fact frame and tick. 0.35 ms per frame on the Mac, 0.17 to 0.24 ms on the runner with Vulkan, 2.3 to 7.1 ms with OpenGL on llvmpipe. Video is a demo rerun of the gated requirement: 728 of 728 same verdict. Clip lines up with facts: title and chat 0 frames off, block up to 2 (meshing), display entity 1 (drawn after the next client tick). Clip 18 to 47 KB; 100 requirements as one preview 2.9 MB. Window capture (B2) was up to 16 frames off with no sync; packet replay (B3) not worth building. Frames and CI run 42111131229 checked by the coordinator. | Record only in a demo rerun, never in the gated suite. On CI record in fixed step at server rate 10 on Vulkan; pick rate from measured FPS and assert no lag. Pixel checks after a cleanup need a render barrier: the previous requirement's block stays 1 to 2 frames after facts say clean. A failure maps to one still frame. |
| F | Yes, on one pinned platform (x86, Vulkan through lavapipe, Mesa 25.2.8): 0 differing pixels in 265 identical pairs, across repeats, fresh clients, four x86 CPU models, void and terrain with water. Exact comparison caught 1400 of 1400 small breaks (one letter, colour off by 3, one pixel lower, stone against andesite, quarter block, missing item); every tolerant method (SSIM, blur, threshold) missed colour off by 3. Fixed offsets elsewhere: OpenGL against Vulkan 304 pixels, arm against x86 82045, Mac against runner 77k to 110k. Compare 0.04 ms; capture 0.18 s void, 0.55 s terrain; golden 237 KB PNG or a 32 byte hash. Coordinator rehashed all 666 CI frames: one hash per scene across CPU models with all knobs on. | Goldens are approved from the runner's own frames, never the Mac. Needed knobs: freeze the client before arranging, texture animation at frame 0, light flicker pinned, vignette off, glint speed 0, toasts used up once per session, render barrier over two frames a client tick apart. Untested: moving camera, entity spawned before the freeze (up to 1170 pixels). A Mesa or Minecraft upgrade likely changes every golden at once. |
| I | Yes. JaCoCo agent limited to the plugin's classes, probes read and reset inside the plugin at the end of each requirement (I3): on the runner 5.0 against 5.1 ms per direct requirement, 10.2 against 10.3 ms at rate 200; dump 21 to 53 us on the main thread; boot unchanged. 3000 of 3000 normal requirements attributed correctly. Work finishing after the requirement (next tick, Bukkit async) went to the wrong requirement 62 to 92 times in 100 with a plain dump, 0 in 2100 after waiting for an idle scheduler (0.1 to 0.5 ms). Work on a raw thread pool is invisible to that wait: 94 of 100 wrong. TCP dump costs 41 ms per requirement on Linux; instrumenting all classes adds 6.2 s boot and about 50 percent. About 0.5 KB lines per requirement; 1000 dumps to lines 2.2 to 2.8 s; diff intersect under 6 ms. Coordinator checked CI run 42162248604 data. | "Touched by the pull request" is affordable. Requirement end must wait for the plugin's work to be idle, which is also a candidate "done" signal for E. Typewriter's async work must run on dispatchers that can be counted, or coverage and readiness both miss it. Reports are built from the agent's class dumps, since Paper rewrites plugin bytecode. Precedent: Teamscale testwise coverage. |
| E | Four signals, one per question. Start: level present, no screen, toasts and chat cleared, first person hands settled; matched the settled frame in 100 of 100 Mac swaps and 30 of 30 runner swaps, wrong in 2 of 70 Mac reconnects and 3 of 16 runner reconnects by one frame; every chunk or mesh signal fires 180 to 200 ms early. Fact verdict (E3t): read the fact every client loop, pass when it holds, fail only on a window barrier sent after the declared window in ticks; 0 wrong in 4000 Mac and 800 runner repeats over all lying scenes. Done (E6): plugin quiet barrier, then a client loop with nothing in flight. Pixels: fact verdict plus the object's own draw, empty render queue and radius chunks; 0 wrong. Bare barrier wrong in 90 percent of delayed repeats, wall clock window wrong in every lag repeat, server quiet alone wrong on title fade and chunk. E3t decides 2.6 to 3.1 ms gated; E6 adds 2 to 4 ms. Coordinator recounted CI run 42174196154 for E1, E3t, E3ms, E4 and pixels; E6 is judged from traces and was not recounted. | A pass costs nothing beyond the truth; only a fail waits for its window. Never use wall clock windows. Warm a client once and reuse it: a first join keeps changing about 0.5 s more, and a reset that leaves the player moving takes 1.15 s to settle in frames (facts stay right). Fresh client numbers are Mac only. |
| G | Drafted, not built: six hard scenarios in windows (G1), await (G2) and timeline (G3) styles, plus where the code runs. G1 34 lines, G2 32, G3 42; G3 waits its whole recording on every pass (about 25 s against 3 s for 500 requirements, inferred from C). G2 anchors each window at the line before, so limits silently grow. All three fit one mechanism: the client streams perceived changes with the window barrier inside the stream. | The developer chose G1 plus the timeline, a test JVM, implicit window start at the last action, broad `never` with a required positive check, and declared frame needs. Framework names and v1 setup accessors in the drafts are assumed. |
| D | The free runner holds 8 gated clients; best as 2 Papers with 4 clients each: 16,700 to 17,500 requirements a minute with the E signals, 13.6 GB. One Paper: 2,400 / 9,450 / 16,500 a minute at 1 / 4 / 8 clients when E6 counts each player's own work; with E6 server wide (as E and I built it) one Paper caps at 6,800 to 11,700. Join one at a time and gate each client the moment it is ready (16 to 21 s each); gating from the first frame hits the client's 30 s loading timeout. 15 wrong verdicts in 245,224, all from world wide broadcast chat and titles; per player versions of every leak and regions 1024 blocks apart gave 0. Coordinator recounted 155,395 fleet requirements, 0 wrong, in runs 42184657603 and 42187755498. | A client costs about 16 s and 1.4 GB, a requirement about 24 ms, so 1 or 2 clients cover today's suite and 8 pay off only above about 15 minutes of single client work (inferred). The framework must enforce per player effects, distant hidden regions, per player E6, and checks matching the requirement's own token. Only a separate Paper isolates tick rate (a rate 10 demo cut neighbours 94 percent), main thread lag (39 percent) and coverage. **Fail rule with async work:** a tick window shrinks with the rate while wall clock async work does not (window only: 124 of 600 wrong at rate 200, 179 at rate 400 on the runner). Rule tested at the cause: fail only when the window barrier has arrived **and** that player's own counted work is quiet, with a 1000 ms wall clock limit on that work held by the dispatcher, which cancels hung work. 0 wrong in 1,800 runner and 900 Mac requirements at rates 20, 200 and 400; 30 of 30 hung requirements still failed; a pass is unchanged; a real fail waits only for async work still running (about 95 ms for 50 to 150 ms work). A tick limit instead brings the wrong fails back (28 and 73). Coordinator recounted run 42198290611. Every async path must be counted with its player. |
| J | Real window events work for every input: XTest on the client's own Xvfb on the runner (vanilla grab, focus, relative motion), the same SDL events pushed into the client's own queue on the Mac (no OS input, real cursor untouched). Both matched direct handler calls on all 17 inputs (chat, command, tab suggestions, break, cancelled break, use, spyglass hold, swap, scroll, number key, sneak, jump, attack and interact with entities, inventory click, walk), 200 of 200 each; rendered and gated give the same events; a 300 ms client or server lag left events identical. Game action calls never match typed tab completion (0 of 200); packets miss aim and get kicked when walking. Cost 0.03 to 0.09 s per input at rate 200, walking 4 blocks 0.16 to 0.18 s. CI runs 42211818480, 42215647584, 42218505138 checked by the coordinator. | Input goes through real window events; waits count client ticks. **Paper's block break timer runs on wall clock**, so breaking only works at rate 20 (1.0 to 1.25 s per break); such requirements run at rate 20 or the timer needs a decision. Typed suggestions got no reply 5 to 45 percent of the time (server keeps only the latest request per tick; cause inferred), so a suggestion check needs a retry or a cause fix. No pixels checked in J. |
| K | Restart: kill the same Paper (SIGKILL) and boot again, connect when Paper logs Done: ready in 5.1 s on the Mac, 12.9 s on the runner (boot 9.5 s there), 0 wrong verdicts. A standby Paper (1.4 to 2.8 s) reads stale state at boot, a plugin reload (0.7 s) keeps unsaved items, and a clean stop saves player data, so each gave wrong verdicts on broken trials. Isolation: a fresh identity per requirement leaked 0 in 2,540 requirements; a full wipe of all 17 kinds also leaked 0, while the obvious wipe (store, chat, inventory, effects, position) and a same name reconnect leaked 11 kinds every time. 500 requirements on the runner at rate 200: fresh 108 s on 1 client and about 55 s on 4 (facts ready), full wipe 9 s and about 5 s; with frames ready 227 and 115 s against 35 and 14 s. About 5.4 KB of player files per identity, heap flat. Coordinator checked CI run 42235574190. | Restart requirements need a Paper of their own (a kill drops every client). **Correction to C and E:** their reconnect closed only the client side, so Paper kept the old player about 30 s and those numbers measured a duplicate login kick, not a quit; leaving like the pause menu fixes it. A gated client never leaves the loading screen, so it draws until ready, then gates. The isolation choice is the developer's (asked with these numbers). |
| N | Yes, with a small Paper tweak (N2): the main loop waits for a permit from the runner, Paper's break clock counts ticks, the client's clock moves one tick per step ping; the next tick is granted only after the client acked and the subject's async work is quiet. Vanilla freeze and step (N1) fails: plugin tasks, players and the break clock keep running on wall clock. Lockstep costs 1.2 to 1.9 ms per tick (Mac) and 1.22 to 1.31 ms (runner); server and client ticks matched 2000 of 2000. Trivial requirement passes in 2.0 ms and fails in 2.9 ms on the runner (rate 200: 5.0 ms). 0 wrong in 1,800 requirements; exact windows right 562 of 562; async work of 50 to 150 ms passes with no wall clock window, hung work fails at the 1 s limit. Breaking at stepped speed: 200 of 200 on the Mac, 150 of 150 and cancelled 150 of 150 on the runner after a rig fix (an earlier 0 of 100 was the startup loading overlay still up when the client was gated: a gated client draws no frame to remove it, and it blocks keybinds; readiness now waits for it). 0.031 to 0.034 s per break, CI run 42310014228. Coordinator checked CI run 42304863563. | Stepped ticks replace rate grouping and the wall clock fail rule, except for the hung work limit. Still wall clock and to be handled: Paper's packet limiter (kicked after about 1100 steps, off in the rig), the 30 s network read timeout and Paper's 60 s watchdog during long pauses, lag compensation for eating and sprint jumps (inferred). Effects sent from an async thread land one step late, so effects should go through the main thread. Tweak about 160 lines as an agent, about 30 as a Paper patch (inferred). |
