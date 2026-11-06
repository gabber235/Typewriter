# Game verification: prior decisions

Recovered 2026-11-05 from past threads and the harness plan. The already known list (real clients, `services/playtest`, requirements near the code, `Book.appliesTo`, stimuli, full suite, Q1 to Q8, P1 to P5, goals table) is only repeated where the developer's own words add something.

Source tags:

- `M#n`: thread 1e764db2 (Design Post-Merge Agent Workflow), item position n
- `S#0`: thread a9c559dc (Prototype In Game Verification), the developer's opening message
- `T`: thread mcp:b3e6b5f6 (Review Typewriter Test Strategy)
- `Plan:n`: `docs/plans/agent-harness.mdx` line n on the features-agent-harness worktree
- `Draft r3`, `Draft p3`: older plan revisions, in the M session transcript, not in the final plan
- `R:legacy`, `R:client`, `R:bot`, `R:speed`, `R:industry`: research subagent reports in the M session (`agent-ac06f0f6`, `agent-a71e30e1`, `agent-aa56035b`, `agent-a8a3d037`, `agent-a9e998e9`, `agent-a9a146bc`). Agent output, not decisions.
- Thread 5a24eb1f (Improve Test Strategy Review Capabilities) holds nothing about in-game.

## Requirements (developer stated)

### What a good in-game test is

- "The goal for a test is to capture requirements and to validate that or verify that a requirement has been met." Always domain driven. (M#140)
- "A test that only checks for what you're doing is a useless test because it only tests for what you're actually doing." A printing hello world test that it prints hello world is the example. (M#140)
- A player output layer "is useless because you can only test for what the thing is actually doing and not test for if what it is doing actually achieves the desired result." (M#140)
- "test results rather than just procedures"; "how we can express almost everything". (M#189 item 8)
- Check "observations", "not necessarily check for packet sequences, because A they're very brittle and B they're not very useful because they always check implementation". (S#0)
- "We want to check, okay, but what is a user seeing, and there are many different ways of checking that." So several observation methods are in scope. (S#0)
- "How can we make typewriter tests effective? For example, how do we make them easy to create and test, yet still expressive?" (M#512 item 4)
- Verification is "is it actually doing what it's supposed to do", validation is "is this actually solving the problem correctly", and the developer must be able to "assess that very quickly". (M#0)

### Optimization targets from the prototype brief (S#0)

- **Flexible**: "how flexible it is".
- **Accurate**: observations, not packets (above).
- **Videos**: see below.
- **Performant**: "if this takes 5 hours, then it's not worth it at all".
- Tradeoffs must be raised: "if we scrap this or hey, we can do this, but then it will cost this or hey, if we remove this, it will significantly reduce complexity". Ask at any time, also on coding style.

### Video, recording, goldens

- "We want to be able to make videos; that's one of the important things. It should be able to be recorded just like the panel, such that we can also find differences between and have golden things and stuff like that as well." (S#0)
- "We would like it to also have automated stuff and maybe even golden tests or stuff like that for users because it's incredibly useful" (M#35, the first in-game statement). "for users" is unclear: players, extension authors or dictation.
- "A lot of times we want videos of something. Showing it works end-to-end, which needs recording." (M#189 item 11)
- "just a screenshot often isn't enough. A demonstration of the feature, or a few demonstrations, is better because it builds trust." (M#189 item 11)
- "Including what happens when things go wrong is also important." (M#189 item 11)
- Edge cases: "the AI is good at the basic flow, but often misses edge cases that cause issues. How do we catch and show these?" (M#189 item 11)
- Evidence lives in the PR description, stays current, no spam comments. (M#189 item 11)
- Storage: chose an evidence repository in the question tool (M#278), then rejected a separate repository; media lives on an orphan `evidence` branch of the main repository (M#916).

**Conflict to raise.** The developer's only golden choice so far went the other way:

- Panel story images: chose "PR evidence only (Recommended)" over "Compare to approved images" and over "Both" (T, question tool). Plan text: "Images are evidence, not goldens" (`test-review.mdx:827`).
- So "just like the panel" holds for recording, but the panel has no golden comparison to copy. `xtask/src/evidence/record.rs` records with Xvfb plus `ffmpeg x11grab` on Linux only, and clips are for viewing.
- The developer has not said what "find differences" compares (pixels, frames, observation traces). Ask.

### Micro server

- "discussing game verification and things like that that we could do stuff in game and run a micro server". (S#0)
- This is the **only** place the words appear. No earlier thread uses "micro server", and no search hit defines it. The meaning is unknown, and it may be a dictation artifact.
- Nearest recorded ideas: Q5 "a server per few clients", one Paper server per CI job, a void world with regions. All agent text. Ask before building on it.

### Speed

- "we also will need to think about time in general, because if one tests takes already 3 seconds we are in big trouble." (M#512 item 2)
- "Of course this will be a much more heavy and long running thing than other stuff. But we want to have a ton of these. And we can't have this running for hours." (M#512 item 2)
- Note: the goals table's "arrange plus act median under 1 s" and all other numbers are agent written. The developer's own number is only "3 seconds is big trouble".
- Chose "Real clients, parallel" in the question tool even though the same question stated that research "found nobody running hundreds of real client tests fast". (M#540)

### Time and start of a test

- "I agree with the until, but we also need a good starting indicator. Often things need a few ticks to actually startup etc. Your eventually does this, but its not clear that the throughout skips those initial ticks." (M#512 item 2)
- Must be explicit in how a requirement reads, not only in behavior.

### Legacy mechanics as the reason for real clients

- Look at the legacy code: "we're gonna at some point get back to most of these things and look at how for example cameras are done and that uses a lot of Minecraft bugs and things like that to actually get things to work or not necessarily bugs, but it uses some interesting Minecraft mechanics." (M#140)
- Asked for a legacy survey of "what types of tests and what would it need. So that the suite we have will be good and more complete". (M#534)
- Keep legacy user visible behavior as the target unless the vision changes it. (design session preference in memory)

The camera mechanic itself (agent read, verified in `CameraCinematicEntry.kt`):

- `DisplayCameraAction` (`:347`) spawns a packet only entity with `TextDisplayMeta` (`:360`), `positionRotationInterpolationDuration = BASE_INTERPOLATION` (`:361`). Interpolation is done by the client.
- `entity.addViewer` then `player.spectateEntity(entity)` (`:383-384`): the player's view becomes that entity.
- `player.teleportIfNeeded(frame, location)` (`:390`) drags the real player along so chunks load.
- `fakeClearInventory()` (`:228`), `hidePlayer` both ways (`:220-221`).
- Agent's requirement statement: "the player sees a smooth path with the world rendered"; "A packet transcript would pass even if the client showed a black void." (M#150)

### Framework shape in the developer's words

- "create a separate project for the basic framework so it can be reused easily"; "Don't focus only on our single use case". (M#189 item 8)
- "The core should just be a minecraft testing framework. All the other things, like anything with nats, oidc etc all of that is only for Typewriter." Test: "if we extract the core would it make sense to have that for a completely different minecraft project". (M#618 item 1)
- Own tests in extensions; third party extensions later, "we won't deal with Maven repo details now, but we should keep it in mind"; "avoid excessive repetition and maximize reuse". (M#512 item 4)
- A few Typewriter independent tests "in the actual thing to check in general things are working. These shouldn't be made now because we don't have the real entries yet." (M#512 item 3). Earlier in the same list: still useful to create the framework "even though no \"real\" typewriter tests can be written yet because nothing is actually executable" (item 4).
- Setups: compose "books, pages, elements, cues", used "as if supplied" (M#512 item 1). Generated, not hand wired; new record types and extension sections must work without wiring; auto discovered; "the single commit at the start; it is necessary". (M#618 item 2)
- Scenario overlap: "we may want to specify exactly what we need for certain scenarios, so that overlapping scenarios do not run at the same time." (M#618 item 2)

### How to work

- Design search, in the developer's words: "try a couple of things out", "small prototypes", "okay, this is nice developer experience. This is very flaky or is not flaky at all. This has these downsides", "try out quite a few different ways of doing things instead of fixating on one path". (M#618 item 9)
- The plan is for "what are we searching for? What makes it good or bad?" (M#618 item 9)
- A good search "tries out different things and different approaches because then you get much more information". A good prototype "you can whip up fast", "not do everything all at once but specifically prototype parts". (S#0)
- Before prototyping: "what is there to prototype? ... what are the separate things that we want to try out?" (S#0)
- Keep findings in the docs folder so a context reset loses nothing, and use subagents as a coordinator. (S#0)
- Stay critical (said about mutation testing, M#1648, same attitude likely applies): "if this is too difficult or too flaky its not worth it"; "The only reason to keep it is if it will actually provide measurable benefits".
- Free: "we can't pay for anything, so we can't use paid services" (coding agents excepted). (M#0)
- Generally: "you make things too much in the spirit of what we have today instead of think about, how can we make this the best for the future". (M#189)
- "We don't want to have parallel universes. We want to have one unified way of doing things." (M#35)
- Order: harness PR, test review PR, then in-game. (M#837)

## Rejected

Rejected by the developer:

- **Player output layer**: "yes it's fast but it's way too much mocking and doesn't give us basically any confidence". (M#140)
- **Packet golden files**, fake NMS players with `EmbeddedChannel` as main gate: proposed M#65, dropped after M#140.
- **Hybrid tiers** (virtual players recording sent packets for about 85% of tests, real clients for 10 to 15%): chose real clients over it. Second rejection of the same idea. (M#540)
- **Smoke on PR, rest nightly**: agent's recommended option, developer chose full suite despite the stated "Likely flaky red PRs and long queues". (M#417)
- **Everything through commands**: "it will suck". (M#512 item 2)
- **Requirement catalogue written now**: "These were examples." (M#512 item 3)
- **Planning in-game as a normal implementation**: "I don't think we can actually plan this one out." (M#618 item 9)
- **Name "audience"** for the book restriction. (M#618 item 8)
- **A generic stack core** with NATS or OIDC in it. Only Playtest is extractable. (M#618 item 1)
- **Separate evidence repository**. (M#916, memory note on the workstream)
- **Golden comparison for panel stories** (see conflict above). (T)
- First reaction to the agent's "own fake player harness or check by hand" question (M#33): neither; "try and see if there is more". (M#35)

Ruled out by agents, developer never weighed in:

- Mineflayer: stops at 26.1. (R:bot)
- MCProtocolLib or SoulFire as the "real client": packets only, "cannot observe" interpolation, camera pose, culling, chunk meshing, HUD layout, pixels. (R:client)
- HeadlessMC `--headless`: patches LWJGL, nothing renders. (R:client)
- Vanilla gametest: server side, cannot see client state. (R:bot)
- Fabric `TestDedicatedServerContext` and `waitForClientboundPackets`: in-process vanilla server only, cannot target Paper. (R:bot)
- `run-fabric` Gradle plugin: does not exist. (R:client)
- Making Playtest Typewriter-only (R:industry): the agent refused it because the developer asked for general.

## Agent proposals not yet confirmed

Observation:

- Client probe (Fabric mod) reports state per frame; server drives; assertions run in Kotlin near Typewriter. Plugin channel ping as ordering barrier, since it travels on the same TCP stream. (R:bot)
- Fact catalogue, one extractor each. Camera, Hud, Chat, TabList, OpenScreen, Inventory, VisibleEntities, Blocks, Particles, Toasts, Sounds, Suggestions, WorldRender, PlayerView, server side PlayerState. (Draft r3)
- Concrete client sources, verified with javap on the 26.3 jar (R:bot): `Minecraft.getCameraEntity()`, `gameRenderer.mainCamera`, `levelRenderState.entityRenderStates` (entities actually rendered, already interpolated), `levelRenderer.hasRenderedAllSections()`, private HUD fields for title and action bar, `BossHealthOverlay.events`. Private fields need accessor mixins per Minecraft version.
- Screenshots as evidence, "not as the assertion". (M#150). Never confirmed, and now in tension with goldens.
- Video as failure artifact only (R:client). Contradicts the developer's "one of the important things".

Time:

- Paper `/tick freeze` and `/tick step`, tick stamped trace, server tick over plugin channel, RTT estimate NTP style. (R:client, M#263). Absent from the final plan.
- Fixed tick timeouts get flaky when tick speed changes; readiness must come from observed signals. (R:speed)
- Online monitors with bounded windows only (RTAMT idea), so every verdict settles in known delay. (R:speed)
- Budget: `60.ticks` default with a required reason above it (Draft r3); M#584 says 20 ticks default; the final plan only shows `budget = 60.ticks, budgetReason = ...` in one example (Plan:1780). Unsettled.
- Short fixture cinematics, 40 to 60 ticks, not production length. (R:legacy)
- Failure report format: broken tick and frame, budget used, window, expected, actual, screenshot, clip timestamp. (Plan:1938)

Parallelism and isolation:

- Regions in a void world spaced over twice the view distance, view distance 2 to 3 chunks. (R:speed, Draft r3)
- Lanes: Parallel, Exclusive (global state), Restart (one restart serves all). Shards split by recorded durations. Longest first. (Draft r3). Replaced by `SetupPlan` overlap in the final plan; lanes are gone.
- Declared shared state `Shared.World`, `Shared.Section`, `Shared.Resource`. (Plan:1852)
- Reset by clearing a region, not a new world per test; environments as fixtures; batch by environment like vanilla. (R:speed)
- Each requirement's setup renamed, books applied only to its clients, one commit for all. (Plan:1843)
- Separate slower lanes for restart and third party profiles. (R:legacy)

Reliability (added after the developer chose full suite, folded in with approval M#431 to M#506, **not in the final plan text**):

- GL and Vulkan preflight before anything starts. `Preflight.graphics()`.
- Prebuilt world template per Minecraft version.
- Seeds derived from requirement ID.
- Watchdog per step, names the step that hung.
- Single rerun and `harness/quarantine.toml` (the harness has this; game does not use it yet).

Environment:

- Linux container for multi-client suites, macOS only for one visible client. (R:client)
- Fabric's own CI runs client gametests on `ubuntu-24.04` with OpenGL and Vulkan via `mesa-vulkan-drivers`, about 5 to 6 minutes per job including build. (R:bot)
- Client memory 1.5 to 3 GB at render distance 5, 2 to 4 clients on 4 cores, all an estimate "Measure before relying on this". (R:client)
- Machine wide E2E slots, one run per 8 GB. (M#506)
- Client defaults worth copying: clouds off, chunk fade 0, render distance 5, volume 0, flat world, seed 1, `online-mode=false`, `enforce-secure-profile=false`, `--username botN`, disable `useNativeTransport`. (R:client, R:bot)

Sizing:

- About 350 tests: framework 30, dialogue 35, isolation 25, entities 50, cinematics 35, HUD 35, facts 15, events and actions 60, quests and paths 30, bounds and commands 15, third party 20. About 80% under 60 ticks. (R:legacy, "judgment")
- The 3 minute, 4 job, 4 client numbers all derive from this estimate.

Stimuli API sketch (Draft r3): `press`, `scrollHotbar`, `lookAt`, `interact`, `attack`, `walkTo`, `chat`, `disconnect`, `reconnect`, `server.run`, `server.restart`, `Network.latency`, `Network.cut`, `Network.heal`, `typewriter.trigger`.

Known risks stated by agents, none measured for Paper:

- Clock drift: if lavapipe frames exceed 50 ms the client falls behind, and camera tolerance tests may flake. (R:bot)
- GLX visual hangs, world load timeouts, Loom #1636 (26.3 needs `mesa-vulkan-drivers` even for OpenGL), network synchronizer error fabric-api #4415. ChiselsAndBits made its client gametest non blocking. (R:industry, R:bot)
- OpenGL removal planned, 26.4 snapshot may default to Vulkan. (R:bot, secondary source)
- No public project runs several real clients against one server, or real client tests of a Paper plugin. JEI `ExternalServerClient` is the closest precedent. (R:client, R:bot)

Observed, not proposed: panel e2e on Linux CI reached `direct rendering: Yes`, llvmpipe GL 4.6 only after `+extension GLX` on Xvfb and `__GLX_VENDOR_LIBRARY_NAME`; `ffmpeg-full` added about 580 MB, so it moved to the devenv e2e profile. (T)

## Untested ideas

Floated, never tried. No in-game prototype was run in these threads; every number and precedent below is from reading or estimate.

Video and comparison:

- In-client frame readback piped to ffmpeg `rawvideo` with stepped frames and fixed delta: deterministic video, each frame tagged with tick and partial tick. (R:client)
- `ffmpeg x11grab`: cheap, wall clock, drops frames under llvmpipe. What the panel does today. (R:client)
- Replay Mod style: record packets, render offline at fixed fps; 26.x support unverified. (R:client)
- Fabric `assertScreenshotEquals` and `assertScreenshotContains`, fuzzy, can be limited to a region. (R:client)
- Fabric screenshot path renders one extra frame with fixed `deltaTicks`, so a frame is deterministic and interpolation can be sampled at partial ticks such as 0.0, 0.25, 0.5, 0.75. (R:client)
- Fabric maintainers: the window is "a visualization", not a test surface; screenshots render offscreen at a chosen `deltaTicks` (fabric-api #5624). (R:bot)
- Golden tamper signal exists: `TestChanges` reports "Expected values rewritten: snapshots, goldens, fixture outputs". (Plan:1377)
- Golden noise warnings: fonts and frame timing nondeterminism; "without strict allowlisting and normalization, snapshots will flap". (R:bot, said about packet goldens)

Assertions:

- Smoothness as a property: `cameraPath.maxJerk < k`, `noTeleportsAbove(d)`. (R:client)
- Expose interpolation targets as facts so assertions are deterministic. (R:legacy)
- Tolerance bands for camera pose, e.g. `near(path.at(t - 10.ticks), 0.25.blocks)`. (Plan:1780)
- Re-evaluate a recorded trace offline without replaying. (R:client)
- Chat as a versioned log, because legacy dialogue rewrites the whole chat. (R:legacy)
- Property functions tested on synthetic timelines in milliseconds. (Draft p3)

Finding edge cases (the developer asked how in M#189; exploration and the state model are gone from the final plan):

- **Exploration**: random allowed actions plus faults, invariants on the timeline, shrunk to the shortest failing sequence, saved as replayable seed. Few long runs, nightly. (Draft p3)
- Model of player visible state, Hypothesis `RuleBasedStateMachine` style. jqwik is in maintenance mode. (R:client)
- Requirement IDs for edge cases in the plan (`QUEST-1.E1`), shown as unproven in the PR when missing. (M#402, in harness for panel)

Faults:

- Toxiproxy per client: latency, jitter, cut, heal; lag requirement example `ENTITY-DIALOGUE-1.F1`. (Draft r3). Launcher mention survives. (Plan:1868)
- Velocity for server switching; kill and relaunch Paper; client disconnect path. (R:client)

Client and environment:

- Loader neutral `-javaagent` probe using Mojang names since 26.1, behind a `ClientAccess` interface like JEI. Could run on vanilla. (R:client)
- `SDL_VIDEO_DRIVER=offscreen` with `VK_EXT_headless_surface`: windowless clients on macOS and Linux without Xvfb. "Not verified; needs a spike." (R:bot)
- SoulFire's POV capture from Minecraft's renderer with many bots per process; on demand, one scene at a time. (R:bot)
- Virtual players only as crowd or observers next to real clients. Agent thought, never asked. (M#529)
- Server side state, not packets, for non perceptual checks. Agent thought, never asked. Differs from the rejected hybrid. (M#531)
- `/tick sprint` is no help with real clients: "Players are not affected by tick rates that are higher than the default one." (R:speed)

Framework plumbing:

- Discovery via `ServiceLoader` or KSP index from `@Playtest`, vs TestBalloon compile time discovery. (R:speed, Draft r3)
- Reporter interface so another project could write JUnit XML; Typewriter's writes `TestRun`. (Draft r3)
- Client pool per job reusing one `runServer` config. (Draft r3)

## The kinds of player observable behaviour

Legacy survey (R:legacy, agent output, file citations are evidence, counts are judgment). About 450 entry types, about 14 kinds. "Most of that behavior is packet-only and per player", so "the client probe is the source of truth".

The report's table has A to N. Each line: what the player perceives; the hard or edge part; typical ticks.

- **A. Spoken, option, input dialogue**: text types out; earlier chat darkened and re-sent; unrelated chat held and replayed; hotbar scroll picks option; confirm key advances; typed chat answers and is not broadcast. Hard: whole chat rewrites. Edge: two players on one NPC, leaving the radius, disconnect, confirm spam, invalid input. 20 to 200.
- **B. Action bar dialogue and messages**: only Typewriter's text shows, others suppressed. Edge: another plugin spamming. Short.
- **C. Cinematics**: camera follows path smoothly; others hidden both ways; invisible, flying, no damage; inventory looks empty; everything restored exactly; titles, sounds, particles on frame; credits screen for blinding; pumpkin overlay; screen shake; skip key. Hard: camera rides interpolated display entity, chunk rendering after teleport. Edge: disconnect or restart mid cinematic, creative mode, frame jumps over 5, parallel cinematics. 100 to 1200.
- **D. Entities and NPCs**: visible only to audience; name plate and indicator reflect quest state; skin; equipment, pose, glowing, scale, display content; activities move it; right click triggers. Hard: packet only, tab list add and remove, skins, display interpolation. Edge: same NPC differs per player, chunk unload, world change, click spam. About 20 static, 100+ activities.
- **E. Entity cinematic replay**: recorded actor replays movement, swing, pose. Long.
- **F. Audiences and HUD**: boss bar, sidebar, tab header and footer, compass, per player blocks, player time and weather, XP bar, slot items, effects; appear on enter, gone on leave; live placeholders. Edge: boundary oscillation, world change. 5 to 40.
- **G. Quests**: active, tracked, completed; objective lines; indicators; path particles. Stimuli are real gameplay (break, place, kill, fish, shear, smelt, breed, travel). Edge: restart during quest, players at different stages. Medium to long.
- **H. Path display, road network**: particles stream to target. Edge: target change, no route. 40 to 200.
- **I. Facts and persistence**: permanent survive restart and rejoin; session reset on quit; group facts shared in the group, isolated outside. Edge: cron needs clock control. Restart tests long.
- **J. Events and triggers**: fire once per stimulus, only for that player. Edge: rapid re-trigger, cancelled event. Short.
- **K. Actions**: item, teleport, sound, particle, potion, velocity, burn, set block, toast, switch server. Edge: full inventory, cross world. Short.
- **L. Interaction bounds**: camera locked; sneak exits when interrupting, not when blocking; leaving radius ends. Edge: lag spike past a limit. Short.
- **M. Commands and placeholders**: typed args, tab completion, PAPI text. Edge: permission change. Short.
- **N. Third party**: reacts to Citizens, MythicMobs, WorldGuard, Vault, RPGRegions. Separate server profile per plugin. SuperiorSkyblock appears in the survey but is deprecated and unsupported. Short.

Capabilities the survey said a framework needs beyond title, chat and camera:

- Particles (client particle manager, transient), tab list, client view of inventory, per player blocks, toasts, chat rewrite semantics, entity metadata with interpolation target, camera effects (hurt tilt, overlays, world border, time, weather, XP), command suggestions, resource pack prompt response, clock control, rejoin as same UUID.
- Low priority: sign, book, anvil UIs, map items, Bedrock forms, builder content modes.
