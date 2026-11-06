# G: how an in-game requirement reads

A paper spike: the same six scenarios written in three styles, plus where the requirement's logic runs.
Nothing was built or run. Every framework name below is a draft; every v1 name beyond the one action,
one event and one trigger relation is **assumed** and listed under [Assumptions](#assumptions).

## Answer

- **Recommend G1 windows as the surface, with the run's timeline (G3) open for facts about a path**:
  order, gaps, motion. G2 is not needed.
- **Run the requirement's logic in a test JVM. The client streams what its player perceived, in loop
  order, with the window barrier inside the stream.** Paper and the client run no requirement code.
- Why G1:
  - A window in ticks is the one thing the evidence forces on every check (C: 95 of 95 wrong fast
    fails; E: E3t is the only verdict never wrong). G1 makes it the syntax, so it cannot be forgotten.
  - The window anchors at the stimulus, visibly. Several players and an absence share one window.
  - A pass is decided the moment the facts hold. Only `never` waits out its window.
- Why not G2 alone: each await anchors at the line before it, so a 12 tick fade checked after a 3 tick
  await really allows 15. An absence on a second player needs `launch`, or it checks the wrong span.
  G2 is G1 with one fact per window and a hidden anchor.
- Why not G3 alone: every passing requirement pays its whole recording, unless it adds `until`, which is
  G1 again. "Seen" for an entity needs A4 while the frame exists, so subjects must be named before the
  run anyway. Goldens must be captured live too.
- **All three styles fit one mechanism** (below). The choice is surface syntax, so mixing G1 with a
  timeline costs no second engine.

## One mechanism under every style

1. The test JVM sends the stimulus (player input to the client, or a probe call to Paper) and asks Paper
   for a barrier. That barrier anchors the window.
2. The client sends a record each loop where perceived state changed: A2 facts (what was drawn, alpha,
   position), A4 for named subjects only, camera pose per frame while a ride is watched.
3. Paper's scheduler sends the window barrier after `n` ticks. TCP order puts it in the stream after
   everything sent before it (E3t).
4. The test JVM evaluates facts over the stream: pass when they hold, fail when the barrier arrives
   first. Arbitrary Kotlin works, since nothing runs in the client.
5. On failure the record names the cause from client state (A1): not sent, held but not drawn, drawn
   but covered.

Unmeasured: the size of the change stream. E's perceived state hash suggests changes are rare outside
motion; a ride sends one pose per frame.

## Vocabulary the drafts share

All of this is a draft framework API (**assumed**), identical in every style so only the shape differs.

| Name | Meaning |
|---|---|
| `GameSpec`, `requirement(id, sentence) { }` | A kotest spec; one requirement per block, ids illustrative |
| `load(setup)` | Commits a `Setup` to the test Realm, returns once the Paper engine holds it |
| `player()`, `players(n, ...)` | Warm clients parked in an isolated region of a long lived Paper (C3, R1p) |
| `alice.chat(text)`, `alice.moveTo(pos)` | Player input; returns after the server applied it (barrier) |
| `probe.*` | Probe plugin calls that imitate legacy mechanics v1 lacks |
| `chat(text)`, `title(text)`, `textDisplay(text)`, `dialogue(...)`, `anyChat()`, `anyTitle()` | Perceived things. For chat, "seen" means a new line drawn, not an old line still on screen |
| `sees`, `never sees` | Drawn legibly plus owns visible pixels (A2 and A4); text in the GUI needs A2 only |
| `holds` | Client state (A1). Only for arranging and controls, never the verdict |
| `alice.screen shouldMatchGolden name` | Freeze, pinned knobs, render barrier, capture, exact compare (F) |
| `Int.ticks` | Server ticks; every window is ticks, never wall clock |

Requirements live beside the code they test, for example a `gameTest` source set in
`services/extensions/basic` next to `SimpleMessageActionEntry` (source set name **assumed**).

## Scenario 1: a chat line triggers the message action

Real v1 today. The setup is shared by all styles.

```kotlin
val greeting = setup("greeting") {
    library {
        books.book("village") {
            pages.sequencePage("welcome") {
                val reply = elements.simpleMessageActionEntry("reply") { message = "Welcome, traveller" }
                elements.playerMessageContainsTextEventEntry("greet") {
                    text = "hello"
                    exactSame = false
                    triggers = setOf(reply)
                }
            }
        }
    }
}
```

**G1 windows**

```kotlin
requirement("SEQ-1", "a chat line containing the word answers with the book's message") {
    load(greeting)
    val alice = player()

    alice.chat("well hello there")
    within(10.ticks) {
        alice sees chat("Welcome, traveller")
    }
}
```

Fails: `SEQ-1: window of 10 ticks after alice.chat (SequenceRequirements.kt:14) closed. alice did not see
chat "Welcome, traveller". New in window: chat "<alice> well hello there" at tick 0. Cause: no such line
reached alice's client.`

**G2 await**

```kotlin
requirement("SEQ-1", "a chat line containing the word answers with the book's message") {
    load(greeting)
    val alice = player()

    alice.chat("well hello there")
    alice.awaitSeen(chat("Welcome, traveller"), within = 10.ticks)
}
```

Fails: `awaitSeen(chat "Welcome, traveller") gave up after 10 ticks (SequenceRequirements.kt:15). New since
alice.chat: chat "<alice> well hello there". Cause: no such line reached alice's client.`

**G3 timeline**

```kotlin
requirement("SEQ-1", "a chat line containing the word answers with the book's message") {
    load(greeting)
    val alice = player()

    val run = record(alice, ticks = 10) {
        alice.chat("well hello there")
    }
    run[alice] shouldHaveSeen chat("Welcome, traveller")
}
```

Fails: `alice's 10 tick timeline holds no chat "Welcome, traveller". Timeline: tick 0 chat "<alice> well
hello there". Cause: no such line reached alice's client.` A pass also waits all 10 ticks.

## Scenario 2: a title fades in for one player only

Setup `questComplete` (**assumed** title action): chat "done" shows title "Quest Complete" with fade in
10, stay 40, fade out 10 ticks.

**G1 windows**

```kotlin
requirement("TTL-1", "a title fades in for the player who triggered it and for nobody else") {
    load(questComplete)
    val (alice, bob) = players(2, apart = 3.blocks)

    alice.chat("done")
    within(60.ticks) {                       // the whole show; `never` holds it open all 60
        bob never sees anyTitle()
        within(12.ticks) {
            alice sees title("Quest Complete").translucent() then title("Quest Complete").opaque()
        }
    }
}
```

Fails: `TTL-1: bob saw title "Quest Complete" at tick 4 of the 60 tick window after alice.chat (line 6).
Clip frame 4.` Or: `alice saw title "Quest Complete" opaque at tick 1 with no translucent frame before it.`

**G2 await**

```kotlin
requirement("TTL-1", "a title fades in for the player who triggered it and for nobody else") {
    load(questComplete)
    val (alice, bob) = players(2, apart = 3.blocks)

    val sent = alice.chat("done")
    coroutineScope {
        launch { bob.awaitNeverSeen(anyTitle(), within = 60.ticks after sent) }
        alice.awaitSeen(title("Quest Complete").translucent(), within = 3.ticks after sent)
        alice.awaitSeen(title("Quest Complete").opaque(), within = 12.ticks after sent)
    }
}
```

Fails: `awaitNeverSeen(anyTitle) for bob (line 7): saw title "Quest Complete" at tick 4 after alice.chat.`
Without `after sent`, the second await's 12 ticks start when the first one passed.

**G3 timeline**

```kotlin
requirement("TTL-1", "a title fades in for the player who triggered it and for nobody else") {
    load(questComplete)
    val (alice, bob) = players(2, apart = 3.blocks)

    val run = record(alice, bob, ticks = 60) { alice.chat("done") }
    val shown = run[alice].seen(title("Quest Complete"))
    shown.first().alpha shouldBeLessThan 1.0
    shown.firstOpaque().tick shouldBeLessThanOrEqual 12
    run[bob] shouldNeverHaveSeen anyTitle()
}
```

Fails: `bob's 60 tick timeline holds title "Quest Complete" from tick 4 to 58.` With plain kotest list
matchers instead of framework ones: `expected empty list but was [Seen(...)]`.

## Scenario 3: a packet only display entity, one player only, not through a wall

The display comes from the probe plugin (**assumed**): v1 has no entities yet. The wall case tests the
framework's "seen", so it belongs to the framework's own lying battery, not to a product suite.

**G1 windows**

```kotlin
requirement("ENT-1", "a display shown to one player is seen by them and not by a player beside them") {
    val spot = region.at(0, 1, 4)
    val (alice, bob) = players(2, apart = 1.blocks, lookingAt = spot)

    probe.textDisplay("Guide", at = spot, audience = alice)
    within(5.ticks) {
        alice sees textDisplay("Guide")
        bob never sees textDisplay("Guide")
    }
}

requirement("SEEN-1", "an entity behind a wall is not seen") {
    val spot = region.at(0, 1, 4)
    val alice = player(lookingAt = spot)
    region.fill(region.at(-2, 0, 2), region.at(2, 3, 2), Material.STONE)

    probe.textDisplay("Guide", at = spot, audience = alice)
    within(5.ticks) {
        alice holds textDisplay("Guide")      // control: the client has it, so the absence means something
        alice never sees textDisplay("Guide")
    }
}
```

Fails: `ENT-1: bob saw text display "Guide" at tick 1 (drawn, owns 2210 visible pixels). Cause: the server
sent it to bob.` Or: `SEEN-1: alice saw text display "Guide" at tick 2 (drawn, owns 1840 visible pixels).`

**G2 await**

```kotlin
requirement("ENT-1", "a display shown to one player is seen by them and not by a player beside them") {
    val spot = region.at(0, 1, 4)
    val (alice, bob) = players(2, apart = 1.blocks, lookingAt = spot)

    val sent = probe.textDisplay("Guide", at = spot, audience = alice)
    coroutineScope {
        launch { bob.awaitNeverSeen(textDisplay("Guide"), within = 5.ticks after sent) }
        alice.awaitSeen(textDisplay("Guide"), within = 5.ticks after sent)
    }
}
```

SEEN-1 in G2: `alice.awaitHolds(...)` then `alice.awaitNeverSeen(...)`, 2 lines. Fails as in G1, plus the
line of the await.

**G3 timeline**

```kotlin
requirement("ENT-1", "a display shown to one player is seen by them and not by a player beside them") {
    val spot = region.at(0, 1, 4)
    val (alice, bob) = players(2, apart = 1.blocks, lookingAt = spot)

    val guide = textDisplay("Guide")
    val run = record(alice, bob, ticks = 5, watch = guide) {
        probe.textDisplay("Guide", at = spot, audience = alice)
    }
    run[alice] shouldHaveSeen guide
    run[bob] shouldNeverHaveSeen guide
}
```

`watch` is the honest cost: A4 suppresses one thing in a live frame, so it cannot run after the
recording. Without it the timeline holds "drawn" only, and A2 alone says seen behind a wall (A, scene 1).

## Scenario 4: a smooth camera ride that ends where it should

Setup `gateRide` (**assumed** camera cinematic entry): chat "ride" moves the camera from `start` to `end`
over 60 ticks on a packet only display entity. Smoothness needs frame samples at 60 Hz or more (A, scene
16), so the client renders, at a server rate that leaves at least 3 frames per tick.
`smooth()` and `restsAt` are framework rules, starting from A's measured split: under half the samples
stalled, no frame step over 3 times the median step.

**G1 windows**

```kotlin
requirement("CIN-1", "a camera ride glides along its path and stops at its end") {
    load(gateRide)
    val alice = player(frames = 60.hz)

    alice.chat("ride")
    within(70.ticks) {
        throughout { alice.camera moves smooth() }
        alice.camera restsAt gateRide.end
    }
}
```

Fails: `CIN-1: alice's camera jumped 1.9 blocks between frames 211 and 212 (tick 34), median step 0.09.
Clip frame 212.` Or: `camera came to rest 2.4 blocks short of gateRide.end at tick 41.`

**G2 await**

```kotlin
requirement("CIN-1", "a camera ride glides along its path and stops at its end") {
    load(gateRide)
    val alice = player(frames = 60.hz)

    alice.chat("ride")
    val path = alice.camera.sampleUntil(within = 70.ticks) { it restsAt gateRide.end }
    path shouldBe smooth()
}
```

Fails as G1. `sampleUntil` is a recording: motion forces a timeline into G2.

**G3 timeline**

```kotlin
requirement("CIN-1", "a camera ride glides along its path and stops at its end") {
    load(gateRide)
    val alice = player(frames = 60.hz)

    val run = record(alice, ticks = 70) { alice.chat("ride") }
    val path = run[alice].camera
    path shouldBe smooth()
    path.last().position shouldBeNear gateRide.end
    path.moving().duration shouldBe 60.ticks.plusOrMinus(1.ticks)
}
```

Fails as G1. The ride's duration costs one line here; in G1 it needs a new fact kind.

## Scenario 5: nothing arrives after leaving an area

Setup `shrine` (**assumed** area and repeating reminder): while inside the area the player gets chat "The
shrine hums" every 20 ticks. The first window is the control: without it, a broken book passes.

**G1 windows**

```kotlin
requirement("AREA-1", "leaving the shrine stops its reminders") {
    load(shrine)
    val alice = player(at = shrine.center)

    within(25.ticks) { alice sees chat("The shrine hums") }
    alice.moveTo(shrine.outside)
    within(40.ticks) { alice never sees anyChat() }
}
```

Fails: `AREA-1: alice saw new chat "The shrine hums" at tick 20 of the 40 tick window after alice.moveTo
(line 7). Clip frame 20.`

**G2 await**

```kotlin
requirement("AREA-1", "leaving the shrine stops its reminders") {
    load(shrine)
    val alice = player(at = shrine.center)

    alice.awaitSeen(chat("The shrine hums"), within = 25.ticks)
    alice.moveTo(shrine.outside)
    alice.awaitNeverSeen(anyChat(), within = 40.ticks)
}
```

Fails as G1. This is G2's best case: the requirement is a sequence, and each anchor is the line before.

**G3 timeline**

```kotlin
requirement("AREA-1", "leaving the shrine stops its reminders") {
    load(shrine)
    val alice = player(at = shrine.center)

    val run = record(alice) {
        waitTicks(25)
        mark("left") { alice.moveTo(shrine.outside) }
        waitTicks(40)
    }
    run[alice].before("left") shouldHaveSeen chat("The shrine hums")
    run[alice].after("left").newChat().shouldBeEmpty()
}
```

Fails: `alice's timeline after mark "left" holds chat "The shrine hums" at tick 20.` The control always
waits 25 ticks, and `before("left").seen(...).gaps() shouldAllBe 20.ticks` adds the spacing in one line.

## Scenario 6: a golden frame of a dialogue screen, a clip on failure

Setup `elder` (**assumed** spoken dialogue entry): chat "road?" makes the Elder speak "The road east is
closed.", typed out over 30 ticks. The clip needs no code in any style: the runner reruns a failing
requirement as a demo run with recording on (B), and the sidecar maps the failing window or capture to a
frame.

**G1 windows**

```kotlin
requirement("DLG-1", "the elder's dialogue screen looks as approved") {
    load(elder)
    val alice = player()

    alice.chat("road?")
    within(40.ticks) { alice sees dialogue("Elder", "The road east is closed.").typed() }
    alice.screen shouldMatchGolden "elder-road-closed"
}
```

Fails: `DLG-1: frame differs from golden elder-road-closed in 312 pixels, box (220, 388) to (634, 412).
Golden, new frame and diff attached; clip of the rerun attached.`

**G2 await**

```kotlin
requirement("DLG-1", "the elder's dialogue screen looks as approved") {
    load(elder)
    val alice = player()

    alice.chat("road?")
    alice.awaitSeen(dialogue("Elder", "The road east is closed.").typed(), within = 40.ticks)
    alice.screen shouldMatchGolden "elder-road-closed"
}
```

Fails as G1.

**G3 timeline**

```kotlin
requirement("DLG-1", "the elder's dialogue screen looks as approved") {
    load(elder)
    val alice = player()

    val run = record(alice, ticks = 40) {
        alice.chat("road?")
        waitTicks(35)
        alice.capture("elder")
    }
    run[alice] shouldHaveSeen dialogue("Elder", "The road east is closed.").typed()
    run.frame("elder") shouldMatchGolden "elder-road-closed"
}
```

Fails as G1. The capture freezes the client, so it must happen live; `waitTicks(35)` is a guess that is
wasted when typing is fast and wrong when it is slow. Replacing it with "until typed" is G1 again.

## Costs

Lines are the non blank lines of the six product requirement bodies, without setups, the `requirement`
line, lone closing braces and SEEN-1.

| | G1 windows | G2 await | G3 timeline |
|---|---|---|---|
| Lines | 34 | 32 | 42 |
| Pass cost | Early, at the truth. `never` pays its window | Early. Absences run in series unless launched | Always the whole recording |
| Framework must provide | Window anchored at the last stimulus, nested windows, `never`, `then`, `throughout`, live evaluation over the stream | Same stream; `awaitSeen`, `awaitNeverSeen`, `after` anchors, structured `launch`, a sampler for motion | Recorder, `watch` subjects for A4, live `capture` and `mark`, a query API (`seen`, `first`, `gaps`, `before`, `after`, camera path), matchers that print the timeline |
| Flake risks | Window too short (every style). Little else: the anchor is visible | Hidden anchor at the previous line; a forgotten `launch` checks the wrong span; an await that starts late misses a short fact unless it reads from the stimulus | Fixed `waitTicks` before captures and marks; recording length guessed; a subject not watched is judged by A2 alone |
| Failure reads as | Window, anchor line, the missing or forbidden fact, what was seen, cause | Await line and fact; the anchor must be inferred | Rich with framework matchers, a bare list diff with kotest's own |
| Video | Each window is a chapter; failure is the close frame or the first forbidden frame | Each await is a chapter; same | The timeline is the sidecar; any assertion can point at any tick |
| Goldens | Live call after a window | Live call after an await | Live capture inside the recording, compare afterwards |
| Order, gaps, motion | Needs new fact kinds (`then`, `throughout`) or a timeline | Needs a timeline | Plain Kotlin over data |

Wall clock of the pass cost difference, **inferred** from C (rate 200, about 5 ms per tick): a 10 tick
window passing at tick 1 costs about 5 ms in G1 or G2 and about 50 ms in G3. 500 such requirements:
about 3 s against 25 s.

## Where the logic runs

| | Test JVM, client streams perceived changes | Inside Paper | Inside the client |
|---|---|---|---|
| Latency per step | One loopback hop per stimulus and per streamed change. The spike drivers already ran from a separate process and measured 5 to 10 ms per requirement (C, E) | Arranging is free; every fact still needs a hop from the client | Facts are free; every arrangement needs a hop; a second player's facts need a hop between client JVMs |
| Debugging | Breakpoints are safe: the window is ticks and its barrier sits in the stream, so pausing the test changes no verdict. Ordinary kotest in the IDE | A breakpoint stops the tick; clients time out after about 30 s (**inferred**, vanilla network timeout) | A breakpoint stops rendering and the client loop; Paper kicks after about 30 s (**inferred**) |
| Observes directly | Nothing; all through the stream and probe calls | Server state and Typewriter internals, which invites testing how instead of what | Perceived state, frames, camera per frame |
| Several players | Natural: one place sees every stream | Natural for the server, one hop per client | Awkward: each client sees only itself |
| Edit and rerun | Rerun against the warm Paper and clients | Reload the test plugin, or boot Paper (7 to 9 s) | Restart the client (12 s) |
| Framework holds no Typewriter code | Yes | Weaker: test code lives in the server | Yes |

Recommend the test JVM. The cost is the stream, and it keeps Paper and client free of requirement code.

## Open questions for the developer

1. **Surface style.**
   - G1 windows plus the run's timeline for order, gaps and motion. **Recommended**: early pass, visible
     anchors, and plain Kotlin where windows get awkward.
   - G1 only: every new path fact becomes a framework feature, against "Flexible".
   - G2 await: familiar, best for pure sequences (scenario 5); hidden anchors elsewhere.
   - G3 timeline: most flexible checks, but every pass pays its whole window and captures need guessed waits.
2. **Where the logic runs.**
   - Test JVM with a perceived change stream. **Recommended**.
   - Inside Paper: free arranging, but breakpoints stop the server and internals tempt.
   - Inside the client: free facts, but several players need coordination between clients.
3. **Window anchor.**
   - Implicit: a window opens at the barrier of the last stimulus, with an explicit `after(mark)` to
     override. **Recommended**: short, and matches how the scenarios read.
   - Always explicit: every window names its stimulus. Safer, one more token per window.
4. **Breadth of absence facts.**
   - Broad (`anyChat()`, `anyTitle()`). **Recommended**: catches the wrong text too; per player
     isolation and the cleared chat at start (E) keep unrelated lines out.
   - Specific (`chat("The shrine hums")`): survives unrelated messages, misses a changed text.
5. **Requirements that need frames (rides).**
   - The requirement declares it (`player(frames = 60.hz)`), and the runner groups them at a rate that
     leaves 3 frames per tick. **Recommended**: the need is part of the requirement, and the rate is
     server wide (C), so the runner must know before it starts.
   - The framework infers it from the facts used: nothing to write, but only known once the body runs.
6. **Controls for absence.**
   - The framework refuses a requirement whose facts are all `never` or all `holds`. **Recommended**:
     cheap, and an absence without a positive fact passes on a broken book.
   - Left to review through the `typewriter-testing` skill.

## Assumptions

About v1 (beyond `SimpleMessageActionEntry`, `PlayerMessageContainsTextEventEntry`, `SequenceTriggers`):

- Generated setup accessors `pages.sequencePage`, `elements.simpleMessageActionEntry`,
  `elements.playerMessageContainsTextEventEntry`, by analogy with `pages.fixtureGraphPage` in
  `RealmPresentationSearchRoutesTest.kt:49`; setup filling `placement` with a default.
- A relation field set from setup handles: `triggers = setOf(reply)`.
- A way to publish a setup's Realm content to a running Paper engine and know it arrived (`load`).
- Entries v1 lacks: a title action with fades, a camera cinematic entry on the tick clock, an area with a
  repeating reminder, a spoken dialogue entry with typing. Until they exist, probe plugins imitate them.
- Per player packet only display entities come from the probe plugin.

About the framework: every name in [Vocabulary](#vocabulary-the-drafts-share), the change stream, A4
limited to named subjects, the `smooth()` and `restsAt` rules, and the `gameTest` source set.
