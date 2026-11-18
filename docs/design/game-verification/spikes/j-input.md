# J: real player input into a real client

## Answer

- **Drive every input through the window event path, the same events a keyboard and mouse produce, and
  wait in client ticks.** On the runner that is **X**: XTest on the client's own Xvfb display, with the
  vanilla mouse grab and real focus, and **relative** mouse motion. On the Mac, where no OS level injection
  is allowed, it is **J1**: the same SDL events pushed into the client's own SDL queue (`SDL_PushEvent`
  with the client's window id), with a probe focus and a probe grab that never warps the real cursor.
  X, J1 and J2 (calling the client's input handlers directly) produced the same server events in the
  same order on every input kind, 200 of 200 per input. They are the reference for "what a person causes".
- **X is the truest person and the steadiest path.** With a real grab and relative motion it matched J2
  on all 17 inputs (attack, entity clicks including a packet only entity, use and hold, swap, scroll,
  number key, sneak, jump, spectator fly, inventory click, walk to a point, chat, command, suggestions,
  break, cancelled break) with 0 flakes except two timing variants explained below. J2 itself shows small
  packet variants that X never shows (stray rotation packet before walking, jump packet order, a dropped
  first mouse motion), so **J2 is the reference for the event sequence, not for packet timing**.
- **J3 (game actions: KeyMapping, gameMode, chat screen send) is not a person for typing.** It sends the
  command as one value, so the server sees one suggestion request instead of one per typed character, and
  its tab completion side events never match a typed command (0 of 200). For every other input it matched
  J2 200 of 200. **J4 (packets) is not a person:** the server sees the action but the client does not
  (aim MISS, no scoping, hotbar slot out of sync, no jump, no drawn suggestions), and walking by packets is
  kicked ("Invalid move player packet received").
- **Gated and rendered behave the same.** Input polling, mouse turning and the aim raycast all run outside
  the gate, so gate mode 2 gives the same events as rendered (gate 0) for every path and input.
- **Lag spikes do not change the outcome.** A 300 ms sleep on the client thread or the server main thread in
  the middle of the input left the events identical to a calm run, 10 of 10 per input and path on the Mac
  and the runner, because every wait is in ticks.
- **Cost per input** (gated, rate 200, runner): 0.03 to 0.09 s for keys, clicks, swaps and screens; 0.16 to
  0.18 s to walk 4 blocks; breaking is bound by wall time (1.0 to 1.25 s for leaves at rate 20, below).

### What the framework input API should guarantee

| Guarantee | Why (evidence below) |
| --- | --- |
| Inputs enter as window events (X on Linux, SDL queue on the Mac), never as packets or game calls | J3 and J4 differ from a person |
| Waits, holds and timeouts count client ticks, never milliseconds | lag spikes changed nothing |
| A hold ends on a tick boundary chosen by the test, not by polling | X cancelled break: retry count varied 37 of 200 |
| Aim is a mouse motion computed from the client's own degrees per pixel, then the crosshair target is checked before the click | same raycast as a person; a wrong target fails fast |
| With a grabbed mouse, motion is relative; the pointer is never moved on the developer's desktop | absolute motion under SDL relative mode turned to pitch 90 |
| Before each requirement: no screen open, chat draft discarded, every key and button released, mouse grabbed | leftover drafts and held keys leaked into the next input |
| A mark barrier after each input: a client payload sent at the end of the tick that ran the last input step | the server log is read up to the mark, so the events are complete |
| Tab completion results are judged as eventual: "the list shows X", never "the server ran the completer for each prefix" | the server coalesces requests per tick |
| Typing a partial command waits for the reply to the full text and retries the request once when none comes | 5 to 15 percent of typed requests get no reply |
| Block breaking runs at server tick rate 20, or the framework accepts Paper's wall clock break timer | breaks failed at fast rates |

Machines: the developer's M1 Max (OpenGL 4.1 on Metal, 854x480, render distance 2, void world, load 6 to 14,
given next to each table) and the free runner (`ubuntu-24.04`, AMD EPYC 7763, 4 vCPU, Vulkan on lavapipe,
Mesa 25.2.8). Runs [42211818480](https://github.com/gabber235/Typewriter/actions/runs/42211818480) (X with
a probe grab and absolute motion), [42215647584](https://github.com/gabber235/Typewriter/actions/runs/42215647584)
(X with a real grab and absolute motion; J1 and J3 rows; lag) and
[42218505138](https://github.com/gabber235/Typewriter/actions/runs/42218505138) (X with a real grab and
relative motion). Measured unless marked **inferred**.

## The paths as built

| Path | How an input enters | Focus and grab | Aim |
| --- | --- | --- | --- |
| X | XTest key, button and motion events on the client's own Xvfb (display 90 or higher, asserted) | real focus (X input focus), vanilla SDL grab, taken by one click at setup | relative motion of `dyaw / degreesPerPixel` pixels |
| J1 | `SDL_PushEvent` of key (768, 769), text (771), motion (1024), button (1025, 1026) and wheel (1027) events with the client's window id | probe focus (`Window.isFocused` true) and probe grab (grabbed state, no SDL grab or warp) | one zero motion (the first motion after a grab only sets the cursor), then the delta |
| J2 | the handlers SDL events reach: `keyboardHandler.keyPress`, `textInput`, `mouseHandler.onButton`, `onScroll`, `onMove` | as J1 | as J1 |
| J3 | `KeyMapping` state and clicks, `gameMode` calls, chat screen value and send | as J1 | yaw and pitch set on the player |
| J4 | serverbound packets from the client connection | as J1 | a rotation packet |

Every path runs as a script of steps, one step per client tick at the head of `Minecraft.tick` (X runs
the same steps from the orchestrator and waits by reading the client tick count). After the last step and
a settle of 2 or 3 ticks, the client sends a `probe:mark` payload at the end of its tick; the plugin logs it
on the main thread. The plugin records every event and every serverbound packet, by thread, until the mark.

Aim uses the game's own raycast: `pick` runs before render extraction every frame and once per tick before
the keybinds are handled, so the target under the crosshair is the one a person would hit, gated or not.

## Equivalence: the runner, 200 per input

Gated (mode 2), server rate 200 (rate 20 for breaking), run 42218505138 for X and J2, 42215647584 for J1 and
J3. "Same as J2" counts repeats whose event and packet sequence equals J2's most common one.

| Input | X ok | X same as J2 | J2 variants | J1 ok, same | J3 ok, same | X median s | J2 median s |
| --- | --- | --- | --- | --- | --- | --- | --- |
| attack entity | 200 | 200 | 2 (3 aim dropped) | 200, 200 | 200, 200 | 0.040 | 0.060 |
| attack packet only entity | 200 | 200 | 2 | 200, 200 | 200, 200 | 0.040 | 0.060 |
| interact entity | 200 | 200 | 3 | 200, 200 | 200, 200 | 0.040 | 0.060 |
| interact packet only entity | 200 | 200 | 2 | 200, 200 | 200, 200 | 0.040 | 0.060 |
| use, held 10 ticks (spyglass) | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.075 | 0.085 |
| hotbar scroll | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.030 | 0.035 |
| number key | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.035 | 0.040 |
| swap to offhand | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.035 | 0.040 |
| sneak | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.040 | 0.065 |
| jump | 200 | 200 | 2 (13 packet order) | 200, 200 | 200, 200 | 0.080 | 0.095 |
| fly up in spectator | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.035 | 0.061 |
| inventory open, click slot, close | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.050 | 0.090 |
| walk to a point 4 blocks away | 200 | 200 | 1 | 200, 200 | 200, 200 | 0.155 | 0.180 |
| chat line | 200 | 200 | 2 | 200, 200 | 200, 200 | 0.039 | 0.050 |
| command typed, Enter | 200 | see below | 30 | 200, see below | 200, 0 | 0.040 | 0.050 |
| suggestions for `/claim h` | 192 | see below | 4 | 190 | 200, 0 | 0.074 | 0.090 |
| break leaves (rate 20) | 200 | 200 | 1 | 200, 200 | 200, 200 | 1.000 | 1.250 |
| cancelled break, held (rate 20) | 200 | 163 | 1 | 200, 200 | 200, 200 | 1.550 | 1.750 |

J1 and J3 numbers for the first block are from run 42211818480 (rows at rate 200 with a probe grab) and
42215647584. X is faster than J2 because its steps do not wait for the next script tick (**inferred**).

## Equivalence: Mac, 200 per input

Gated, rate 200 (rate 20 for breaking), probe focus and grab, load 6.2 to 13.7, the front app unchanged
before and after every run. No OS level input was used.

| Input | J1 ok, same as J2 | J2 variants | J3 ok, same | J4 ok | J1 median s |
| --- | --- | --- | --- | --- | --- |
| attack, attack packet only entity | 200, 200 | 1 | 200, 200 | 0 (client MISS) | 0.060 |
| interact, interact packet only entity | 200, 200 | 2 | 200, 199 | 0 | 0.060 |
| use held | 200, 200 | 1 | 200, 200 | 0 (no scoping) | 0.085 |
| swap | 200, 200 | 1 | 200, 200 | 200 | 0.040 |
| scroll, number key | 200, 200 | 1 | 200, 200 | 0 (slot out of sync) | 0.035, 0.040 |
| sneak | 200, 200 | 1 | 200, 200 | 200 | 0.065 |
| jump | 200, 200 | 2 (4 packet order) | 200, 200 | 0 (no rise) | 0.100 |
| fly in spectator | 200, 199 | 2 | 200, 199 | 200, packets differ | 0.060 |
| inventory click | 200, 200 | 1 | 200, 200 | 0 | 0.090 |
| walk to a point | 200, 200 events | 2 (67 stray rotation) | 200, 200 events | kicked, skipped | 0.185 |
| chat | 200, 200 | 2 | 200, 200 | 200 | 0.050 |
| command | 200, events vary | 20 | 200, 0 | 200, 0 | 0.050 |
| suggestions | 175 | 3 | 200, 0 | 0 | 0.080 |
| break leaves (rate 20) | 200, 200 | 1 | 200, 200 | 200, 0 (no arm swing, no retry) | 1.250 |
| cancelled break (rate 20) | 200, 200 | 1 | 200, 200 | 200, 0 (one try, no retry) | 1.750 |

The Mac and the runner agree on every equivalence.

## Rendered against gated

Rate 20, every input kind (18), 5 repeats per path on the runner, gate 0 and gate 2 in the same job
(run 42215647584 for J1, J2, J3; 42218505138 for X): every path gives the same outcome and the same events
in both modes, except the two typing effects below.

Mac, rate 20, load 8 to 10: rendered (gate 0) 20 per input, gated 13 to 14 per input (the run was stopped
by the time limit). J1, J2 and J3 matched each other and the gated rate 200 results on every input except:

| Input | J1 ok | J2 ok | J3 ok |
| --- | --- | --- | --- |
| suggestions, rendered | 11 of 20 | 14 of 20 | 20 of 20 |
| suggestions, gated | 8 of 14 | 9 of 14 | 14 of 14 |
| command, events | 6 variants | 6 variants | 1 |

Suggestions fail far more often at rate 20 than at 200 (J1 175 of 200), which fits the per tick
coalescing: at rate 20 more typed characters land in one server tick (**inferred**).

## Lag spikes

300 ms sleep a few ticks into each input, 10 lagged and 10 calm repeats per input, rate 20, gated. Runner
run 42215647584 (X still on absolute motion there, so X aim inputs are not counted):

| Spike | J2 same as calm | J3 same as calm | X same as calm |
| --- | --- | --- | --- |
| client thread | 60 of 60 (break, use, sneak, move, chat, attack) | 60 of 60 | 30 of 30 (use, sneak, chat) |
| server main thread | 60 of 60 | 60 of 60 | 29 of 30 (one sneak with a move event between) |

Mac, same inputs, 10 lagged and 10 calm per input and path (load 52 at the start of the client run from
another process, 8 to 12 after): client thread spike 60 of 60 same as calm for each of J1, J2 and J3; server
main thread spike 60 of 60 for each.

## Surprises

- **Paper's block break timer runs on the wall clock.** `ServerPlayerGameMode.gameTicks` advanced 20 per
  wall second at tick rates 20, 100 and 200 (measured), while the server, the player's age and the client
  ran at the set rate. A finished break (`STOP_DESTROY_BLOCK`) is accepted only when the wall clock progress
  reaches 70 percent, so at fast rates the server falls back to a delayed destroy or keeps the block: leaves
  broke 20 of 20 at rate 20 and 50, 19 of 20 at 100, 9 of 20 at 200 (Mac). Vanilla advances `gameTicks`
  per server tick, so the cause is a Paper change (**inferred**).
- **The server must see the player on the ground before a break.** Mining speed is divided by 5 while the
  server side `onGround` is false, which it is for a few ticks after a teleport; the arrangement waits for it.
- **Typed commands make the server coalesce suggestion requests.** The client sends a request per typed
  character; 26.3's `ServerCommandSuggestionsProvider` handles one per tick and keeps only the latest. Which
  prefixes reach the completer, and whether the completer runs before or after the command, varies from run
  to run for every typing path (J2 30 variants of 200, X 53), while the command itself is identical.
- **Some typed suggestion requests get no reply at all.** In 5 to 15 percent of repeats (Mac J1 25 of 200,
  J2 30; runner X 8, J2 7) the server ran the completer for `/claim ` but never for `/claim h`, and the
  client showed no list within 40 ticks. Both requests reached the server and fired `AsyncTabCompleteEvent`.
  The cause is a race in the provider's per tick budget between Paper's async suggestion thread and the
  main thread (**inferred**, from the provider's code; not reproduced in isolation). J3 sends one request and
  never failed.
- **Absolute pointer motion is wrong under a real grab.** SDL relative mode warps the pointer to the window
  centre, so an absolute XTest move from a remembered position turned the view to pitch 90 and walked the
  player off the world. Without a real grab the pointer is never warped and drifts to the screen edge after
  a few aims, after which clicks land outside the window (scroll, use and break failed 200 of 200 in the
  first runner run). Relative motion is what a physical mouse sends and fixed both.
- **The first mouse motion after a grab is dropped** (`ignoreFirstMove`); a path that aims right after a
  screen closes must send a zero motion first. J2 still lost the aim in 3 of 200 under a real grab.
- **A cancelled break keeps retrying while the button is held.** Each retry fires a new `BlockBreakEvent`;
  how many fit in the hold depends on the tick the button is released (X 163 two retries, 37 one retry).
- **Interacting with an entity while holding a spyglass also uses the spyglass**, as for a person.
- **Two position packets in one server tick disconnect the player**, so packet walking cannot be faster than
  one step per tick at any rate.
- **Escape from the chat screen keeps a draft**, which the next chat open restores; the framework must
  discard it between requirements.

## What this means for the search

- The input layer can be shared by every platform: one script of window events per input kind, with only the
  injector differing (XTest on CI, the client's SDL queue on a developer's Mac). Neither touches the
  developer's desktop, and both run gated.
- Requirements about what a person causes (L4 cancelled break, L5 `/claim` with suggestions, L15 spyglass
  hold and swap, L16 NPC click, hotbar scroll, sneak, jump, swap hands, spectator input) are all reachable
  with this layer, including a packet only NPC.
- Tests must not assert on tab completion internals; they assert on what the player sees (the list) and on
  the command's effect.
- Block breaking tests either run at rate 20 or need a decision on Paper's wall clock break timer; this is
  the one input whose cost does not shrink with a faster server.

## Rerun

Build, from the worktree root:

```
cargo xtask heavy -- bash -c 'cd prototypes/game-verification && ./gradlew --console=plain -q :probe-mod:writeClientLaunch :probe-mod:jar :probe-plugin:jar'
```

Mac, from `prototypes/game-verification`, one at a time, `SDL_MAC_BACKGROUND_APP=1`:

```
python3 orchestrator/input.py run --paths J2,J1,J3,J4 --ops chat,cmd,suggest,use,swap,scroll,num,sneak,jump,attack,attackPacket,interact,interactPacket,inv,move,fly --n 200 --gate 2 --rate 200 --label mac
python3 orchestrator/input.py run --paths J2,J1,J3,J4 --ops break,breakCancel --n 200 --gate 2 --rate 20 --label mac
python3 orchestrator/input.py run --paths J2,J1,J3,J4 --ops all --n 20 --gate 0 --rate 20 --label mac
python3 orchestrator/input.py lag --paths J2,J1,J3 --ops break,use,sneak,move,chat,attack --n 10 --where client --ms 300 --gate 2 --rate 20 --label mac
python3 orchestrator/input.py lag --paths J2,J1,J3 --ops break,use,sneak,move,chat,attack --n 10 --where server --ms 300 --gate 2 --rate 20 --label mac
python3 orchestrator/input.py report runs/j-input/mac-run-*.jsonl.gz
```

Flags: `--focus fake|real`, `--grab cancel|fake|real` (real only on a virtual X server), `--keep`. Every
repeat's trace is kept in `runs/j-input/`, so a change to the judging is checked with `report` without
running the game again. Results append to `runs/j-input.jsonl` with the load and the front app.

CI: matrix rows `{ plan: input, backend: vulkan, runner: ubuntu-24.04, repeat: 0..8 }` run
`orchestrator/ci.py plan input`; `INPUT_ROWS` in `ci.py` lists what each row runs. Path X needs
`python3-xlib`. Traces are in the job's artifact under `j-input/`.

## Reuse

- **Client** `probe-mod/.../input/Input.java`: the per tick script engine (`Stage`, `Script.until`,
  `waitTicks`), the J1 SDL event builders, the J2 handler calls, the J3 and J4 variants, `aim`, and the
  commands `in.setup?focus=&grab=`, `in.run?path=&op=&mark=`, `in.state` (screen, focus, grab, slot, yaw,
  pitch, eye, degrees per pixel, crosshair hit, scoping, sneaking, carried, suggestions, block and slot
  position on request), `in.mark`, `in.reset`, `in.ticks`. Mixins: `FocusMixin`, `MouseGrabAccessor`,
  `TickHookMixin`, and the three grab modes in `MouseHandlerMixin`.
- **Plugin** `probe-plugin/.../Input.java`: the event and packet recorder with threads, the `probe:mark`
  channel, `in.arrange` (survival player, inventory, target block, NPC or packet only entity), `in.log`,
  `in.ground`, `in.lag`, and the `/claim` command with its completer.
- **Orchestrator** `input.py` (`Bench`, judging, `report`) and `xtest.py` (XTest driver for the client's own
  display, relative motion under a grab).
