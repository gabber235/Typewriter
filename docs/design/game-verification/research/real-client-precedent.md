# Real client test precedent

Researched 2026-11-05. Target: Paper plugin (MC 1.21.4 today), assertions on what a player perceives, real Paper server, video and golden frames, hundreds of requirements in minutes on Linux with 4 cores, 16 GB and no GPU, plus local runs on Apple Silicon.

Labels used in every section:

- **Verified**: read in source, docs, workflow files, or CI logs and step timings through the GitHub API.
- **Reported**: a project's own claim that I did not reproduce or check in code.
- **Inference**: my reasoning, not stated by any source.

Nothing was downloaded or run. CI timings are from a small sample of recent runs, not long term statistics.

## 1. Fabric client game tests

### Verified

- Runs test code on its own thread inside a real client. Tests run sequentially, and the game closes after the last one. [package-info](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/package-info.java)
- The module exists on the 1.21.4 branch with screenshot comparison, `TestInput`, `TestSingleplayerContext` and `TestDedicatedServerContext`. Later branches rename parts of it (`withTickDelta` became `withDeltaTicks`; names moved to Mojang mappings). [1.21.4 context](https://github.com/FabricMC/fabric/blob/1.21.4/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/context/TestDedicatedServerContext.java)
- `TestSingleplayerContext` is the integrated server. `TestDedicatedServerContext` is documented as an **in-process** dedicated server, created by the world builder. [source](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/context/TestDedicatedServerContext.java)
- **No API takes an external address.** `connect()` calls `ConnectScreen.startConnecting` with `localhost:<in-process port>`. That same vanilla call is reachable through `runOnClient`. [impl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/context/TestDedicatedServerContextImpl.java)
- **JEI already connects a client game test to a separately spawned server process.** It starts vanilla and Fabric dedicated servers as disposable processes, waits on a status ping, then uses `ConnectScreen.startConnecting`. No Paper variant exists there. [ExternalServerClient](https://github.com/mezz/JustEnoughItems/blob/HEAD/Common/src/clientTestFixtures/java/mezz/jei/test/client/ExternalServerClient.java), [ExternalTestServer](https://github.com/mezz/JustEnoughItems/blob/HEAD/Fabric/src/gametest/java/mezz/jei/fabric/test/ExternalTestServer.java), [vanilla server test](https://github.com/mezz/JustEnoughItems/blob/HEAD/Fabric/src/gametest/java/mezz/jei/fabric/test/JeiVanillaServerWithoutJeiClientGameTest.java)
- Lockstep: a tick has a tick phase (client and in-process server tick once in parallel) and a test phase (both block while test code runs). Exactly one server tick per client tick, at most one client tick per frame. [ThreadingImpl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/threading/ThreadingImpl.java), [MinecraftMixin](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/mixin/client/gametest/threading/MinecraftMixin.java)
- The client tick is still driven by `advanceGameTime`, only capped to 1 per frame, so the source shows no speedup above the game's tick rate. [MinecraftMixin](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/mixin/client/gametest/threading/MinecraftMixin.java)
- `waitForClientboundPackets` depends on `runOnServer` and a custom Fabric payload (`gametest_sync`) on the server side. It does not work against a server without that receiver. [TestServerConnectionImpl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/context/TestServerConnectionImpl.java), [FabricClientGameTestImpl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/FabricClientGameTestImpl.java)
- `waitForChunksRender` is a real render wait: chunks present, light queue empty, `hasRenderedAllSections`. [TestServerConnectionImpl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/context/TestServerConnectionImpl.java)
- World load has a hard 1200 tick limit. [ClientGameTestImpl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/util/ClientGameTestImpl.java)
- Screenshot API: `takeScreenshot`, `assertScreenshotEquals`, `assertScreenshotContains`, with `withRegion`, `withGrayscale`, `withAlgorithm`, `withSize`. Default is mean squared difference below **0.005**, with an `exact()` alternative. [options](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/screenshot/TestScreenshotComparisonOptions.java), [algorithms](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/screenshot/TestScreenshotComparisonAlgorithms.java)
- A screenshot renders one frame directly at **delta ticks 1 by default**, meaning objects are drawn as they are in the current tick, without partial tick interpolation. `withDeltaTicks` changes it. The call keeps ticking until the capture completes, so game time moves during a capture. [common options](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/screenshot/TestScreenshotCommonOptions.java), [ClientGameTestContextImpl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/context/ClientGameTestContextImpl.java)
- A missing template is written to disk when `fabric.client.gametest.testModResourcesPath` is set, which gives an accept flow. [TestSystemProperties](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/TestSystemProperties.java)
- `TestInput` covers keys, mouse buttons, `lookAt`, `typeChars`, scroll, cursor, `resizeWindow`, and timed holds. [TestInput](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/TestInput.java)
- The runner loop has no per-test catch, so the first failure ends the run. JEI wraps each test in its own `JUnitXmlTestReporter`. [runner](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/FabricClientGameTestRunner.java), [JEI test](https://github.com/mezz/JustEnoughItems/blob/HEAD/Fabric/src/gametest/java/mezz/jei/fabric/test/JeiVanillaServerWithoutJeiClientGameTest.java)
- Headless: Loom's production client task defaults `useXVFB` to true on Linux when `CI` is set. An outer `xvfb-run` is unnecessary. [ClientProductionRunTask](https://github.com/FabricMC/fabric-loom/blob/dev/1.19/src/main/java/net/fabricmc/loom/task/prod/ClientProductionRunTask.java), [JEI workflow comment](https://github.com/mezz/JustEnoughItems/blob/HEAD/.github/workflows/tests.yml)
- Start time reports: I found **no built-in per-run startup report**. Available: optional Tracy capture in Loom (Fabric API uploads the profiles), and log timestamps. [TracyCapture](https://github.com/FabricMC/fabric-loom/blob/dev/1.19/src/main/java/net/fabricmc/loom/task/prod/TracyCapture.java), [Fabric build.yml](https://github.com/FabricMC/fabric/blob/26.3/.github/workflows/build.yml)
- Docs warn about a network synchronizer error on GitHub Actions and name `fabric.client.gametest.disableNetworkSynchronizer`. That property is not in `TestSystemProperties` on 26.3, and code search found it only in the docs, so the note may be stale. [docs](https://docs.fabricmc.net/develop/automatic-testing)

Real CI use (`ubuntu-latest`; public repos get 4 vCPU, 16 GB, no GPU listed, private repos 2 vCPU, 8 GB, [runner docs](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)):

- **Wurst**: `runClientGameTest` step took **65 to 80 s** over 6 runs on 2026-11-03. [workflow](https://github.com/Wurst-Imperium/Wurst7/blob/master/.github/workflows/gradle.yml), [runs](https://github.com/Wurst-Imperium/Wurst7/actions/workflows/gradle.yml)
- Wurst timeline for one run on MC 1.21.11: `Loading Minecraft` at 13:45:47, test thread starts 13:46:05 (**18 s** boot), world created by 13:46:15 (about 8 s), about 40 s for 20+ test classes, done 13:46:56. Renderer in the same job: llvmpipe, LLVM 20.1.2, 256 bits, GL 4.5 core, Mesa 25.2.8. [run log](https://github.com/Wurst-Imperium/Wurst7/actions/runs/41647020188)
- **JEI**: client game test step took **3 min 49 s to 9 min 45 s** over 4 runs, about 30 test files (some are helpers). It sets `SDL_OPENGL_FORCE_SRGB_FRAMEBUFFER=skip`. [workflow](https://github.com/mezz/JustEnoughItems/blob/HEAD/.github/workflows/tests.yml), [runs](https://github.com/mezz/JustEnoughItems/actions/workflows/tests.yml)
- **Fabric API**: `runClientGametest` step took 4 min 14 s to 5 min 49 s, in a matrix of OpenGL and Vulkan on software drivers, including Gradle work. [build.yml](https://github.com/FabricMC/fabric/blob/26.3/.github/workflows/build.yml), [runs](https://github.com/FabricMC/fabric/actions/workflows/build.yml)
- **Skyblocker**: OpenGL and Vulkan matrix, 15 min job timeout. [beta.yml](https://github.com/SkyblockerMod/Skyblocker/blob/HEAD/.github/workflows/beta.yml)
- **LiquidBounce**: workflow comment says "A normal run takes about 5 minutes". [build.yml](https://github.com/CCBlueX/LiquidBounce/blob/HEAD/.github/workflows/build.yml)

### Reported

- A project on 2 vCPU runners never finished world load. See section 6. [haulback#2](https://github.com/achedon12/haulback/issues/2)

### Inference

- A Paper server cannot be the in-process server. It is a separate patched server with its own `net.minecraft` classes, loaded from its own launcher. External process is the only route, and that loses server lockstep.
- With external Paper the client still pauses during the test phase while Paper keeps ticking at wall clock. Assertions must poll for perceived state with timeouts, as JEI does, or Paper must be held still with the vanilla `/tick` command. Long test thread work risks keepalive timeouts.
- A sync equivalent to `waitForClientboundPackets` needs a small Paper side echo over plugin messaging.
- Fabric's default screenshot hides interpolation. Good for golden stability, bad for "what a player perceives" when a requirement is about motion, so motion checks need several frames with explicit delta ticks or video.

## 2. HeadlessMC and mc-runtime-test

### Verified

- HeadlessMC `--headless` patches LWJGL: every `org.lwjgl` method body is redirected to a default value or custom stub. This is a launcher feature and needs no display. [headlessmc-lwjgl README](https://github.com/headlesshq/headlessmc/blob/main/headlessmc-lwjgl/README.md), [launch docs](https://github.com/headlesshq/headlessmc/blob/main/docs/launch.md)
- Minecraft's rendering code still runs; only the LWJGL calls do nothing, and buffers are allocated on the heap. `hmc-optimizations` removes more of the pipeline with mixins and warns it can be unstable. [hmc-optimizations](https://github.com/headlesshq/hmc-optimizations)
- **No pixels in that mode.** `hmc-specifics` states `screenshot` saves "only if the game renders (not in HeadlessMc's headless mode)". [hmc-specifics](https://github.com/headlesshq/hmc-specifics)
- What still works without rendering: `gui` dumps screen widgets with coordinates, `render` dumps strings passed to the font renderer, plus `click`, `text`, `connect`, `msg`, `/`, `metrics`. [hmc-specifics](https://github.com/headlesshq/hmc-specifics), [docs](https://github.com/headlesshq/headlessmc/blob/main/docs/specifics.md)
- Dummy assets (`hmc.assets.dummy`) reduce memory further and remove real textures and sounds. [hmc-optimizations](https://github.com/headlesshq/hmc-optimizations), [configuration](https://github.com/headlesshq/headlessmc/blob/main/docs/configuration.md)
- mc-runtime-test is a GitHub Action around HeadlessMC plus Xvfb: join a singleplayer world, wait for chunks, quit, and optionally execute `/test runall`. It is a smoke test, not an assertion harness. It lists 1.21 to 1.21.11 and 26.1 to 26.3. `.minecraft` is cached. [README](https://github.com/headlesshq/mc-runtime-test)
- No-render runs on 26.3 need a HeadlessMC release with the SDL update, so the patch follows every windowing change. [README](https://github.com/headlesshq/mc-runtime-test)

### Reported

- **artisan** (Paper 26.2): real Fabric client through HeadlessMC, offline account, no rendering, tick by tick mod writing `ok`/`FAIL`, about **4 min 30 s per variant**. Visual items "need real rendering and remain manual". [artisan#125](https://github.com/artisanmc/artisan/pull/125)
- **gp-headless-client** (Paper): HeadlessMC with Fabric and Minescript, about 15 s server boot, about **20 s per client boot**, about a minute per run, about **6 GB for two bots**. [README](https://github.com/FreeMonoid/gp-headless-client)
- mc-server-flashback PR #7 used the same pattern against Paper, per a search snippet. The repository is no longer reachable, so treat as weak. `https://github.com/Dead-Doctor/mc-server-flashback/pull/7`

### Inference

- HeadlessMC `--headless` cannot be the golden or video tier. It can serve a fast tier asserting client state and drawn strings, but that observes what the client intended to draw, not what appears. Clipping, layout overlap, shaders, and fonts stay invisible.
- HeadlessMC under Xvfb without the patch is a normal rendered client. Its value is then only launching, which Loom already does.

## 3. Other harnesses and approaches

### Verified

- **Mojang GameTest**: the Java entry point starts a server, runs tests and exits; `/test` runs them in game. No client involved in the entry point. Current form from 1.21.5. [wiki](https://minecraft.wiki/w/GameTest)
- **Quick Play**: `--quickPlayMultiplayer <address>` joins a server at startup, since 1.20. Useful for launchers with no in-client code. [wiki](https://minecraft.wiki/w/Quick_Play)
- **PortableMC**: a launcher with loader support; no test features in its README. [README](https://github.com/theorozier/portablemc)
- **Loom**: production client task and dev run both manage Xvfb. [ClientProductionRunTask](https://github.com/FabricMC/fabric-loom/blob/dev/1.19/src/main/java/net/fabricmc/loom/task/prod/ClientProductionRunTask.java), [JEI workflow comment](https://github.com/mezz/JustEnoughItems/blob/HEAD/.github/workflows/tests.yml)
- **Wurst and Wurst mods** (ChestESP, WI Zoom, Mo Glass, WI Freecam): client game tests with goldens, singleplayer. Most mature public user. [WurstTest](https://github.com/Wurst-Imperium/Wurst7/blob/master/src/gametest/java/net/wurstclient/gametest/WurstTest.java)
- **Sodium, Iris, MiniHUD, Meteor**: PR or build workflows only run `./gradlew build`; no llvmpipe or client run seen in those workflow files. [Sodium](https://github.com/CaffeineMC/sodium-fabric/blob/HEAD/.github/workflows/build-pull-request.yml), [Iris](https://github.com/IrisShaders/Iris/blob/HEAD/.github/workflows/build.yml), [MiniHUD](https://github.com/sakura-ryoko/minihud/blob/HEAD/.github/workflows/build.yml), [Meteor](https://github.com/MeteorDevelopment/meteor-client/blob/HEAD/.github/workflows/pull-request.yml)
- **Carpet**: `./gradlew build`. **Create**: `runGameTestServer`, server only, no client rendering in CI. **Baritone**: `./gradlew test`. [Carpet](https://github.com/gnembon/fabric-carpet/blob/HEAD/.github/workflows/build-on-pr.yml), [Create](https://github.com/Creators-of-Create/Create/blob/HEAD/.github/workflows/build.yml), [Baritone](https://github.com/cabaletta/baritone/blob/HEAD/.github/workflows/run_tests.yml)
- **mc-test**: Paper plus rendered Fabric client under Xvfb and llvmpipe with an in-process client agent. Its own workflow calls this the "heaviest/most-fragile lane", nightly only, `continue-on-error`. One rendered job on 2026-10-11 took 5 min 17 s and failed while the workflow stayed green. [e2e.yml](https://github.com/Shawn11564/mc-test/blob/HEAD/.github/workflows/e2e.yml), [run](https://github.com/Shawn11564/mc-test/actions/runs/38144519924)
- **MinecraftModConventions**: shared Gradle plugin with production game tests, MP4 recording, and an in-process dedicated server harness. [README](https://github.com/brainage04/MinecraftModConventions)
- **Archie** and **strata** write Kotlin client game tests, so Kotlin is workable. [Archie](https://github.com/kernel-panic-codecave/Archie/blob/HEAD/gametest/common/src/main/kotlin/net/kernelpanicsoft/archie/gametest/AClientGameTestHarness.kt), [strata](https://github.com/sya-ri/strata/blob/HEAD/integration/shared/minecraft-fabric/runner/gui-extractor/src/gametest/kotlin/dev/s7a/strata/integration/minecraft/fabric/MinecraftLoadedTestContextExtensions.kt)

### Not checked

- XMCL. Launcher only as far as I know; not read.

### Inference

- Only one pattern exists for real rendered testing in the wild: **Fabric client game tests, Xvfb, llvmpipe**. Everything else is a launcher, a server only test, or no-render. The "big renderer mods test with llvmpipe" assumption is not supported by the workflow files I read.

## 4. Protocol bots: what they cannot see

Rejected as a tier. Stated only to define the gap.

### Verified

- Mineflayer lists entity knowledge, block knowledge, physics, inventory. Rendering is not part of it; `prismarine-viewer` is a separate browser view. [README](https://github.com/PrismarineJS/mineflayer/blob/HEAD/docs/README.md)
- Azalea lists graphics as a **non-goal** and states some physics features are not implemented. [README](https://github.com/azalea-rs/azalea/blob/HEAD/README.md)
- MCProtocolLib is "a simple library for communicating with Minecraft clients and servers". [README](https://github.com/GeyserMC/MCProtocolLib/blob/HEAD/README.md)
- Display entity interpolation happens on the client: it records previous and changed values and interpolates when rendering; the server updates position and rotation immediately. [wiki](https://minecraft.wiki/w/Display)
- mc-test states its bot "cannot see client-rendered mod Screens". [README](https://github.com/Shawn11564/mc-test)

### Inference

A bot sees packets decoded into state. It cannot see:

- Interpolated positions, display entity transitions, title and action bar fades at any given moment.
- HUD and GUI layout: GUI scale, text wrapping, overlap, clipping, draw order.
- Resource pack effects: font glyphs, custom models, textures, shader tricks. Whether a pack was really applied is only a status packet.
- Occlusion, culling, fog, lighting, particles, render distance.
- Local client logic: screens opened by the client, client side prediction, keybinds, and audible sound (only the packet).

## 5. Visual regression on Minecraft

### Verified

- **Fabric API default**: mean squared difference normalized by 255 squared, threshold 0.005. [algorithms](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/screenshot/TestScreenshotComparisonAlgorithms.java)
- **Wurst**: threshold **3e-4**, alpha masks on templates (pixels at most 50% opaque are ignored), hosted templates, and a retry helper up to 200 ticks for "settling" states. Failures post expected and actual images to the job summary. [WurstClientTestHelper](https://github.com/Wurst-Imperium/Wurst7/blob/master/src/gametest/java/net/wurstclient/gametest/WurstClientTestHelper.java)
- **Skyblocker** uses the default comparison with `saveWithFileName`. [SkyblockerGameTest](https://github.com/SkyblockerMod/Skyblocker/blob/HEAD/src/gametest/java/de/hysky/skyblocker/SkyblockerGameTest.java)
- **strata** compares with its own per pixel loop in Kotlin. [source](https://github.com/sya-ri/strata/blob/HEAD/integration/shared/minecraft-fabric/runner/gui-extractor/src/gametest/kotlin/dev/s7a/strata/integration/minecraft/fabric/MinecraftLoadedTestContextExtensions.kt)
- **grug-for-minecraft**: per-loader references, accepted from a **CI capture** because "a world capture from a local run can differ slightly", with an `update-goldens` phase. [README](https://github.com/grug-lang/grug-for-minecraft/blob/HEAD/README.md)

Nondeterminism people removed:

- Fabric defaults: tutorial, clouds, anisotropic filtering, chunk fade, onboarding, render distance 5, music; flat world, seed 1, no structures, no time or weather advance, no mob spawning, respawn radius 0. [package-info](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/package-info.java)
- Wurst: splash text, title fade, chunk fade, its own HUD animation, grass replaced by smooth stone ("because the grass texture is randomized and smooth stone isn't"). [WurstTest](https://github.com/Wurst-Imperium/Wurst7/blob/master/src/gametest/java/net/wurstclient/gametest/WurstTest.java)
- MinecraftModConventions: toasts (unsecure chat, social, recipe, advancement), `showAutosaveIndicator`, `hideSplashTexts`, realms notifications, fixed `overrideWidth` and `overrideHeight` so GUI scale is stable. [README](https://github.com/brainage04/MinecraftModConventions)

### Reported

- **grug #1132**: pixel exact check with 5 references flaked because of the save indicator overlay; 927 of 34,000 pixels differed, all in the overlay. Autosave every 6000 ticks made the flake depend on timing. [issue](https://github.com/grug-lang/grug-for-minecraft/issues/1132)
- ZigCraft (not Minecraft) saw a completely black golden; its script refuses to compare it. Black baselines are a known failure class. [issue](https://github.com/OpenStaticFish/ZigCraft/issues/962)

### Inference

- **The Fabric default tolerance is too loose for HUD checks on full frames.** At 1280x720 the budget of 0.005 equals about 4600 pixels at maximum error (black against white). A 100x20 HUD element at maximum error scores about 0.0022 and **passes**. Wurst's 3e-4 budget is about 280 such pixels. Requirements need region or mask scoped comparison.
- Goldens need provenance: generated by one pinned renderer image, with Mesa and LLVM versions recorded. llvmpipe vector width (the log shows 256 bits) is a likely source of drift between machines.
- No precedent found for sharing goldens between macOS and llvmpipe. Assume they cannot match. Local Mac runs should use region checks at loose tolerance or per platform references, or run the Linux renderer in a container. Linux arm64 client natives in a container need checking first; I did not verify them for 1.21.4.

## 6. Failures and lessons

### Verified

- **Native transport**: JEI forces NIO and asserts `useNativeTransport` is off before connecting to external servers. [ExternalServerClient](https://github.com/mezz/JustEnoughItems/blob/HEAD/Common/src/clientTestFixtures/java/mezz/jei/test/client/ExternalServerClient.java)
- **Stack split at 26.3**: Fabric 26.3 has `SDLEventHandlerMixin` and `VulkanGpuSurfaceMixin`; Fabric's own CI runs both backends. 1.21.11 logs show LWJGL and GL 4.5 on llvmpipe. [mixin tree](https://github.com/FabricMC/fabric/tree/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/mixin/client/gametest/input), [run log](https://github.com/Wurst-Imperium/Wurst7/actions/runs/41647020188)
- **Vulkan**: 26.2 added it with OpenGL fallback (Vulkan 1.2 at that snapshot), MoltenVK on macOS. [wiki](https://minecraft.wiki/w/Java_Edition_26.2-snapshot-1)
- Three software render fixes in current workflows: install `mesa-vulkan-drivers` (Wurst, Fabric), set `SDL_OPENGL_FORCE_SRGB_FRAMEBUFFER=skip` (JEI), install EGL (LiquidBounce). [Wurst](https://github.com/Wurst-Imperium/Wurst7/blob/master/.github/workflows/gradle.yml), [JEI](https://github.com/mezz/JustEnoughItems/blob/HEAD/.github/workflows/tests.yml), [LiquidBounce](https://github.com/CCBlueX/LiquidBounce/blob/HEAD/.github/workflows/build.yml)
- HeadlessMC notes: turn off `pauseOnLostFocus`, `onboardAccessibility`, `narrator`. Fabric fakes window focus for the same reason. [launch docs](https://github.com/headlesshq/headlessmc/blob/main/docs/launch.md), [runner](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/FabricClientGameTestRunner.java)
- Startup deadline: MinecraftModConventions fails a run if the client is not loaded within 300 s; JEI gives external servers 90 s to start. [README](https://github.com/brainage04/MinecraftModConventions), [ExternalServerProcess](https://github.com/mezz/JustEnoughItems/blob/HEAD/Common/src/testFixtures/java/mezz/jei/test/lib/ExternalServerProcess.java)
- Sync chunk writes make Unix shutdown slow, so Fabric disables them. [package-info](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/package-info.java)
- JEI clears render data on disconnect as a workaround for MC-310862 and checks the level is collected, which shows client reuse can leak between sessions. [ExternalServerClient](https://github.com/mezz/JustEnoughItems/blob/HEAD/Common/src/clientTestFixtures/java/mezz/jei/test/client/ExternalServerClient.java)

### Reported

- **26.3 GLX failure**: "Couldn't find matching GLX visual", because the GL backend asks for an sRGB framebuffer that Xvfb's GLX does not expose. It hung to a 240 s timeout; Vulkan via lavapipe then passed in about 50 s. The same step on 26.1.2 used GLFW and passed. [conflux-map#97](https://github.com/Conflux-Union/conflux-map/pull/97)
- **2 vCPU failure**: under Xvfb and llvmpipe, integrated server stuck at "Preparing spawn area: 16%", `Can't keep up!` at 4 to 8 s per tick, `Timeout loading world`. `LP_NUM_THREADS=1` and lower settings did not help. About 5 min locally with a GPU. [haulback#2](https://github.com/achedon12/haulback/issues/2)
- **MineRL**: Xvfb is 2 to 3 times slower because rendering runs on the CPU. [docs](https://minerl.readthedocs.io/en/latest/notes/performance-tips.html)
- **JEI**: Fabric client could hang connecting under Linux epoll; a separate fix for tests stalling while the server log looked ready. [changelog](https://www.curseforge.com/minecraft/mc-mods/jei/files/8407026)
- **LiquidBounce docs snippet**: `SDL_VIDEO_FORCE_EGL=1 xvfb-run ...`, and Debian needs `libegl1`. The page failed to load on fetch, so this is from a search snippet only. `https://liquidbounce.net/docs/add-on-api/testing`
- **Xvfb capture**: black frames reported with ffmpeg on Xvfb for other software. [CRW-2518](https://issues.redhat.com/browse/CRW-2518), [ffmpeg-user](https://lists.ffmpeg.org/pipermail/ffmpeg-user/2019-February/043540.html)

### Inference

- 1.21.4 sits on the older GLFW stack, so the Xvfb sRGB problem should not apply today, and 4 vCPU has real evidence of working (Wurst). **Any Paper upgrade to 26.x changes windowing and render backend**, so the harness should keep the render stack behind one seam and treat the upgrade as a test of its own.
- The harness must run on 4 vCPU, and a local Paper plus client plus llvmpipe share those cores. Wurst's sample does not include a separate Paper process.

Memory per client:

- No one publishes a rendered client figure. Best found: about 6 GB for two no-render bots including Paper, with dummy assets (reported, gp-headless-client). Mojang's stated 26.x minimum is reported at 8 GB or more by secondary sources. [GamingOnLinux](https://www.gamingonlinux.com/2026/07/minecraft-java-edition-system-requirements-get-bumped-up-ahead-of-vulkan-support/)

## 7. Multiple real clients against one server

### Verified

- Fabric's harness is one client per JVM: phaser and semaphores are static; the in-process dedicated server sets `max-players=1` to stop others joining. Concurrency therefore means several JVMs with no shared lockstep. [ThreadingImpl](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/impl/client/gametest/threading/ThreadingImpl.java), [package-info](https://github.com/FabricMC/fabric/blob/26.3/fabric-client-gametest-api-v1/src/client/java/net/fabricmc/fabric/api/client/gametest/v1/package-info.java)
- Malmo: each client takes its own port from 10000 up ("launch, say, four Minecraft clients"). Fresh world creation takes "many seconds even on a fast machine". [FAQ](https://github.com/microsoft/malmo/wiki/FAQ)
- MineRL's multi-agent env holds one instance per agent, with a role per instance, and a `refresh_instances_every` option described as a "band-aid to memory leaks". [_multiagent.py](https://github.com/minerllabs/minerl/blob/HEAD/minerl/env/_multiagent.py), [malmo.py](https://github.com/minerllabs/minerl/blob/HEAD/minerl/env/malmo.py)
- **grug-for-minecraft**: "on a 15GB machine, has to be at most two at a time". These are whole loader runs, mostly old versions, not clients on one server. [README](https://github.com/grug-lang/grug-for-minecraft/blob/HEAD/README.md)

### Reported

- **gp-headless-client** is the closest match: up to three real clients on one Paper server (Offline1 to Offline3), each `headlessmc launch --offline --headless --server`, no rendering. About 6 GB for two. "One run at a time per MC version" because ports and game dir are shared. [README](https://github.com/FreeMonoid/gp-headless-client)

### Not found

- Anyone running **several rendered clients** against one server in CI with published numbers.
- Any lockstep across client JVMs.
- A multi-client mode in Fabric's client game test API.

### Inference

- Two perceiving clients on 4 cores with llvmpipe plus Paper will contend badly. Expect a very small number (1 or 2) in a prototype, then measure. Only rendered clients need CPU for llvmpipe, so a multi-player requirement might mix one rendered observer with no-render clients, but that second client's view is then not verified.
- Each needs its own game dir, username, and offline mode. One Xvfb per client keeps video separate.

## Video recording precedent

### Verified

- **MinecraftModConventions `recordClientGameTest`** is the only Minecraft precedent found. It runs the client game test in its own Xvfb with ffmpeg `x11grab`, default 30 fps at 1920x1080, `libx264 veryfast crf 18`, private PulseAudio sink, and writes JSON metadata with tick and frame boundaries and capture gaps. A run fails if audio is not routed. [README](https://github.com/brainage04/MinecraftModConventions), [RecordClientGameTestTask](https://github.com/brainage04/MinecraftModConventions/blob/HEAD/gradle-plugin/client-gametest-recorder/src/main/java/io/github/brainage04/minecraftmodconventions/gradle/recorder/RecordClientGameTestTask.java)
- Lessons in its source: ffmpeg's default mux queue stops x11grab on a busy disk and leaves frame gaps, fixed with a queue of 4096 packets. Same file.
- KStars records Xvfb with x11grab in CI, general pattern. [.gitlab-ci.yml](https://invent.kde.org/lancaster/kstars/-/blob/cffc7f79f34362f65c220c16dc909abb5108bcf3/.gitlab-ci.yml)

### Inference

- x11grab shows the swap chain as presented, so test phase stalls show up as frozen video. Encoding also takes CPU from llvmpipe on 4 cores. Prototype must measure the slowdown and likely record only requirements under evidence or a failed retry, or assemble frames offline.
- It has 1 star, so read it for ideas rather than depend on it.

## Throughput against "hundreds in minutes"

### Inference from the data above

- Client boot 18 to 24 s, Paper boot about 15 s (reported), world creation about 8 s. Restarting per requirement is out: at 40 s each, 300 requirements take over 3 hours.
- Wurst reuses one client and one world at **about 2 s per test class**, with no external server. 300 at that rate is about 10 min on one client. Reaching "minutes" requires one long lived client, one long lived Paper, per-requirement isolation inside them, and capturing a failed run per requirement rather than stopping (section 1 runner note).
- Requirements that wait on game time cost real time at 20 ticks per second, as no speedup exists in the source. `/tick rate` or `/tick sprint` is unproven against client interpolation and needs its own check.
- Local Apple Silicon: Loom's Xvfb default applies only to Linux, so I expect a real window on a Mac. I found no precedent for hiding it or for rendering headless there.

## Open checks a prototype must answer

- Rendered client with external Paper 1.21.4 on 4 cores: scenario rate, frame rate, tick stability.
- Golden stability across repeated runs of pinned llvmpipe at a low threshold.
- Isolation between requirements in one client session (scoreboard, boss bars, resource packs, inventory, world state) and JEI style leak checks.
- Whether Fabric's lockstep helps or gets in the way with an external server.
- ffmpeg overhead and a failed-only recording strategy.
- Second rendered client: cost, and whether it is ever needed.
- macOS: backend used on 1.21.4, window behaviour, and how far its frames sit from llvmpipe.
