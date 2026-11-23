# Game verification

Design record of Typewriter's in-game verification framework: requirements that prove what a player
experiences in a real Minecraft client, run on every pull request. The framework is built
(`services/playtest`); this file describes its model and the decisions behind it. How it was chosen
is in [The prototype search](#the-prototype-search) at the end, with one line per spike in
[Results](#results); details live in `spikes/` and `research/`. Read this file first after a context
reset.

## Goal

Prove what a player perceives in a real client, never packet sequences, judged on, in the developer's
order:

| Criterion | Meaning |
|---|---|
| Flexible | Any new kind of behaviour can be checked without a new framework feature |
| Accurate | Checks what the player perceives; never packet sequences. A deliberately broken behaviour must fail |
| Recordable | Video of what the player saw, and comparison against approved references |
| Performant | Hundreds of requirements in minutes. "if one tests takes already 3 seconds we are in big trouble" |

The framework holds no Typewriter code and may later move out of the repository. What it needs from
Typewriter is listed in [Obligations on Typewriter](#obligations-on-typewriter).

## The parts

Five kinds of process take part. A requirement's code runs only in the test JVM; Paper and the
clients hold none.

| Part | Process | Java | Role |
|---|---|---|---|
| Test JVM | Gradle's `gameTest` task, one per module with a `src/gameTest` source set | 21 (services' toolchain) | Declares requirements in testBalloon, submits them to the pool, judges windows, decides retries |
| Pool | one process per checkout, started and stopped by the Gradle build | 25 | Owns the warm clients and the Papers, queues and grants claims, records the run file |
| Shared Paper | stock Paper 26.3 with the step agent and the framework plugin | 25 | Runs every requirement that does not restart Paper, each in a region of its own |
| Own Paper | the same, booted per restart requirement (at most 2 at once) | 25 | Runs a requirement that kills and boots Paper |
| Client | Minecraft 26.3 with the framework's Fabric mod, 4 by default | 25 | Steps one tick per step ping, perceives without drawing, sends real window input |

- The **step agent** is a Java agent on the stock Paper jar. Once stepping starts, Paper's main loop
  runs a tick only on a permit, and Paper's block break clock counts ticks
  ([n-stepped-ticks.md](spikes/n-stepped-ticks.md)).
- The **framework plugin** runs the probes (chat, block, spawn, give, teleport and the like), the
  wipe, the step policy, per player work counting (`PlayerWork`) and coverage reads.
- The **client mod** holds the clock still between step pings, builds a perception record after each
  tick, sends input as window events (XTest on its own Xvfb display on Linux, its own SDL queue
  elsewhere) and drops every input event it did not send itself.
- The **wire** is Skir: every message the parts exchange is declared in
  `skir-src/harness/v1/wire.skir`. The wire module only frames those messages on a socket. The
  launch module holds what the processes share about launching each other: the memory budget, the pool
  and part files, and the pool's command and process (`PoolProcess`). It uses the standard library
  alone, as build-logic compiles it too.
- Test JVMs share the pool, so every module and extension shares the warm clients, and a warm single
  requirement takes about 2 s ([p6-pool-process.md](spikes/p6-pool-process.md)). The pool takes turns
  between test JVMs.
- A module adds what its requirements need to every Paper with `gamePaper { pluginJars; files { };
  environment }` in its build file: plugin jars, files at a path in Paper's folder, and Paper's
  environment. As every module shares the pool's Papers, the pool takes the union of every module's
  additions, for the shared Paper and each own Paper, and fails before Paper starts when two modules
  disagree on a file or a variable. The framework itself still holds no Typewriter code.
- Every Paper has a slot: 0 for the shared Paper, 1 and 2 for own Papers, which take the lowest free
  slot and give it back when they end. Paper learns its slot from `PLAYTEST_PAPER_SLOT`. A module adds
  environment to one slot's Papers with `gamePaper { slot(n) { environment } }`, and keeps paths
  across a slot's Papers with `keptPerSlot`: when an own Paper ends, the pool keeps those paths of its
  folder and puts them into the slot's next Paper, so a service identity a Paper wrote comes back on
  that slot. A run starts with nothing kept.
- Typewriter's module (`services/runtime/engine/runtimes/paper`) adds the Paper loader, the stack's
  config and a registration token path per slot. `cargo xtask e2e game` runs the suite inside the
  stack's `game` spec: the panel spec plus a binder that binds each slot's loader as the engine of
  the stack's Realm when its token appears (service `game_paper_<slot>`); a slot whose Paper ends
  before it advertises is attached once a later Paper of that slot advertises; and read only observer
  credentials (`STACK_OBSERVER_*`) for the owner's topology and the Realm's sessions bucket. The
  module's suite setup waits once, outside any window, until slot 0's engine is active. Its
  requirements therefore run only through `cargo xtask e2e game`.

## How a requirement runs

```kotlin
requirement("GROUP-1", "a line sent to the members of a group reaches each member and nobody else", players = 3) {
    val (member, partner, outsider) = players
    probe.chat(to = listOf(member, partner), "Bank: 1")
    within(10.ticks) {
        member sees chat("Bank: 1")
        partner sees chat("Bank: 1")
        outsider.never sees anyChat()
    }
}
```

A requirement declares how many players it needs, what it demonstrates (happy path, failure, edge
case) and whether it restarts Paper. Then:

1. **Submit.** The test JVM sends the requirement to the pool, which queues it. A claim larger than
   the pool is declined at once.
2. **Grant.** When enough players are free, the pool grants them (side by side attempts together) and
   picks a fresh region 1024 blocks from any other.
3. **Wipe.** Paper wipes each player's Minecraft and Paper state, fires `PlayerWipeEvent` so every
   plugin resets its own, and moves the player into the region. Each client resets its own state
   (blends, delays, chat). A claim waits until the client holds the chunks it draws.
4. **Lease.** The attempt gets its players. Nothing it does runs ticks yet.
5. **Stimulus.** A probe changes the world through Paper's API, or an input drives a client like a
   person (type, press, click, look, walk). A probe returns once its effect reached the client. Each
   stimulus marks the tick a window counts from.
6. **Window.** `within(n.ticks)` asks Paper to step until the window's last tick. It passes the moment
   every check holds in a perception record, and fails when the window's barrier comes back with a
   check still open. Ticks run only while a window waits, so a pass costs no more ticks than the truth
   needs.
7. **Settle.** After the body, Paper steps until the players' counted work is quiet, then the attempt
   ends, coverage is read and the players go back to the pool.

A body may send a player away and back: `player.quit()` makes its client leave Paper the way a person
quits, through the pause menu, and returns once Paper saw it leave; `player.rejoin()` joins the same
Paper again, unwiped and where Paper kept the player, and returns once its client steps and holds what
Paper sends it. Each marks the tick windows count from. The player stays on the attempt's lease
meanwhile and is no lost client; the other players' windows decide as usual, and a window, input or
frame of the away player is refused, as are a restart and a second quit. An attempt that ends with a
player away brings its client back to the shared Paper before the player serves another claim. Both
verbs work on the shared Paper and on an own Paper.

Requirements are G1 windows plus the recorded timeline
([g-requirement-shape.md](spikes/g-requirement-shape.md)): order, gaps and motion are read from the
attempt's timeline after a window. A window needs one positive check; `never` checks are broad
(`anyChat()`) and keep the window open for all its ticks. A body needs one positive check too, or it
fails as refused: a window that held, a `looksLike` whose compare matched, or a framework outcome the
body caught (`shouldThrow<WindowMissed>`, `WorkHung`, `ClientLost`, `PaperLost`). A bare read never
counts.

State no player perceives, such as a record in a store, is checked inside a window too:

```kotlin
within(40.ticks) {
    state("Alex's session listed") { sessions.holder(alex) == engine }
    never.state("Alex's session gone") { sessions.holder(alex) == null }
}
```

The test JVM reads each state check after every tick of the window, so a window that reads state runs
one tick at a time: each tick ends with a barrier of its own after its records, then the reads run. A
`state` holds at the first tick it reads true and counts as a positive check; a `never.state` fails at
the first tick it reads true and keeps the window open for all its ticks. Checks stay on ticks, never
wall clock: state that changes only with real time (a store's TTL) is proven outside the game.

## Ticks

The runner decides when a tick happens. Paper's next tick waits until every connected client acked
the last one and no claimed player's counted work is running; an idle Paper ticks once a second so
its watchdog and keepalives stay calm. A requirement therefore takes the same ticks on every run and
never waits for wall clock timers ([n-stepped-ticks.md](spikes/n-stepped-ticks.md),
[lease-time.md](spikes/lease-time.md)).

- **Counted work.** A plugin counts work it starts for a player through `PlayerWork`. The step waits
  while it runs; work past 1 s fails its attempt as hung, is never cancelled, and keeps its player out
  of the pool until it ends. Paper's async chat and command suggestions count as their player's work.
- **Input.** An input starts right after a tick; the client's ack waits until the game took every
  event it queued, so its packets reach Paper first. Typing sends one key per tick, as a person does.
- **Lost clients.** A client that does not ack for 5 s is lost: its attempt fails and the pool boots a
  replacement under the same name. A client that crashes or drops while its player is away is lost
  the same way; the intended leave of a quit is not.
- **Away players.** Paper holds back no tick for a player that quit, as for any player that left.

All requirements share one stepped Paper ([p1-topology.md](spikes/p1-topology.md)): a Paper per
attempt was 41 to 777 percent slower once groups or restarts appear. The cost is that one attempt's
async work holds every attempt's tick.

## Isolation

Every requirement meets a player who never played. Warm clients are kept; the player is wiped
([k-restarts.md](spikes/k-restarts.md)).

- The framework wipes the vanilla and Paper kinds it owns (inventory, effects, attributes, statistics,
  recipes, advancements and more, each with a leak requirement that fails when its wipe is off).
- Each plugin resets what it keeps for the player on `PlayerWipeEvent`. The framework never reaches
  into a plugin.
- Attempts run in regions 1024 blocks apart, never reused, and players see only their own attempt's
  players and chat.

## Perception

A client perceives without drawing ([p11-perceive-without-drawing.md](spikes/p11-perceive-without-drawing.md)):
after every tick it runs the extract and submit stages of a frame and skips the GPU work, and builds a
**perception record** from what they handed over: legible text runs with the HUD element that drew
them, chat lines with their arrival tick, the camera, items in hotbar and screens, watched blocks and
watched entities. A record goes out whole, only when it changed ([p4-live-stream.md](spikes/p4-live-stream.md)),
and stands for every tick until the next.

- **Seen means drawn legibly and owns visible pixels** ([a-observers.md](spikes/a-observers.md)).
  `drawn()` is the cheap culling answer; `visible()` makes the client draw real frames while its
  window holds, once with and once without the entity, and the entity owns the pixels that change.
- **Watches.** A probe that places a block or entity tells the client to watch it on the player's own
  connection, ahead of the packets that show it.
- Client state only arranges scenes and names causes; it never decides a verdict.

## Retries and verdicts

A failed attempt runs again at the end of the queue, up to 4 attempts. The verdict is one of:

| Verdict | When | Blocks |
|---|---|---|
| Passed | first attempt passed | no |
| Flaky | an attempt failed and a later one passed | yes, like a failure |
| Failed | every attempt failed, or a demo ended otherwise than the last attempt | yes |
| Quarantined | listed in `harness/quarantine.toml`; runs once | no |

- A requirement refused as written (a window without a positive check, `restartPaper()` without the
  flag, a claim the pool can never grant) and a game that cannot run never retry.
- Kotlin decides retries and fails the mirrored testBalloon test; xtask judges every runner's run file
  with the same rule for the gate ([p2-testballoon-runner.md](spikes/p2-testballoon-runner.md)).
- `--repeat N` runs exactly N attempts of each selected requirement.

## Goldens

`player.looksLike("sidebar")` draws a real frame and compares it exactly against an approved golden
([f-goldens.md](spikes/f-goldens.md), [p5-devenv-mesa.md](spikes/p5-devenv-mesa.md)).

- The repository holds only the golden file (`src/gameTest/goldens/<name>.golden`): readable Skir
  JSON of a `Golden` (`skir-src/harness/v1/golden.skir`), the frame's hash and size and the `Renderer`
  that drew it. The image lives on the `evidence` branch as `goldens/<hash>.png`, and
  `cargo xtask e2e game` fetches every image the machine lacks before the run, so a differing frame
  shows golden, new frame and diff.
- Goldens are exact on one **pinned renderer**: Vulkan through llvmpipe on Linux amd64 with the Mesa
  devenv ships (`PLAYTEST_MESA`). There a differing frame, a golden never approved, or one another
  renderer drew fails with the approve command. Any other machine reports "not checked".
- Each captured frame leaves a `GoldenCandidate` beside it, listed as the attempt's `golden`
  artifact: the golden file it is for, the image, the `Golden` it would become and whether the pinned
  renderer drew it. `cargo xtask goldens approve` takes the candidates a run left, refuses any the
  pinned renderer did not draw, writes the golden files and pushes the images.
- Only a compare that matched is a positive check; a golden not checked on another machine proves
  nothing, so a body there needs a window as well. A Mesa or Minecraft upgrade fails every
  golden, and its pull request approves them again. The weekly prune drops images no golden on a
  long lived branch (`develop` or `features/v1`) names once they are 30 days old.

## Coverage and demo clips

- **Coverage per requirement.** A JaCoCo agent limited to the plugin's classes is read and reset when
  an attempt starts and when it settles; each read goes to every attempt that ran since the read
  before ([i-coverage.md](spikes/i-coverage.md)). On the shared Paper overlapping attempts get each
  other's lines, so it over attributes and never loses a line.
- **Touched requirements.** xtask writes the lines the change added since the merge base with the
  default branch; a requirement that covered one is touched.
- **Demo reruns.** A failed, flaky, quarantined or touched requirement runs once more as a demo with
  clips: the stepped client draws 30 frames per second of game time between steps and pipes them to
  ffmpeg ([p9-frames-between-steps.md](spikes/p9-frames-between-steps.md)). Windows read only the
  records at the end of each tick, so a demo is judged as the gated run was, and it must pass or fail
  as the last attempt did.
- Evidence (frames, golden candidates, clips) is staged per attempt; CI publishes it to the `evidence`
  branch for the pull request.

## Restarts

`requirement(restartsPaper = true)` runs on a fresh Paper of its own, since a kill drops every client
on it. `restartPaper()` kills it (nothing saved) and boots it again on the same folder; its players
come back without a wipe, and windows count from the new Paper's ticks. The boot uses Java 25's AOT
cache trained on a restart boot in the same job, C1 only and SerialGC, with the clients quiet while
Paper boots: about 5 s from kill to state ([p7-faster-boot.md](spikes/p7-faster-boot.md)). At most 2
own Papers run at once.

## The pool's life and the run file

- **The pool lives exactly as long as the Gradle build.** The build service `GameRun` starts it when
  the build's first `gameTest` task runs, and returns once the pool listens. At the build's end
  `close()` closes the pool's stdin and waits up to 90 s for it to stop its game and exit, then kills
  it with its game. The pool ends its run when its stdin closes, so a killed Gradle takes it down too.
  Gradle exits, and xtask gives up the heavy lock, only once the pool is gone.
- **A test JVM only connects.** The pool writes `pool.running` (its port, run and process) once it
  listens. A test JVM reads it, and when it names another run, or a pool of its run that exited, it
  fails at once with `GameUnavailable` naming `pool.log`. It never starts, replaces or stops a pool,
  and no new pool starts after a crash. A lock keeps one pool per checkout.
- A leased attempt fails with `LeaseExpired` after 300 s.
- Each part writes its pid and start time into its folder (`part.running`), and tests find a client
  or Paper by it; Linux shows Java only the first page of a command line.
- **The run file** (`test_run.json`) survives a pool crash: the pool writes it as it takes up the run
  and rewrites it atomically after every attempt. It carries the run's id, which xtask chose and handed
  to the build, so xtask rejects a file another run wrote, and fails a run that left none, since it
  proved nothing: no game test ran, so the build never started the pool, or the pool wrote nothing, and
  the message names `pool.log`. Its `end` is
  one variant: `cut_short` until the build ends the run, so a pool that crashed leaves the finished
  cases and `cut_short`; `completed` once the build ended it with no session still open; and
  `could_not_run` with why the game could not serve the run, as when it never booted. xtask fails
  `cut_short` and `could_not_run` as the whole run's trouble, and the finished cases' evidence still
  stages.
- Each run keeps its pool, Paper and client logs in a folder of its own; the newest 3 are kept.

## Memory

The pool counts every part at its expected resident size, its heap cap and what it keeps beside its
heap (`PartMemory`), and admits only what fits in the machine's memory less a reserve
(`MemoryBudget`). On the 16 GB runner (MemTotal 16,053 MiB):

| Part | Heap cap | Beside heap | Resident |
|---|---|---|---|
| Shared Paper | 16 % (2569 MiB) | 640 MiB | 3209 MiB |
| Own Paper | 7 % (1124 MiB) | 288 MiB | 1412 MiB |
| Client | 4.5 % (723 MiB) | 960 MiB | 1683 MiB |
| Pool | 2 % (322 MiB) | 128 MiB | 450 MiB |
| Reserve | | | 3840 MiB |

- The pool runs as many restart attempts' own Papers at once as fit beside the shared Paper, its
  clients and itself, up to the 4 slots the build sets up: 1 on the 16 GB runner with 4 clients, 4 on
  a 32 GB machine. It refuses to run when not even one fits, and names how many clients would.
- The reserve is what the machine holds beside the pool's parts: the Realm host, Gradle, the test
  JVM, the rest of the stack, Xvfb, the runner and the kernel, with room for the page cache.
- Every Paper bounds direct memory (256 MB), class metadata (512 MB) and compiled code (256 MB); the
  pool 64, 256 and 128 MB. Each bound sits well over what it measured, so reaching one fails the part
  loudly instead of letting it outgrow the budget.
- A client's memory beside its heap is mostly the software renderer's, which no JVM flag bounds, so
  its allowance is measured alone.
- Every number comes from the kernel's process table when the runner ran out of memory with 2 own
  Papers (run 45115703169): shared Paper 3203 MiB, clients 1482 to 1674 MiB, pool 448 MiB, everything
  outside the pool's parts 3161 MiB and the kernel 513 MiB.

## CI

The game suite is the `game` entry of CI's `e2e` matrix on a Namespace runner of 4 vCPU and 16 GB,
in devenv's `e2e` profile (Xvfb, Mesa, lavapipe), about 11 minutes warm. The free GitHub runner it
was proven on ([h-ci-runner.md](spikes/h-ci-runner.md)) took 13 to 14.

- `cargo xtask e2e game` first runs `gameTestBuild` in a Gradle of its own without a daemon, so no
  compile daemon sits beside the suite, then the suite.
- The suite runs inside the stack's `game` spec, which builds and starts the services first, so
  the job also keeps the panel's generated sources and the frame vectors, as the panel suites do.
- Caches: Gradle's build cache (which holds the patched Paper), Loom's caches, and the AOT cache of
  the restart Paper. The build cache and the AOT cache are kept per job kind (`cache-scope`), so the
  game job and the services check each save their own.
- A dispatched run saves these caches only on `develop` or `features/v1` and only restores them on
  any other branch, so work branches cannot evict the base branch's caches past the 10 GB limit.
- Runners: every CI job but the gate runs on `nscloud-ubuntu-24.04-amd64-4x16-with-cache` with
  `nscloud-cache-tag-typewriter` and `nscloud-cache-size-50gb`, a cache volume all jobs share for the
  Nix store, Gradle's dependencies, the pub cache and Loom's downloads. Gradle's build cache and the
  AOT cache stay on the Actions cache: every job saves the whole volume and the last one wins. Run
  44247548234 against the GitHub hosted 44203399779: job setup from 160 to 340 s to 21 to 39 s, the
  suite from 818 s to 557 s, the same renderer and goldens. A cold volume is slow once, since the
  first fetch of a Nix path from Namespace's network crawls.
- The job checks out full history for the touched lines, and stages and uploads evidence even when
  the suite failed.

How to run it locally is in the dev loop skill (`.claude/skills/typewriter-dev-loop`); how to write
a requirement is in the testing skill (`.claude/skills/typewriter-testing`).

## Obligations on Typewriter

The search decided what Typewriter itself must offer so its behaviour can be verified. Each obligation
lives in the design doc of the layer that owns it; this list only points there.

| Obligation | Owner |
|---|---|
| The engine reads time from one clock source: the system clock in production, a clock the stepped test moves 50 ms per permitted tick (`StepPolicy`) | [interactions.md](../interactions.md#steps) |
| The realm purges every stored value of a subject in one operation | [stored-data.md](../stored-data.md#purging-a-subject) |
| The realm's clock is given to it, and a test can advance it past a `Due` | [stored-data.md](../stored-data.md#due) |
| Engine and realm report, per subject, whether chains or transactions are still busy (the done hook) | [events-and-handlers.md](../events-and-handlers.md#busy-per-subject), [stored-data.md](../stored-data.md#who-waits-for-a-commit) |
| The Paper engine clears its live state and asks for the purge on `PlayerWipeEvent` | [live-data.md](../live-data.md#wiping-a-protagonist) |
| Effects reach the player through the owner thread | [events-and-handlers.md](../events-and-handlers.md#busy-per-subject) (open against chat from the worker) |

Open: whether the done signal needs a test side hook as well as Paper's `PlayerWork`, decided with
layers 3 and 6.

## Decisions from the developer

Dated decisions, oldest first. The sections above describe what they add up to.

- Superseded 2026-11-18: v1 cinematics and sequences advance on the **tick clock**, not wall clock
  (2026-11-06), applied 2026-11-07 as a live `StepClock` per step on each engine. See the
  engine clock decision below.
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
  for wall clock timers such as Paper's block break timer. Spike N proved it.
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
- The **pinned renderer** is Vulkan through llvmpipe on Linux amd64 with the Mesa devenv ships
  (2026-11-15). devenv exports that release as `PLAYTEST_MESA`, and the game framework owns the pin
  and its one match rule. On the pinned renderer a golden never approved, or one another renderer drew
  (the Mesa before an upgrade), fails with the approve command; any other machine reports "not
  checked" with its renderer. CI's game job is the pinned runner and says so (`PLAYTEST_PINNED_RUNNER=1`),
  so there a frame from another renderer fails with the renderer it saw: a runner that drifts from the
  pin cannot let every golden pass unchecked. Each captured frame's candidate says whether the pinned renderer drew it, and
  `cargo xtask goldens approve` refuses any it did not. The run file lists each candidate as a
  `golden` artifact of its attempt (2026-11-18); staging, publishing and approve read that kind
  and never look for a `.golden` file beside a frame. `cargo xtask goldens approve --pr <n>` downloads
  the game results of the pull request's latest CI run and approves from them; without `--pr` it reads
  the last local run. A nixpkgs Mesa upgrade fails every golden, and the upgrade pull request approves
  them again.
- **Golden images live on the evidence branch** (2026-11-17): the repository holds only a golden's
  hash, size and renderer. `cargo xtask goldens approve` also pushes the frame to the `evidence` branch
  as `goldens/<hash>.png`, beside the pull request folders pruning empties, and `cargo xtask e2e game`
  fetches every golden image the machine lacks before the run, so a frame that differs shows its diff
  on CI while the framework stays offline. Approve writes `goldens/<hash>.approved-at` beside each
  image, and the weekly prune drops an image no golden file on a long lived branch (develop,
  features/v1) names once it is older than the retention (an image without that file counts as old).
- **Parts name their processes** (2026-11-17): the pool writes each part's pid and start time into its
  folder at every boot (`part.running`), and tests find a client or Paper by it. Linux shows Java only
  the first page of a command line, so arguments cannot name a part; a file a crash left behind names
  no process.
- **The pool budgets real memory** (2026-11-23): the heap only budget below let the runner run out
  of memory with 2 own Papers (run 45115703169: the kernel killed the shared Paper at 3203 MiB
  resident on a 2568 MiB heap cap, while the clients held 1482 to 1674 MiB on a 722 MiB cap). Each
  part kind is now counted at its heap cap plus a measured allowance beside it (`PartMemory`), every
  Paper and the pool bound direct memory, class metadata and compiled code, and `MemoryBudget` admits
  as many own Papers as fit in the machine less a 3840 MiB reserve, up to 4 slots: 1 on the 16 GB
  runner. The pool refuses to run when not even one fits. Chosen over 3 clients with 2 own Papers and
  over a 32 GB runner, as only 4 requirements restart Paper. Supersedes the 50 % heap limit and the
  fixed 2 own Papers of the next decision.
- **Every game JVM takes a share of the machine** (2026-11-17): `HeapShare` in the wire module holds
  each part kind's `-XX:MaxRAMPercentage` (shared Paper 16, own Paper 7, client 4.5, pool 2), so the caps
  scale with the machine; the pool starts each part with its share, and the test JVM starts the pool
  with the pool's, which is why it lives in the module both share. The parts that can run at once (the
  shared Paper, at most 2 own Papers, the pool's clients, the pool) hold at most half the machine in
  heap, which a unit test pins for the default 4 clients; the pool refuses to start with more clients
  (`-Pplaytest.clients`) than fit, and names how many do. The pool claims no restart attempt while 2 own Papers have not fully exited.
  A unit test of the command lists the pool builds (`Launches`) and the pool's own (`PoolProcess`) checks
  that each part carries its share. Since the build service owns the pool (2026-11-18), `HeapShare` lives
  in the launch module with the pool's command, which build-logic compiles too. Measured on the 16 GB runner without caps (run
  43996334142): the shared Paper peaked at 4.4 GB RSS with its heap committed to 4 GB (the part that
  ran the runner out of memory), a client at 1.7 GB RSS on a 0.54 GB heap, an own Paper at 1.3 GB RSS,
  the pool at 0.3 GB.
- **No compiler runs beside the suite** (2026-11-17): `cargo xtask e2e game` first runs `gameTestBuild`
  (everything gameTest runs, and nothing more) in a Gradle of its own with `--no-daemon`, then the
  suite. The Kotlin compile daemons end with the build's Gradle; on the 16 GB runner three of them held
  4.1 to 4.3 GB while the suite ran (run 44013168715). Building apart raised the lowest free memory from
  1.0 GB to 3.8 GB at the cost of a second Gradle start, measured at 46 s from start to first test (run
  44019397538). With `gameTestBuild` in place, the suite kept at least 3785 MB free and no Kotlin daemon
  was alive during it (run 44041628191). Compiling inside Gradle frees nothing, as the
  Gradle daemon grows by what the daemons held. It never runs `--stop`, which would stop other
  worktrees' builds.
- **The pool stays attached to its starter** (2026-11-17): the test JVM starts the pool without `setsid`.
  It outlives its starter's normal exit anyway, since the system reparents an orphan, and staying in the
  starter's process tree is what lets Gradle's cancel stop it: Gradle destroys every descendant by pid.
  Superseded by the build service owning the pool (2026-11-18, below): `GameRun` starts and stops it.
- **A run file survives a pool crash** (2026-11-17): a session names the run file and attempt policy in a
  `Join` right after its `Hello`, and the pool refuses a session of the run that names others. The pool
  rewrites the file atomically when a session joins and after every attempt it records, with
  `cut_short` true while a session of the run is open; other runners never set it.
  Superseded (2026-11-18): a `Join` names only the run id; the pool writes the file as it takes up the
  run, the run's end is one variant (`completed`, `cut_short`, `could_not_run`), and it reads
  `cut_short` until the build ends the run.
- **A run names itself and says when it could not run** (2026-11-17): `cargo xtask e2e game` makes a
  run id and passes `-Pplaytest.runId`; the build's `GameRun` service hands it to every test JVM and
  pool (a build outside xtask makes a fresh one), and the pool writes it as `run_id`. xtask takes the
  file as its own only when the id matches, so a file an earlier run left never passes for this one.
  When the game cannot serve the run, the pool writes why as `failure`, and the attempts it never ran
  are not recorded as failures of their own. `results::run_trouble` judges `failure` and `cut_short`
  once for every suite, and the pull request's evidence leads with them as not ready. Since review
  round 2 (2026-11-18) `failure` is the run end's `could_not_run` variant.
- **One pool per run** (2026-11-17): after its run's last session left, the pool waits 60 s for
  another session of the run, so with `--max-workers=1` a module whose tests start later joins the same
  pool and game instead of booting another. A pool that starts for a run whose file already holds that
  run id takes it up and adds to it, and adds to the run's logs instead of emptying them.
  Superseded (2026-11-18): the build service owns the pool, so the 60 s wait and the run file pick-up
  are gone.
- **The build service owns the pool** (2026-11-18): the Gradle build service `GameRun` starts the pool
  on the build's first `gameTest` task and stops it in `close()` at build end; the pool also stops when
  its stdin closes, which covers a killed Gradle. The 60 s grace after the last session, the owner timer
  and the run file pick-up are deleted, and so is the test JVM's start, restart and stop of pools: it
  only connects through `pool.running`, checking the run id. A pool crash fails the rest of the build
  at once with the cause in `pool.log`, and the run file reads cut short. Review round 2 traced the pool outliving the heavy lock by 60 to 120 s.
- **Selection** is testBalloon's (2026-11-15): `cargo xtask e2e game --only` passes each id as a test
  pattern, and the framework holds no selection code. A game module the selection leaves empty passes,
  as Gradle's "no matching tests" check is off for gameTest tasks; xtask's selection check fails as
  `--only <ids> matched nothing`, naming each id that matched no requirement or case of the run. A Gradle run that passed while no test JVM opened a pool
  session is a run without cases, which fails as "no requirements ran".
- **Steady tick counts** (2026-11-15): a requirement takes the same ticks on every run. Work that
  already runs when it begins holds the next tick; a task handed to Bukkit's async scheduler holds the
  one after, since that tick's heartbeat starts it. Paper's async chat counts as its player's work from
  the moment Paper reads the line until its chat thread sent it; chat stays on that thread. A command
  suggestion request counts the same way, from the read until its answer goes out or Paper decides to
  send none (cancelled or empty suggestions, or a newer request of the player ended); the client types
  one character per tick, as a person does, so it asks at most once per tick and every request gets
  its answer. The client mirrors this: it records a tick in the frame right after it, so the record
  shows the tick as it ended, and only the ack waits for its own work for the tick, that is until the
  game took each event an input queued right after the tick, so their packets reach Paper before the
  ack (the client counts its pushed events as the game takes them; on Linux, where X rebuilds them,
  each batch ends with `XSync` and counts as taken after the next poll); until
  that tick's record went out it handles no packet, since one queued after the tick's step ping belongs
  to the next tick. An input starts
  only right after a tick; one that arrives while Paper is idle asks for a tick first. GOLDEN-3 is
  watched: the visible sections update on a background thread after a move, which may make a frame
  lag a tick, but no run showed it, so the client does not wait for them (cause unproven). The client
  wipe also resets the break delay, which counts down only while the player keeps breaking. The
  client's other input delays (miss, use, jump and sprint double tap) count down every tick or clear
  once the button is up, and the pool runs at least 10 ticks between two attempts on a client, so no
  requirement can show them carry over; the wipe leaves them.
- **Only own input** (2026-11-16): while the client steps, the game takes only the mouse and key
  events the playtest sent; it drops every other one and logs its kind and the tick, without failing
  the attempt. On macOS the client's window shows on the developer's screen and the game believes it
  holds the mouse, so motion SDL reports there turns the player: an unmarked motion of 132 by 17.8
  pixels after BREAK-2's turn reproduced its one flake exactly (yaw 19.8, pitch 6.1). The SDL queue
  marks each event it pushes in the event header's reserved field, which SDL copies with the event. On
  Linux each client has a virtual display of its own that no real cursor or keyboard reaches, so every
  event there is the playtest's; this stays unproven on a real runner until slice 9.
- **Watches travel with the probe** (2026-11-16): Paper sends a probe's watch on the player's own
  connection, ahead of the packets that show the block or entity, so the client records them from the
  tick those packets arrive in; nothing about watches crosses the pool. Every watched entity a perceived
  frame draws is measured: the client draws that frame for real, once with and once without it. Two
  measured full runs put the drawn frames this adds at 0.6 to 0.7 percent of suite time, summed over
  clients; a measure only while a `visible()` window is open would cost 0.1 percent but needs the window
  to reach the client again.
- Requirements are written as **G1 windows plus the recorded timeline** (2026-11-06): every check sits
  in a `within(n.ticks)` window that opens at the last stimulus and passes the moment it holds; order,
  gaps and motion are read from the run's recorded timeline after a window. Drafts in
  `spikes/g-requirement-shape.md`.
- Requirement code runs in a **test JVM** (2026-11-06). The client streams what its player perceived,
  loop by loop, with the window barrier inside that stream; Paper and the client hold no requirement
  code. P4 measured the stream: about 3 records of 61 bytes per requirement.
- A window counts from the **last player action or probe call**, with an optional named start
  (`within(40.ticks after left)`) for the rare case (2026-11-06).
- `never` checks are **broad** (`anyChat()`, `anyTitle()`), and the framework **refuses** a requirement
  whose checks are all `never` or all client state: it needs one positive check (2026-11-06). A body
  that returns without one fails as refused (2026-11-18). A positive check is a window whose checks
  held, a `looksLike` whose compare matched (review round 2: one not checked proves nothing), an
  outcome the framework observed that the body caught (a missed window, hung
  work, a lost client or Paper, caught with `shouldThrow`), or the test kit's `holds`/`lacks` state
  check. The rule covers whole bodies: a body with no positive check at all fails. A bare read made
  after one check already held is not caught.
- A requirement that needs rendered frames **declares it** (`player(frames = 60.hz)`), so the runner
  groups such requirements at a fitting server rate before it starts (2026-11-06). Superseded: stepped
  ticks replaced server rates, and clients perceive without drawing (P11), so only `visible()`, goldens
  and clips draw, each for its own span, and no requirement declares frames.
- **The engine's clock is test driven** (2026-11-18, replacing the tick clock above). Answer to "How
  should step time count, so the branch can merge with features/v1?": "Clock, test driven
  (Recommended)". Step time keeps the clock model of the design records: `Running.startedAt`,
  `StepContext` and `QueuedContext` with `Duration`, `Playhead` with `since: Instant`, `KeyOffer`
  with `by` and `press`, and dialogue's `Instant` fields. The engine reads time from one clock source;
  production gives it the system clock, and the stepped test moves it 50 ms per tick `StepPolicy`
  permits, beside the realm clock a test can advance. Why: layers 17 and 18 build on clock time and a
  `Playhead` shared across engines, which a per engine tick count cannot drive; legacy lag behaviour
  (scenes stay on time) is kept; tests stay exact because time moves only with a step.
- **Typewriter runs on the game Paper inside the stack** (2026-11-18). Answer to "How should
  Typewriter on the game Paper reach real NATS, backend and realm?": "A. Inside the stack
  (Recommended)". `cargo xtask e2e game` runs under a stack spec whose Paper loader is bound like the
  realm host. Why: real grants and a real `engine_instance`, and no loader mode that only tests use.
- **State checks count as proof** (2026-11-18). Answer to "May a check on state no player sees (like a
  session entry) count as a requirement's proof?": "A. State check (Recommended)", a test JVM read
  after each tick inside a window. Answer to "Keep G3 to tick windows only, or add wall clock too?":
  "A. Ticks only (Recommended)": `never.state` covers state that must stay, and state that changes only
  with real time is proven outside the game.
- **Modules add to Paper** (2026-11-18): a module's `gamePaper { }` adds plugin jars, files and
  environment to every Paper; the pool takes the union of every module's additions.
- **Restart identities use 3 fixed slots** (2026-11-19). Answer to "How should restart Papers get an
  engine identity?": "A. 3 fixed slots (Recommended)". Each slot's identity is bound once per run
  and kept across that slot's Papers. Answer to "When are the slots bound?": "A. Bind during the
  run": the binder binds a slot when its loader's token appears, the framework keeps a generic path
  per slot, and no requirement waits for an engine inside a window; Typewriter's suite setup waits
  for slot 0. Why: loaders exist only once the pool boots their Papers, and a wall clock wait inside
  a tick window is wrong.
- **A slot binds, not one Paper** (2026-11-20). Answer to "The stack's binder fails when a short
  restart Paper stops before advertising. How should slots 1 and 2 bind?": "A. Wait for the slot
  (Recommended)". The binder has no deadline per Paper: a slot keeps its identity, so the slot's
  next Paper advertises the bound service. Why: CI's RESTART-3 ended its own Paper seconds after
  the binder bound it, and the 60 s advertise deadline then stopped the whole stack.
- **The observer reads real state** (2026-11-19): the test JVM reads with read only credentials the
  stack mints, the owner's topology snapshot request and exact reads of `sessions_<realm>`, never
  a file the binder writes.
- **The observer's grants stay hand written** (2026-11-20). Answer to "The read-only test observer
  lists its NATS grants by hand (observer.rs:64), against the rule that grants are never hand
  written. What should happen?": "A. Keep, record why (Recommended)". Why: it is a test only
  credential, and its JetStream reads of `sessions_<realm>` have no transport route to derive
  grants from; an observer role in `transport-routes.yaml` would put a test role into production
  routes.
- **Every game Paper loads Typewriter** (2026-11-20): the union of module additions reaches every
  Paper, so the framework's own requirements also run beside the stack and the loader, and run only
  through `cargo xtask e2e game`. Accepted as the cost of one shared pool.

## The prototype search

How the framework was chosen. Each axis was tried separately, by trying several approaches per
question and measuring them; a spike was small and was deleted after it answered its question.

### Facts that framed the search

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

### Settled before this search

Real clients only, no packet level tier (rejected twice). Stimuli are player input or API, not chat
commands. Full suite on every pull request. The framework holds no Typewriter code and may later
move out. Goal numbers in the old plan (1 s, 45 s, 350 in 3 min) are agent estimates, not
requirements; the hard statement is the 3 second quote and "if this takes 5 hours, then it's not
worth it".

### The search map

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

### Rules for running spikes

- Throwaway Paper instances are started only inside `prototypes/game-verification/`, on free ports,
  and are stopped after each run. This thread's prototyping is the one exception to the rule against
  starting Paper by hand, confirmed by the developer (2026-11-07): a prototype branch may use local
  throwaway Paper servers and CI, since results must hold on both. No k3d, no deploy.
- Gradle goes through `cargo xtask heavy`, so it queues behind other builds.
- Timing runs happen one at a time. Note machine load with every number.
- Every number names its machine and renderer. Evidence and inference stay labelled.
- The developer let spike H push its branch with a temporary workflow that ran only on that branch, to
  measure on GitHub's free runner; the workflow was removed before the search ended.

### Open questions from the search

- "Micro server" was read as the smallest, fastest booting Paper; and the search went on with that reading.

### Status

The search finished on 2026-11-07. After checking the record against the newer design docs, gap
spikes J (real player input), K (restarts and isolation) and N (runner stepped ticks) ran and are
recorded below with the developer's later decisions above. The prototype code and the temporary
workflow are removed again; they remain in git history at commit `86724c794`
(`prototypes/game-verification/` and `.github/workflows/game-verification-prototype.yml`), which the
Rerun and Reuse sections of J, K and N refer to; spikes before J refer to `9c9275f22`. Spikes L (a
1.21.4 client next to 26.3) and M (dialogue redraws on the chat screen) are deferred past the first
working version of the framework and run once their layers exist. The framework was then
planned and built in nine slices (`docs/drive/game-verification/record.yaml`), with prototypes P1
to P11 and the lease time measurement answering the questions the plan raised; each has a spike
document and a row below.

## Results

One line per finished spike or prototype, newest last. Details in `spikes/`.

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
| [P1](spikes/p1-topology.md) | A shared stepped Paper (A) against a Paper per attempt slot (B), 1,000 requirements on the free runner, 0 wrong in 36,000. Without groups B is 2.3 times faster (6.0 s against 14.0 s); at 10 percent groups B is +390 %, at 30 percent +777 %, since every group claim moves clients between Papers (0.3 to 1.0 s each); with 1 percent restarts B is +41 to +182 %. In A one attempt's async work holds every attempt's tick (about 100 ms per hit), and restarts are 82 to 89 percent of its wall time. A fresh Paper per requirement (computed) takes 1.5 to 2.8 hours per 1,000. A stale ack once passed a broken requirement; only acks of ticks after the stimulus count. CI runs 42345155973, 42339156447. | The developer picked the shared stepped Paper. The step policy covers every attempt on the Paper; restart requirements decide suite time and went to P7. |
| [P2](spikes/p2-testballoon-runner.md) | Runner C works: requirements declared in testBalloon, a framework scheduler runs, retries and reports, each test mirrors the verdict. 200 requirements on a fake pool of 4 finished at 1.08 of ideal; flaky shows as failed; `--tests` selects before submission; a failure in `finish` is silent unless a Gradle check reads the outcome. One JVM holds one test compilation (fixed `JvmEntryPoint` name); one root compilation of every module's gameTest ran 200 tests in one JVM, but only inside one Gradle build. | Runner C picked, A and B dropped ([runner directions](research/runner-directions.md)). The flaky error carries the body's frame first; xtask gates on the run file being written. The root compilation gave way to P6. |
| [P3](spikes/p3-one-build.md) | The services Gradle build holds the Loom client mod, the patched Paper, the plugin, the agent and gameTest with no included build; configuration time unchanged (new projects 31 ms), configuration cache holds. Three build file fixes were needed: run-task in build-logic, Kover skips gameTest, coverage merge takes only Kover projects. Loom costs about 700 MB, the patched Paper 216 MB. | The fixes were taken in slice 1. CI caches Loom and the patched Paper (slice 9). |
| [P4](spikes/p4-live-stream.md) | The client streams full perception records after a drawn frame, only when they change: 2.9 records of 61 bytes per requirement (212 KB per 1,000); diffs would save 31 percent, not worth it. A record costs 0.01 to 0.1 ms; the frame is the cost (stepped tick 2.40 to 8.06 ms on the runner). Record arrives 12.1 ms after its tick on the runner (CI run 42336338774). HUD tags 14 of 14 right. A4 in every record doubles the tick. Live gaps: fades legible from alpha 8, wrapped chat lines, grey completion text, cursor blink. | Full records, no diffs, tagged by HUD element, barrier inside the stream. A4 is asked for by a check, never streamed. |
| [P5](spikes/p5-devenv-mesa.md) | Goldens on devenv's Mesa 26.2.5: one hash per scene, 0 differing pixels in 18,540 identical pairs over 6 CPU models on Vulkan and 4 on OpenGL; exact comparison caught 60,480 of 60,480 breaks. The Mesa upgrade from 25.2.8 changed all 18 goldens (almost all off by 1 level). The e2e profile needs libglvnd and the X libraries; building it cost 300 to 480 s per job without the Nix cache. CI runs 42343076555, 42344338415. | Goldens are pinned to the Mesa devenv ships; a Mesa upgrade approves them again. |
| [P6](spikes/p6-pool-process.md) | The warm pool and scheduler run as their own process; two test JVMs shared one pool of 4 fake slots, a lock keeps it single, a warm single requirement takes 2 s of Gradle time against 20 s cold. Rotation between test JVMs: 325 ms against 4,071 ms for a late single. Killed test JVM, killed pool and version mismatch fail clearly; a stuck pool was untested and a pool crash lost the report. About 590 lines against 217. | The developer picked the pool process. Its open points (detach, stale pool, lease deadline, a report that survives a crash) were built in slice 9. |
| [P7 T1](spikes/p7-faster-boot.md) | A restart Paper on Java 25 with an AOT cache trained with the agent and a join, C1 only, SerialGC and the client gated while Paper boots: 5.0 s kill to state against 8.8 s; four at once 15.5 to 23.2 s against 48 to 72 s. 0 wrong of 1,494. The real levers are C1 only (minus 27 %) and a quiet client (minus 23 %); the slim world buys nothing; Java 26 is no faster and drops AppCDS with an agent. CI runs 42430101477, 42433205261. | Picked by the developer: restart Papers boot this way, with the cache trained in the same job. |
| [P7 T2](spikes/p7-checkpoint-restore.md) | A CRaC checkpoint of Paper (Azul Zulu 25) works only when taken right after `Bootstrap.validate`; later points bake stale data (7 of 84 wrong) or die. Kill to ready 8.8 to 9.1 s against 13.9 to 14.5 s booting, 0 wrong of 84; a 400 MB image, Linux only. CI run 42432909519. | Dropped: slower than T1 and needs Azul's CRaC JDK, an image and Linux. |
| [P8](spikes/p8-frames-every-tick.md) | 4 clients on the shared stepped Paper each drawing a frame every tick: +408 % per 1,000 requirements at 10 percent groups (15.4 s to 78.6 s), +545 % at 30 percent. Four lavapipe clients saturate the 4 vCPU; a frame costs about 40 ms with four clients against 6 ms with one. Every lever together (214x120 window, frames only after a game packet or while a check waits): +53 %. 0 wrong in 210,000. A record's tick label lagged up to 4 ticks on an idle client. CI runs 43306724605, 43320141634. | Dropped by the developer, over the 50 percent line even with every lever; led to P11. |
| [P9](spikes/p9-frames-between-steps.md) | In a demo rerun the stepped client draws fps / 20 frames per tick at even partial ticks: no repeated or skipped frames over 4,320 frames per machine; verdicts the same in 12 of 12 across gated, demo 30, demo 60 and a rerun. Cost on the runner 1.5 times gated at 30 fps, 2.6 at 60, against 4 to 5 real time (which dropped frames). Same machine reruns give identical mp4 bytes except particles. CI run 43312553335. | Clips are drawn between steps; the developer chose 30 fps. Windows read only records at the end of a tick, so demos need no margin. |
| [P10](spikes/p10-input-from-client.md) | The client sends window input itself: XTest from inside the client with one Xvfb display per client, or the SDL queue push; both match direct calls on all 18 inputs, 100 of 100, gated and rendered, under stepped ticks, always one tick later. 4 clients at the same step: 0 inputs on the wrong client; a shared display sent 24 of 30 rounds to another client. Lost suggestion replies (4 to 6 percent) come from Paper's 4 thread suggestion pool reordering requests. Mac not run. CI runs 43306835761, 43309694858, 43311267445. | Input comes from the client mod; the pool sends only commands. Suggestions were later fixed by typing one key per tick and counting a request as player work. |
| [P11](spikes/p11-perceive-without-drawing.md) | Clients run the extract and submit stages each tick and skip the GPU draw: +7 %, +15 % and +10 % per 1,000 at 0, 10 and 30 percent groups (P8: +374 to +580 %). A perceive frame costs about 1 ms against about 40 ms drawn. 0 wrong in 249,000; the lying scene battery gave 0 flips in 238 runs; nothing stale for a later drawn frame. A4 on 10 percent of requirements adds 6 to 27 points, since each ask holds the shared Paper for two drawn frames. CI runs 43330492175, 43333247905. | The developer chose no drawing; pixels only for A4 checks, goldens and clips. Slice 6 measured A4 on demand at about 0.25 percent of the suite. |
| [Lease time](spikes/lease-time.md) | Grant to lease cost a median 1.13 s: Paper's wall clock chunk send cap was about 1.08 s of it (81 chunks for a render distance 2 client); the wipe costs 1.4 ms. Cap removed 499 ms, plus regions loaded ahead 291 ms. A separate 8 to 17 s tail came from free clients falling up to 235 ticks behind. Local runs, no CI. | Fixes in `e5f88a238`: no chunk caps on the test Paper, regions loaded ahead, every client stepped, pinned graphics; median 409 ms, p90 684 ms, max 5284 ms (was 1132, 1422, 16353). |
