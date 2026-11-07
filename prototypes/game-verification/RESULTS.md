# Live perception stream: results

Throwaway prototype on `proto/gv-stream`. Question: can a real 26.3 client stream what its player perceives,
loop by loop, to a test process cheaply enough? How big is the stream, and how late does it arrive?

## Answer

- **Yes, and full records are fine.** A typical requirement produced **2.9 records of 61 bytes median**
  (101 max): **about 212 KB per 1,000 requirements** on the Mac (218 KB on the runner). Diffs would have
  cost 146 KB (69 percent; a diff after the first record is 39 percent of the full one). Saving 66 KB per
  1,000 requirements does not pay for diff state on both ends, resync rules and a harder decoder.
- **Building and encoding a record costs nothing that matters**: 0.01 to 0.1 ms median on the render thread
  (p95 under 0.2 ms, one 1.5 ms outlier). **The cost is the frame**: a gated stepped client must now draw one
  frame per tick so there is something to read, which took a stepped tick from **1.76 ms to 3.41 ms** on the
  Mac (2.40 ms to 8.06 ms on the runner).
- **Latency is a few milliseconds**: server tick end to the listener holding the record **4.3 ms median,
  9.0 ms p95** (Mac, typical requirements); barrier sent to its echo received **4.0 ms median, 8.8 ms p95**.
  Most of it is the client: from its own tick end to the listener 2.5 ms, of which the frame is 1.9 ms and the
  socket hop 0.16 ms. Runner: 12.1 ms median, 15.2 ms p95; barrier 12.0 ms and 15.2 ms (a lavapipe frame is
  about 6 ms).
- **The HUD element tag is reliable**: 14 of 14 checks right, 0 untagged text runs in any scene. Seam: a tag
  stack pushed at HEAD and popped at RETURN of each `Hud.extract*` method (and `Screen`, `CommandSuggestions`,
  `ToastManager`, the deferred tooltip), read in `GuiRenderState.addText`.
- **A4 does not belong in every record.** With visible pixels of two watched entities in each record while
  walking, every tick changes the record (pixel counts move), A4 costs 9.2 ms median per record, the stepped
  tick goes from 6.1 to 13.6 ms and the record arrives 29 ms after its tick instead of 7 ms (runner: A4
  16.6 ms, tick 15.2 to 26.5 ms, record 51 ms instead of 22 ms).

Machines: the developer's M1 Max (OpenGL 4.1 on Metal, gated client mode 2, park 2 ms, 854x480, render
distance 2; **load 14.9 to 18.7**, other work running) and the GitHub free runner run
[42336338774](https://github.com/gabber235/Typewriter/actions/runs/42336338774) (`ubuntu-24.04`, x86, 4 vCPU, Vulkan on
lavapipe under Xvfb, same client settings). Everything is measured unless marked **inferred**.

## What was built

- **Client** (`probe-mod`, `observe/Stream.java`, `observe/Tag.java`, `streammix/*`, about 600 lines):
  after every drawn frame the render thread builds the perceived state from spike A's A2 frame record, encodes
  it with a `DataOutputStream`, and queues it when the content bytes differ from the last record sent (exact
  compare, no hash needed). A sender thread writes `int length, type byte, body` over TCP (no delay).
  A gated stepped client draws one frame after each client tick and after each barrier.
- **Record content**: legible text runs as (tag, text); chat lines added since the requirement started; on
  screen command suggestions; watched entities (drawn, visible pixels); watched blocks (state, section visible);
  facts (screen, HUD hidden, block position, boss bars with progress in percent, health). A header carries the
  server tick and frame plus measurement timestamps; only 8 bytes of it (tick, frame) are counted as
  essential.
- **Legibility rule** ported from `orchestrator/observe.py:331` to `:416` into Java (GUI: alpha at least 8,
  more than half on screen, not painted over by a later opaque rectangle or panel, not under the blur; world:
  on screen, facing, alpha at least 26, not the colour of its own background; name tags: on screen).
- **Barrier**: a vanilla ping below 2^30 (spike N's step pings stay above) is queued in `PingMixin`, forces a
  frame, and is echoed right after the record of that frame. Step grants wait while an A4 pair is in flight so
  both frames see the same tick.
- **Listener** (`orchestrator/Listener.java`): a separate JVM, stamps each frame with `System.nanoTime` (one
  monotonic clock for all processes on the machine), decodes it and prices a diff (5 framing + 8 header +
  1 bitmap, per changed section 4 + 2 per removed item + 2 plus the bytes per added item).
- **Paper** (`probe-plugin`, `StreamScenes.java`): the scenes as Bukkit tasks, so they follow stepped ticks;
  tick end timestamps; barrier sends. Spike N's step agent and lockstep policy unchanged.
- `orchestrator/stream.py run` runs everything; `ci.py plan stream` on the runner.

## Mac

| Scene | Ticks | Records | Records per tick | Bytes per record, median (max) | Diff over full | Build and encode ms, median (p95) | Frame ms, median | A4 ms, median | ms per stepped tick | Server tick to listener ms, median (p95) | Barrier to echo ms, median (p95) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 action bar fight, 100 ticks | 112 | 42 | 0.375 | 68 (81) | 0.7 | 0.025 (0.054) | 2.289 | - | 3.448 | 5.387 (8.323) | 5.548 (8.088) |
| 2 title 10/40/20 | 82 | 3 | 0.037 | 44 (105) | 0.705 | 0.021 (0.083) | 1.753 | - | 3.071 | 4.415 (4.52) | 4.603 (5.237) |
| 3 chat burst of 20 | 32 | 3 | 0.094 | 1375 (1780) | 0.588 | 0.019 (0.106) | 2.635 | - | 3.123 | 7.112 (7.256) | 4.822 (5.76) |
| 4 boss bar, progress every tick | 112 | 102 | 0.911 | 94 (94) | 0.687 | 0.018 (0.031) | 2.043 | - | 3.087 | 4.8 (6.719) | 5.062 (6.88) |
| 5 walk 4 blocks, A4 off | 82 | 8 | 0.098 | 231 (231) | 0.37 | 0.068 (1.536) | 2.791 | - | 6.087 | 6.99 (119.483) | 7.505 (8.908) |
| 5 walk 4 blocks, A4 on | 82 | 38 | 0.463 | 231 (231) | 0.225 | 0.1 (0.181) | 2.959 | 9.204 | 13.608 | 28.716 (37.3) | 29.466 (34.379) |
| 6 typing a command | 65 | 41 | 0.631 | 142 (383) | 0.467 | 0.035 (0.059) | 3.258 | - | 6.299 | 8.831 (21.322) | 6.463 (10.479) |
| sidebar and tab list (tag check) | 32 | 3 | 0.094 | 61 (157) | 0.784 | 0.013 (0.021) | 2.881 | - | 3.629 | 5.867 (5.867) | 5.29 (5.834) |
| typical requirements | 5005 | 2912 | 0.582 | 61 (101) | 0.392 | 0.01 (0.019) | 1.936 | - | 3.825 | 4.289 (8.954) | 3.968 (8.767) |

- Bytes per record are the essential wire size: 4 length + 1 type + 8 tick and frame + content.
- Ticks include the 2 to 20 setup ticks of each scene; "ms per stepped tick" is wall time of the steps.
- Per 1,000 typical requirements: 2,912 records, 212 KB full, 146 KB as diffs.
- "Diff over full" counts every record after the first of its requirement or scene.

## Runner

| Scene | Ticks | Records | Records per tick | Bytes per record, median (max) | Diff over full | Build and encode ms, median (p95) | Frame ms, median | A4 ms, median | ms per stepped tick | Server tick to listener ms, median (p95) | Barrier to echo ms, median (p95) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 action bar fight, 100 ticks | 112 | 42 | 0.375 | 68 (81) | 0.7 | 0.024 (0.045) | 6.308 | - | 7.851 | 14.294 (18.415) | 14.615 (19.504) |
| 2 title 10/40/20 | 82 | 3 | 0.037 | 44 (105) | 0.705 | 0.016 (0.077) | 6.546 | - | 7.891 | 13.666 (13.756) | 14.091 (17.715) |
| 3 chat burst of 20 | 32 | 3 | 0.094 | 1375 (1780) | 0.588 | 0.014 (0.142) | 5.751 | - | 8.644 | 11.756 (16.529) | 15.027 (16.029) |
| 4 boss bar, progress every tick | 112 | 102 | 0.911 | 94 (94) | 0.687 | 0.018 (0.036) | 7.014 | - | 8.322 | 15.033 (19.808) | 15.57 (18.349) |
| 5 walk 4 blocks, A4 off | 82 | 8 | 0.098 | 231 (231) | 0.37 | 0.083 (1.189) | 9.562 | - | 15.15 | 21.746 (274.86) | 18.508 (21.941) |
| 5 walk 4 blocks, A4 on | 82 | 38 | 0.463 | 231 (231) | 0.225 | 0.099 (0.254) | 8.291 | 16.564 | 26.479 | 50.562 (97.087) | 53.002 (66.93) |
| 6 typing a command | 65 | 41 | 0.631 | 142 (383) | 0.467 | 0.038 (0.064) | 10.382 | - | 15.377 | 25.516 (90.972) | 22.279 (34.482) |
| sidebar and tab list (tag check) | 32 | 3 | 0.094 | 61 (157) | 0.784 | 0.012 (0.027) | 7.424 | - | 8.449 | 11.285 (11.285) | 14.376 (15.033) |
| typical requirements | 1505 | 901 | 0.599 | 61 (101) | 0.392 | 0.011 (0.021) | 5.838 | - | 7.371 | 12.058 (15.211) | 12.036 (15.186) |

- Runner: Intel Xeon 6973P-C, 4 vCPU, load 1.5 to 3.1, Vulkan on lavapipe. 300 typical requirements instead
  of 1,000. Job 137 s, stream run 60 s, no failed step, no leaked process.
- **Every scene produced exactly the same number of records as on the Mac** (42, 3, 3, 102, 8, 38, 41, 3):
  under stepped ticks the stream is deterministic across machines. Tags were the same 14 of 14.
- A lavapipe frame costs about 6 ms, so the stepped tick goes from 2.4 to 8.1 ms and a record arrives
  12 ms after its tick (client tick end to listener 6.4 ms, socket 0.11 ms).

## Full records or diffs

| Case | Full | Diff | Diff over full |
| --- | --- | --- | --- |
| 1,000 typical requirements, Mac | 212 KB | 146 KB | 0.69 |
| 1,000 typical requirements, runner | 218 KB | 148 KB | 0.68 |
| Chat burst of 20, the records after the first (largest record 1,780 bytes) | 3,155 bytes | 1,856 bytes | 0.59 |
| Boss bar, a record every tick (per record) | 94 bytes | 65 bytes | 0.69 |

- The only section that grows is "chat since start": 20 long lines make a 1.8 KB record. A requirement that
  sends 200 lines would send 18 KB per record (**inferred** from the per line size); still small next to a
  frame, and a requirement scope resets it.
- Diffs save bytes nobody is short of; the stream is about 1 KB per second of stepped ticks at most.
  **Verdict: full records.**

## How the HUD tag works

- Every GUI text run is added to `GuiRenderState.addText` synchronously inside the extract call of the
  element that draws it. So a static tag stack is enough: inject HEAD (push) and RETURN (pop) on
  `Hud.extractChat` (chat), `extractOverlayMessage` (action bar), `extractTitle` (title), `extractBossOverlay`
  (boss bar), `extractScoreboardSidebar` (sidebar), `extractTabList` (tab list), `extractSelectedItemName`,
  `extractHotbarAndDecorations`, `extractEffects`; `Screen.extractRenderStateWithTooltipAndSubtitles`
  (screen); `CommandSuggestions.extractRenderState` (suggestions); `ToastManager.extractRenderState` (toast);
  `GuiGraphicsExtractor.extractDeferredElements` (tooltip, which is deferred to the end of the frame).
  The innermost tag wins. `Hud.extractRenderState` resets the stack each frame.
- **Title and subtitle** share `extractTitle`; a run equal to `Hud.subtitle` is tagged subtitle.
- **World text** needs no stack: spike A's submit hooks already know it; name tags come from `submitNameTag`.
- Checks (runs carrying the scene's text, and their tags, Mac):

| Text | Wanted | Seen |
| --- | --- | --- |
| moonpetals (actionbar) | actionbar | actionbar 20 |
| Mana  (actionbar) | actionbar | actionbar 20 |
| The Journey Begins (title) | title | title 1 |
| Chapter One (title) | subtitle | subtitle 1 |
| [Keeper] Line (chat) | chat | chat 5 |
| The Warden Awakens (boss) | bossbar | bossbar 100 |
| Old Keeper (walk) | nametag | nametag 6 |
| Welcome to Riverside (walk) | world | world 6 |
| Old Keeper (walka4) | nametag | nametag 36 |
| Welcome to Riverside (walka4) | world | world 36 |
| /give (typing) | screen | screen 35 |
| Quest Log (tags) | sidebar | sidebar 1 |
| Find the keeper (tags) | sidebar | sidebar 1 |
| probe1 (tags) | tablist | tablist 2 |

- Not exercised: tooltips (no hover in a gated client without a fake cursor) and toasts. The seams are in and
  load; whether a tooltip run lands under "tooltip" is **not measured**.

## What the legibility rule gets wrong live

Nothing it judged offline flipped, but live streams show cases the offline battery never had:

- **Fades are legible from alpha 8.** The title is legible from the first fade in tick to the second last fade
  out tick (shown 68 of 70 ticks). Alpha 8 to about 30 of 255 is barely visible; offline frames were judged at
  rest, never mid fade. A requirement that wants "the title was readable" needs a higher threshold, or the
  record must carry alpha (**inferred** from the fade timing; the record does not carry alpha).
- **Chat lines wrap into several runs.** "[Keeper] Line 16 of the old tale: the river remembers every" and
  " step." are two runs. A needle across the wrap is never found in one run. Offline tokens were short.
- **Ghost completion text counts as typed text.** While typing, the grey completion suffix ("amemode" after
  "/g", "@a" after "/give ") is a separate legible run tagged screen, indistinguishable from what the player
  typed by tag alone.
- **The text cursor blinks.** 5 of 41 records in the typing scene changed only because "_" came or went. Not
  wrong, but a requirement on the input text must ignore it, and it adds records.
- **Boss bar fill is not drawn text.** Progress changes reach the stream only through the facts (client
  state), so "the bar reads 50 percent" is a client state check, as spike A found offline.
- **Text over text** (suggestion box over chat) is still not judged: the suggestion panel is a rectangle with
  alpha below 240, so chat lines under it stay legible. Not exercised with chat present; carried over from A.

## Surprises

- **The frame, not the record, is the cost.** Gated stepping (spike N) drew no frames at all; streaming needs
  one per tick, which doubles the stepped tick. A requirement that needs no perception (pure server work)
  should switch the stream off and keep N's speed.
- **The barrier echo waits for the gate's park.** N's wake mixin unparks the render thread only for step
  pings; a barrier waits up to the 2 ms park. Waking on every ping would take about 1 to 2 ms off the barrier
  echo (**inferred**).
- **A tick that builds terrain makes its record late.** The first frame after the walk scene placed about 800
  blocks took 55 ms (section compile), so that tick's record arrived 119 ms after the tick. Later ticks: 7 ms.
- **A barrier frame also shows packets that arrived just after the barrier**, because the client handles all
  queued packets at the head of its loop. The echo still means "everything before it is in the record"; it
  can mean more.
- **A4 pixel counts make every walking tick a new record** and need step grants held for two extra frames per
  entity. Asking for A4 only when a requirement asks "is it visible", not in the stream, keeps the stream
  cheap.

## Running it

```sh
cargo xtask heavy -- bash -c "cd prototypes/game-verification && ./gradlew -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar :step-agent:jar"
python3 orchestrator/stream.py run --label mac            # all scenes and 1000 typical requirements
python3 orchestrator/stream.py report runs/stream-mac-<t>  # tables from a run directory
```

Evidence: `runs/stream-mac-*/report.json` and `stream.jsonl` (local, not committed); the runner's artifact
`stream-stream-vulkan-X64-0` of run 42336338774.
