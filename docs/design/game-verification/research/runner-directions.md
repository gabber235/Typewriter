# Runner directions: A, B and C

Condensed from a planning draft of 2026-11-07 ("directions for writing and running requirements", input for the
framework plan). Every framework name is a proposal; Typewriter names that did not exist yet were marked **assumed**.
testBalloon references are to the 1.1.0 sources. Decision: **C picked**, A and B dropped (record tries
`runner-a-and-b`, `runner-c-testballoon`). P2 (`../spikes/p2-testballoon-runner.md`) then proved C's mechanics.

## Answer

Three directions for how a developer declares, runs and extends an in game requirement. The check style (G1,
`within(n.ticks)`) is identical; they differ in who discovers and schedules a requirement, where the extension hooks
live, and how a new perceived kind is added.

| | Short name | Who discovers | Who schedules and retries | Who writes `TestRun` |
|---|---|---|---|---|
| **A** | Tests in a pool | testBalloon | testBalloon runs every test at once; each body claims clients from a framework pool at run time | A framework report beside testBalloon |
| **B** | Requirement values | The framework (class scan) | A framework scheduler that sees every requirement before it starts | The scheduler |
| **C** | Declared in testBalloon, scheduled by the framework | testBalloon | The framework scheduler; each testBalloon test only mirrors the final verdict | The scheduler |

- **A dropped: a flaky requirement shows as passed** in testBalloon and the IDE; only `TestRun` says flaky. Needs are
  known only when the body claims, so the runner cannot group frame requirements or plan the restart lane before the
  run.
- **B dropped: it loses the IDE gutter and test filters.** It is a second test model (no test tree, no testBalloon
  fixtures, one requirement through a run configuration with `--only`) that strains the project idiom that tests use
  testBalloon, and it needs discovery, filter, CLI and reporting built first.
- **C picked: requirements are registered in a testBalloon suite with a needs header.** testBalloon keeps discovery,
  selection, the IDE and assertions; the framework scheduler keeps claims, attempts and `TestRun`. The testBalloon
  result is only a mirror, so nothing in it can drift from `TestRun`.

## Shared by every direction

Fixed by decisions:

- Every check sits in `within(n.ticks)`, anchored at the last player action or probe call; order, gaps and motion are
  read from the attempt's recorded timeline after a window.
- `never` is broad; a requirement with no positive `sees` check is refused (not retried).
- Requirement code runs in a test JVM; the client streams what its player perceived, loop by loop, with the window
  barrier inside the stream. The runner steps Paper ticks (spike N, N2).
- Pool of 4 warm clients; a full wipe of each claimed player before it is handed out; restart requirements on a Paper
  of their own; retry later, up to 3 retries (`rerun_failures: 4`).
- The framework holds no Typewriter code. Typewriter plugs in a done signal, a wipe and content arranging; a panel
  stimulus comes with layer 9.

The check surface (short form of the draft's types): `Ticks`, `Frames` (`None` gated facts, `Still` gated with frames
on demand, `Motion(hz)` rendering), `Mark` (the Paper tick at which a stimulus took effect) and `LossyMark` (a
stimulus the game may drop, such as typed tab suggestions, which `repeat` resends), `GamePlayer` (`useBlock`, `chat`,
`typeInChat`, `rejoin`, `screen`), `GameServer` (`call`, `stimulus`, `kill`, `boot`), `Perceived<T>` over one streamed
`LoopView`, `WindowChecks` (`sees`, `never`, `then`, `throughout`), `timeline(player).since(mark).spans(fact)`,
`shouldMatchGolden`, and the entry `within(window, after?, checks)`.

`within` is defined as: anchor at `after` or the attempt's last Mark; ask Paper for a barrier at the end tick; the tick
driver steps while any attempt has an open window and waits at each step for every claimed client's ack and for every
claimed subject's work to be quiet (so the decided fail rule is carried by the step); a positive passes on the first
loop it holds, a `never` fails on the first loop it holds, `throughout` fails on the first loop it does not hold; a
window fails when the barrier arrives with a positive open; subject work busy for 1 s of wall clock fails as hung
naming the work; a lossy input is resent every 2 ticks while its positive is open; no positive `sees` anywhere means
`RequirementRefused`.

Paper side interface (same in all three): `SubjectWork` (`busy(player)`, `describe(player)`, registered through
Bukkit's ServicesManager) and `GameProbes.register(name, handler)` for test JVM calls handled on the main thread. The
framework's own Paper plugin wipes the 17 vanilla and Paper kinds from spike K and fences chat.

`TestRun` additions every direction needs: `Runner.game` (`test_run.skir:66`), `ArtifactKind` golden, frame and golden
diff (`:98`), and a tick on `Step` (`:50`, which has only `at_millis`). `results.rs:85` already turns "failed, then
passed" under `RerunFailures` into `Flaky`.

Found while writing the drafts (apply to every direction):

- `player never sees anyTitle()` does not compile: Kotlin infix calls chain left to right. Write
  `outsider.never sees anyChat()`.
- A player's chat line goes to every online player, so on a shared Paper one attempt's chat input breaks every other
  attempt's `never sees anyChat()`. The framework plugin must limit the viewers of a claimed player's chat to that
  attempt's players.
- A broad `never sees anyActionBar()` cannot be used when the subject is itself an action bar: use
  `anyActionBar().except(actionBar(ours))`.
- Coverage per attempt is shared on the shared Paper (JaCoCo probes are per JVM, spike D). Attributing a span's lines
  to every attempt in it makes "touched" too large, never too small: more clips, never a missing one.
- Clips need a recorded rerun (spike B). All three directions record retries 2 to 4, so a flaky pass has a clip too.

## Direction A: tests in a pool

A requirement is a testBalloon test. testBalloon discovers, selects and starts every test of the game compartment at
once; each body suspends at its first claim in a framework owned pool and states its needs by calling `players(3)`,
`player(frames = ...)` or `ownPaper()`.

```kotlin
open class GameCompartment(hooks: List<GameHooks>) : TestCompartment(
    name = "Game",
    testConfig = TestConfig
        .invocation(TestConfig.Invocation.Concurrent)  // every requirement starts and waits at its claim
        .testScope(isEnabled = false)                  // windows count Paper ticks, never virtual time
        .aroundAll { all -> Game.start(hooks).use { game -> all(); game.demoRerunTouched() } }
        .aroundEachTest { body -> Game.current.attempts(this, body) },
)

suspend fun Game.attempts(test: TestElement, body: suspend TestElement.() -> Unit) {
    for (n in 1..4) {                                              // one run and up to 3 retries
        val outcome = runCatching { withContext(AttemptScope(attempt, pool)) { test.body() } }
        val failure = outcome.exceptionOrNull() ?: return          // passed; the journal says flaky when n > 1
        if (failure !is RequirementFailed || n == 4) throw failure // refused or a framework fault: no retry
        pool.awaitTicketAtTail()                                   // later: behind every claim queued right now
    }
}
```

The pool: one queue of claims in arrival order; the head claim reserves each client as it becomes free and a claim
behind it may take only clients the head does not need, so a group of 3 can idle 2 clients while it waits. Granting a
client runs the framework wipe, each `GameHooks.wipe`, the start signal, and gating. `ownPaper` and `Motion` claims go
to the restart lane (Paper 2, booted at first claim, one attempt at a time). The `TestRun` is written by a testBalloon
`TestExecutionReport` when the compartment finishes; the Gradle JUnit XML is ignored by xtask and shows a flaky
requirement as passed. Arranging content and panel steps are kit functions a body calls, not framework hooks.

Hooks (`GameHooks`): `paperPlugins`, `quiet(server, player)`, `wipe(server, player)`. A new perceived kind is a
function, two lines in any test source set (`fun bossBar(title) = drawnText("boss bar", hud = "boss_bar") { ... }`),
with no registration. A kind that is not drawn text needs a client mod observer first (a framework change in every
direction).

What A makes harder:

- **Needs are known only at the claim**: frames and own Paper are declared inside the body, so the runner cannot group
  frame requirements or plan the restart lane before the run.
- **No packing**: order is testBalloon's launch order; a group of 3 idles clients behind it.
- **Two reports**: testBalloon and the IDE show a flaky requirement as passed; only `TestRun` says flaky.
- **Claims are code**: a second claim in one attempt is refused, or two attempts holding 2 clients and each wanting 2
  more deadlock the pool of 4.
- **Touched reruns live outside testBalloon** (in `aroundAll`), so their clips appear only in `TestRun`.
- Gains: the IDE gutter, `--tests` filters, kotest assertions and testBalloon fixtures work as in every other suite.

## Direction B: requirement values

A requirement is a value with a header: id, sentence, players, frames, Paper need and content. The framework finds
every requirement set (a class scan for Kotlin objects extending `RequirementSet`), plans the whole run before the
first attempt, and writes `TestRun` itself. testBalloon is not involved.

```kotlin
object BankRequirements : RequirementSet({
    requirement("BANK-1", "a deposit reaches every member of the group and nobody else", players = 3) {
        val (depositor, partner, outsider) = players
        ...
    }
})
fun main(args: Array<String>) = GameRunner(extensions = listOf(TypewriterKit)).main(args)   // once per module
```

The scheduler plans before the run: a restart lane (every `PaperNeed.Own` and every `Frames.Motion`) on Paper 2, and a
shared lane sorted by content key (each distinct content arranged once per Paper) then by player count, largest
first, so groups never wait for a full pool late in the run. It takes the first queued requirement that fits the free
clients (first fit), retries at the queue's end up to 4 attempts, runs touched demo reruns after the queue drains while
clients are warm, and writes `TestRun` with no JUnit XML. Hooks live in one `GameExtension` (`paperPlugins`, `kinds`,
`quiet`, `wipe`, `arrange(server, content)`); arranging is a hook because content is in the header. A new perceived
kind is a `PerceivedKind` value in a catalog, about 8 lines and one registration against 2 in A, so failure messages
list "new in the window" per kind and `anything()` covers every registered kind.

What B makes harder:

- **A second test model**: no IDE gutter, no test tree, no testBalloon fixtures; one requirement runs through a run
  configuration with `--only`. It strains the project idiom that tests use testBalloon
  (`basic-conventions.gradle.kts:5`).
- **More to build first**: discovery, filter, CLI, reporting, all before L3 (cost, not risk).
- **Headers must tell the truth**: `players = 2` with three players needed fails at the destructuring; content shared
  by key forces copies for any requirement that edits content.
- **Kinds need registration** to show up in messages and `anything()`.
- Gains: packing, frame batching and the restart lane are planned before the run; retries and touched reruns are one
  queue; `TestRun` has one writer; the scheduler knows `Still` before the run and pays the frames start signal once
  per batch.

## Direction C: declared in testBalloon, scheduled by the framework

A requirement is registered in a testBalloon suite with the header of B. Its testBalloon test submits the requirement
to the framework scheduler and waits for the final verdict. Hooks and perceived kinds are A's; arranging is a body
call (`load`), not header content.

```kotlin
@TestRegistering
fun TestSuiteScope.requirement(@TestElementName id: String, sentence: String, players: Int = 1,
                               frames: Frames = Frames.None, paper: PaperNeed = PaperNeed.Shared,
                               body: suspend RequirementScope.() -> Unit) {
    val requirement = Requirement(id, sentence, Needs(players, frames, paper), body, callerFrame())
    test("$id $sentence") {
        when (val verdict = Scheduler.current.submit(requirement).await()) {   // after the last attempt
            is Verdict.Passed -> Unit
            is Verdict.Flaky -> println("$id passed on attempt ${verdict.attempt}; reported as flaky")
            is Verdict.Failed -> throw verdict.lastFailure
        }
    }
}
```

The compartment is `Invocation.Concurrent` with `testScope(false)` and an `aroundAll` that starts the scheduler and
calls `scheduler.finish()` (touched reruns, `TestRun`). The scheduler is B's (plan, run, retry at the queue's end,
touched reruns, report) with one change: testBalloon selects tests before they run and its element tree is internal,
so the scheduler learns requirements as mirror tests submit them. It planned after the first 50 ms of wall clock
without a new submission and planned late arrivals as they came; that wall clock affects order only, never a verdict.

What C makes harder:

- **Two verdicts**: testBalloon shows the final verdict (green for flaky); `TestRun` holds the attempts. The
  testBalloon result is only a mirror, so nothing in it can drift from `TestRun`.
- **Planning is partial**: a wall clock debounce in a framework that otherwise avoids wall clock.
- **Stacks point at the scheduler**: the body runs in the scheduler's coroutine, so the failure must carry the body's
  own frame (`junit.rs` takes the first `at com.typewritermc.` line).
- **Content ordering is lost** (no header content), so a setup is applied when the first body needs it.
- Gains: the IDE runs one requirement with its gutter icon, a test filter selects before submission, retries never
  re run testBalloon's action, restart and frame needs are known at submit.

## Comparison

| | A: tests in a pool | B: requirement values | C: testBalloon declares, framework schedules |
|---|---|---|---|
| Concepts beyond the check surface | 5: game compartment, `requirement`, `GameScope` claims, `GameHooks`, kit `load` | 7: `RequirementSet`, header, `RequirementScope`, `Content`, `GameRunner`, `GameExtension`, `PerceivedKind` | 6: game compartment, `requirement` header, `RequirementScope`, verdict mirror, `GameHooks`, kit `load` |
| Lines for scenario 1 (body, non blank, no braces) | 7 (needs in the body) | 7 (needs in the header) | 7 (needs in the header) |
| Claims | At run time, in the body; one claim per attempt; strict order with head reservation | From the header, planned before the run; first fit after sorting by content and group size | From the header, planned online after a 50 ms quiet; first fit |
| Retries | testBalloon wrapper calls the body again after a ticket at the queue's tail | Scheduler moves the requirement to the queue's end | Scheduler moves it to the queue's end; the mirror test waits |
| Restarts | `ownPaper()` claim: Paper 2 booted at first claim, one client moved over | `paper = Own`: Paper 2 planned and booted at start | `paper = Own`, as B, known at submit |
| Frame needs | Declared at the claim, known only when the body runs | Declared in the header, batched before the run | Declared in the header, batched online |
| Into `TestRun` | A testBalloon report writes it from a journal of attempts; JUnit XML ignored | The scheduler writes it; no JUnit XML | The scheduler writes it; JUnit XML is a mirror and ignored |
| Touched clips | Rerun in `aroundAll` after testBalloon reported | Queued at the end of the one queue | Rerun in `aroundAll` by the scheduler |
| New perceived kind | A function, 2 lines, no registration | A `PerceivedKind` value, about 8 lines, registered | A function, as A |
| Arranging content | Kit function in the body | Header `Content`, arranged once per Paper by the scheduler | Kit function in the body |
| Fit with testBalloon | Full: gutter, filters, fixtures, kotest; flaky shows green | None: own runner, own filter, kotest assertions only | Discovery, selection, IDE and kotest; execution is the framework's |
| Main strain on a decided rule | Frame needs not known before the run | None on decisions; strains the testBalloon idiom | A wall clock debounce for planning order |

## What P2 later settled

P2 measured C with a fake pool: all 200 mirror tests submit within 12 to 35 ms, so the debounce is not needed to start
(ratio 1.08 of ideal), flaky shows as failed, selection happens before submission, `finish` runs after every test, and
one JVM can hold only one test compilation. See `../spikes/p2-testballoon-runner.md`.

## Left out

The draft's scenario bodies for the six hard cases (group of 3, kill and rejoin, held action bar with a timeline, async
work, typed tab suggestions, golden frame), the Typewriter kit sketch (`TypewriterKit`, `load`, `RecordingEditor`, the
Paper bridge plugin with assumed engine APIs) and the panel step sketch (layer 9). They illustrate the three
directions and carry no decision the record relies on; the bodies were identical in B and C, and shorter in A only by
the claim calls.
