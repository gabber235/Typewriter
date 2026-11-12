# In process window input: results

Throwaway prototype on `proto/gv-input`, cut from `proto/gv-stream`. Question: can the client mod itself send
real window input, so the pool process needs no outside input tool, with the fidelity of spike J?

## Answer

- **Yes. On Linux, XTest called from inside the client (XF) is the way**: libXtst through the foreign function
  API, on an X connection the client opens to its own display. It matched J2 on **all 18 inputs, 100 of 100
  each**, gated and rendered, under stepped ticks, with the same event sequences as J2 (the only differences are
  the typed command and suggestion variants every path shows, J2 included). **On the Mac the way stays J1**
  (`SDL_PushEvent` into the client's own queue); the same J1 code also works on Linux, 100 of 100 on all 18.
- **Recommendation:** XF on Linux CI with **one Xvfb display per client** (the real device path, real focus,
  real grab), J1 on a developer's Mac. Both live in the mod; the pool process sends nothing but commands.
- **4 clients at once, same step:** XF with a display per client: **50 of 50 rounds clean, 0 inputs on the
  wrong client**. J1: 50 of 50 clean on own displays and 50 of 50 on one shared display (it never touches the
  window system). XF on **one shared display is unusable**: every key goes to the one focused window
  (24 of 30 rounds put another client's key on it, 35 foreign events) and the other 3 clients get nothing.
- **XSendEvent to the own window (XS) is not a path.** Keys, buttons and the wheel arrive, but the game ignores
  sent pointer motion (SDL 3 reads motion from XInput 2, which XSendEvent cannot fake), so every aimed input and
  the inventory click fail (0 of 30). It also needs X focus like XTest: on a shared display only the focused
  window got anything.
- **Latency is exact**: every window path (XF, J1, XS) reaches the server **exactly one tick after J2**, 600 of
  600 single shot inputs; the event is handled between ticks and consumed by the next tick. **Cost**: an XF call
  is 0.14 ms median (one X round trip), J1 0.012 ms, J2 0.008 ms; nothing that shows in a stepped tick.
- **Typed suggestions still lose their reply under stepped ticks**, 4 to 6 percent per path (J2 18 of 300, J1
  18 of 300, XF 12 of 300), and **the cause is found**: Paper hands every suggestion request to a 4 thread
  pool, so `/claim h` can reach the vanilla suggestion provider before `/claim `; the provider keeps only the
  last request it was given, answers `/claim ` and drops `/claim h`, and the client ignores an answer for an
  older request. With the pool set to 1 thread: **900 of 900**, 0 reordered. A retry the way a person would
  (Backspace and the last character again after 6 ticks without a list): **600 of 600**.

Machines: the GitHub free runner (`ubuntu-24.04`, AMD EPYC 7763, 4 vCPU, Vulkan on lavapipe, Mesa 25.2.8, one
Xvfb per client unless marked shared). Paper with the step agent and the break clock in ticks; clients gated
(mode 2) unless marked rendered (mode 0); auto stepping (a tick runs as soon as every subject client acked the
last one). Runs [43306835761](https://github.com/gabber235/Typewriter/actions/runs/43306835761) (all rows,
before the first motion fix), [43309694858](https://github.com/gabber235/Typewriter/actions/runs/43309694858)
(XF and cross talk after the fix), [43311267445](https://github.com/gabber235/Typewriter/actions/runs/43311267445)
(J1 cross talk rerun), [43304169507](https://github.com/gabber235/Typewriter/actions/runs/43304169507) (smoke).
The Mac part is under "Mac" below.

## The paths as built

All run inside the client, as one script of steps on client ticks (spike J's engine), on the render thread.

| Path | How an event enters | Focus and grab |
| --- | --- | --- |
| J2 (reference) | the handlers SDL events reach: `keyPress`, `textInput`, `onButton`, `onScroll`, `onMove` | probe or real |
| J1 | `SDL_PushEvent` with the client's window id | probe focus, probe grab |
| XF | `XTestFakeKeyEvent`, `XTestFakeButtonEvent`, `XTestFakeRelativeMotionEvent` (absolute motion with a screen open), then `XSync` | X focus on the own window, grab taken by one XTest click |
| XS | `XSendEvent` of KeyPress, ButtonPress, MotionNotify to the own X window (empty mask, so SDL gets it whatever it selected) | X focus, grab taken by a sent click |
| XSf | as XS | X focus, probe grab (no SDL relative mode) |

The window id comes from SDL (`SDL.window.x11.window`); the display from the client's `DISPLAY`. A typed line is
one key press and release per character for XF and XS, one text event for J1.

## Fidelity: 18 inputs, gated, stepped

"ok" is J's outcome check; "same" counts repeats whose server event sequence equals J2's most common one in the
same rig. J2's own count is its agreement with itself.

| Input | J2 | XF | J1 | XS | XSf |
| --- | --- | --- | --- | --- | --- |
| attack entity | 100, 100 | 100, 100 | 100, 100 | 0, 0 | 0, 0 |
| attack packet only entity | 100, 100 | 100, 100 | 100, 100 | 0, 0 | 0, 0 |
| interact entity | 100, 100 | 100, 99 | 100, 100 | 0, 0 | 0, 0 |
| interact packet only entity | 100, 100 | 100, 100 | 100, 100 | 0, 0 | 0, 0 |
| use, held 10 ticks | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| hotbar scroll | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| number key | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| swap to offhand | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| sneak | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| jump | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| fly up in spectator | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| inventory open, click, close | 100, 100 | 100, 100 | 100, 100 | 0, 0 | 0, 0 |
| walk to a point | 100, 100 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| chat line | 100, 99 | 100, 100 | 100, 100 | 30, 30 | 30, 30 |
| command typed, Enter | 100, 29 | 100, 15 | 100, 34 | 30, 12 | 30, 13 |
| suggestions for `/claim h` | 86, 67 | 95, 55 | 95, 57 | 27, 18 | 25, 19 |
| break leaves | 100, 100 | 100, 100 | 100, 100 | 0, 0 | 30, 0 (wrong block) |
| cancelled break | 100, 100 | 100, 100 | 100, 100 | 0, 0 | 0, 0 |

n is 100 for J2, XF and J1 (XF from run 43309694858, J1 from 43306835761), 30 for XS and XSf. The J2 column is
the XF rig's; the J1 rig's J2 agrees (83 suggestions, otherwise the same). Differences per input:

- **XF, J1:** none in the event sequence. `interact` once shows a stray `PlayerMoveEvent` first, as J2 does once.
  `command` and `suggestions` vary for every path, J2 included: which typed prefixes reach the completer, and
  whether it runs before or after the command, is the server's per tick coalescing (spike J). Jump packet order
  varies for J2 (85 of 100) more than for XF (98).
- **XS, XSf:** every input that needs pointer motion fails (aim, inventory slot); the cursor never moves. With
  the probe grab a break hits whatever block is straight ahead.

### Rendered (gate 0), stepped

| Input | XF (20) | J1 (20) | XS (10) |
| --- | --- | --- | --- |
| all 16 inputs other than command and suggestions | 20 of 20 each, all same as J2 | 20 of 20 each, all same | the aimed and inventory inputs 0, the rest 10 of 10 |
| command | 20, 9 same | 20, 9 same | 10, 5 same |
| suggestions | 17 | 13 | 8 |

Gated and rendered agree, as in spike J.

## Latency and cost

Single shot inputs (use, scroll, swap, sneak, jump, fly), first server event tick minus the server step on which
the client injected:

| Path | Ticks | Where the event was handled | Injection per call, median | Slowest call |
| --- | --- | --- | --- | --- |
| J2 | 0: 600 of 600 | inside the tick | 0.008 ms | 89 ms (once, a GC or JIT pause in the handler) |
| J1 | 1: 600 of 600 | between ticks, next poll | 0.012 ms | 4.9 ms |
| XF | 1: 600 of 600 | between ticks, next poll | 0.139 ms | 5.0 ms |
| XS | 1: 180 of 180 | between ticks, next poll | 0.164 ms | 7.5 ms |

- The client polls SDL at the top of each loop, before `runTick`; an event injected during tick n is handled in
  the next poll and consumed by tick n+1, never later: `XSync` returns only after the X server has queued the
  event for SDL's connection. So window input is one tick behind a direct handler call, the same every time.
- XF's cost is the X round trip per call; a typed chat line (16 characters, 34 events in one call) cost
  0.6 ms. Per input wall time under stepping is the same for XF and J2 (0.008 to 0.05 s median).

## Cross talk: 4 clients, same step

Each client runs at the same server step: number key for its own slot, sneak held 2, 4, 6 or 8 ticks, turn by
15, 30, 45 or 60 degrees, a chat line with its own token. "Wrong" counts events that reached another client's
player; "lost" counts checks a client's own player failed.

| Path | Displays | Rounds clean | Inputs on the wrong client | What each client got |
| --- | --- | --- | --- | --- |
| XF | one Xvfb per client | **50 of 50** | 0 | all 4: slot, sneak for exactly hold + 1 ticks, turn to 0.01 degrees, chat |
| J1 | one Xvfb per client | **50 of 50** | 0 | all 4, as XF |
| J1 | one shared Xvfb | **50 of 50** | 0 | all 4, as XF |
| XF | one shared Xvfb | 0 of 30 | **35** (24 rounds) | only the focused client got keys, including other clients' number keys and an overlapped sneak of 2 to 4 ticks; 3 clients got nothing; no turns |
| XSf | one Xvfb per client | 0 of 30 | 0 | keys and chat right, turns 0 |
| XSf | one shared Xvfb | 0 of 30 | 0 | only the focused client got its keys; 3 clients got nothing |

- **What XF needs:** its own X display per client. XTest acts on the display's focus and pointer, so on a shared
  display one window wins focus and one wins the pointer grab (2 of 4 clients never got a grab). A display per
  client costs one Xvfb process each; nothing else is shared.
- **What J1 needs:** nothing; it writes into its own process's SDL queue. Its limits are J's: probe focus and
  probe grab instead of the window system's.
- **XSendEvent's targeting does not help:** SDL drops key events for a window without keyboard focus, so XS
  needs the same per client display as XF, and it still cannot move the pointer.
- **Every 4 client rig started its scripts on the same step** (all rounds). One of eight 4 client rigs stalled at
  setup (the stepping deadlock below, second form); the rerun was clean.

### The first motion after a grab

The first cross talk runs turned 0 degrees on every XF client (50 of 50) while XF aimed fine in the fidelity
runs. The game drops the first mouse motion after it takes the grab (`MouseHandler.ignoreFirstMove`); after a
chat screen closes with Enter the flag was set in every round (`ifm` true 50 of 50, one motion seen, turn 0). A
physical mouse sends many small motions, so a person never notices. In process the driver can read the flag:
when it is set, XF sends one 1 pixel motion first. After that 50 of 50 turned exactly. J1 sends a zero motion
first (spike J's fix), which the flag eats instead.

## Typed suggestions under stepped ticks

`suggest` types `/claim h` and waits up to 40 ticks for `home` in the drawn list. Each repeat sends two requests
(`/claim ` and `/claim h`). Gated unless marked.

| Paper's suggestion pool | Retry | J2 | J1 | XF | Requests reordered, of the failures |
| --- | --- | --- | --- | --- | --- |
| 4 threads (default) | none | 282 of 300 | 282 of 300 | 288 of 300 | 46 of 48 |
| 4 threads, rendered | none | 94 of 100 | 93 of 100 | 94 of 100 | 17 of 19 |
| **1 thread** | none | **300 of 300** | **300 of 300** | **300 of 300** | 0 reordered at all |
| 4 threads | after 6 ticks | **200 of 200** (13 retried) | **200 of 200** (15) | **200 of 200** (6) | |

- **Why:** `handleCustomCommandSuggestions` hands each request to `TAB_COMPLETE_EXECUTOR`, a fixed pool of 4
  threads, which fires `AsyncTabCompleteEvent` and then calls `ServerCommandSuggestionsProvider.request`. The
  provider keeps one request (`lastRequest.getAndSet`) and answers it on the next tick. When the second request
  passes the first inside the pool, the provider is left holding `/claim `: the server runs the completer for
  `/claim `, sends that answer, and the client, which asked for `/claim h` last, ignores it. In every failure
  the completer ran only for `/claim ` and an answer for `/claim ` was sent. In 46 of 48 failures the
  `AsyncTabCompleteEvent` order already showed the swap; in the other 2 the swap happened between the event and
  `request` on the pool threads (**inferred**, the order inside the pool is not logged).
- **Stepping does not help:** the pool runs on wall clock, outside the step policy, and both requests arrive
  between the same two ticks. Spike J's per tick budget explanation was half of it: the budget makes the provider
  keep one request, the pool decides which.
- **For the framework:** a typed suggestion is judged by what the player sees, with a retry the way a person
  would; or the test server runs Paper's suggestion pool with 1 thread (a reflection call, `in.tabpool`), which
  removes the reorder without changing what the client sends.

## Mac

The Mac run did not happen: the local build could not start because `devenv shell` hung on this machine for
every session (other repositories' shells hung the same way), and the rules allow Gradle only through
`cargo xtask heavy` inside it. On the Mac the in process path is J1, the path spike J already measured there
(200 of 200 against J2 on every input); this prototype adds nothing Mac specific to it. XF and XS need an X
server and do not apply to the Mac. **Open:** J1 under stepped ticks and the 4 client cross talk on the Mac.

## Surprises

- **The step policy deadlocked on its first tick with more than one client:** the other clients' acks started
  empty, so the first tick waited for an ack that only a tick could cause. Seeding every subject's ack with the
  tick stepping starts on fixed it.
- **XSendEvent click took the real grab** (the game grabs on its own click handler), but SDL then reads motion
  only from XInput 2 raw events, which XSendEvent cannot produce.
- **Typing in one step sends only two suggestion requests**: all characters arrive between two ticks, and the
  client asks only for the word under the cursor at each edit that changes it.

## Rerun

From `prototypes/game-verification`, after `run.py prepare` and the build (`:probe-mod:writeClientLaunch
:probe-mod:jar :probe-plugin:jar :step-agent:jar`):

```
python3 orchestrator/inproc.py fid --paths J2,XF --setup real --ops all --n 100 --gates 2
python3 orchestrator/inproc.py cross --path XF --setup real --n 50 --display own
python3 orchestrator/inproc.py sug --paths J2,J1,XF --setup real --n 300 --pool 1
python3 orchestrator/inproc.py ci --row fidxf --backend vulkan     # what one CI matrix row runs
```

CI: `.github/workflows/gv-input-prototype.yml` runs `inproc.py ci --row <row>` for each row of `CI_ROWS`; traces
are in the artifact under `inproc/`, one gzipped JSON line per input.

## Reuse

- **Client** `probe-mod/.../input/X11.java`: the libX11 and libXtst bindings (own connection, keycodes, XTest key,
  button, relative and absolute motion, focus, `XSendEvent`, window origin). `Input.java`: `XTestKeys` (with the
  first motion nudge), `Sends`, the `Timed` wrapper (inject step and cost), `HandledMixin` (when an event reaches
  the handlers), `atStep` (every client starts on one step), `in.xsetup`, the `cross` op, the suggestion retry.
- **Plugin** `Cross.java` (per player event log), `N.java` (several subjects in lockstep, seeded acks),
  `in.tabpool` (Paper's suggestion pool size), `st` and thread name on every log line.
- **Orchestrator** `inproc.py` (`fid`, `cross`, `sug`, `ci`, per display Xvfb hooks).
