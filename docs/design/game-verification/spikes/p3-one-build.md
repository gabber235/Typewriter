# P3: One services Gradle build for every game verification piece

## Answer

- **Yes: the single services Gradle build holds every piece, no included build needed.** Configuration time is
  unchanged (the new projects configure in 31 ms) and the configuration cache holds. **Three existing build files
  needed changes** (listed below).
- Pieces, all in the services build:

  | Piece | Project | Result |
  |---|---|---|
  | Fabric client mod: Loom 1.19.3 `net.fabricmc.fabric-loom`, MC 26.3, Loader 0.20.1, API 0.165.0+26.3, Java 25, one mixin | `:playtest-client` | builds; no clash with Kotlin 2.4.21 (Loom brings kotlin-metadata-jvm 2.4.10 in its own child class loader) |
  | `writeClientLaunch` | `:playtest-client` | typed task, configuration cache safe; 142 classpath entries, 139 in modules-2 |
  | Paper 26.3 through `DownloadsAPIService.paper(project)`, patched with `-Dpaperclip.patchonly=true` | `:playtest-paper` | builds 200 and 242 both download and patch; `@CacheableTask`, restores FROM-CACHE |
  | Plugin compiled against patched internals (`ClientboundPingPacket`, `ServerTickEndEvent`) | `:playtest-plugin` | compiles (the packet is `net.minecraft.network.protocol.common`) |
  | Java agent with `Premain-Class` | `:playtest-agent` | builds |
  | `gameTest` source set and Test task in `com.typewritermc.game-test` | `:playtest` | 4 testBalloon tests pass; out of `check` only after excluding it from Kover |

- **Patching Paper stays in `check`** because the plugin compiles against the patched jar.
- **Cache cost for CI (not yet in any CI cache):** Loom about 700 MB (161 MB `fabric-loom/26.3`, 73 MB
  `minecraftMaven`, 474 MB assets, 73 MB per worktree `loom-cache`) and the patched Paper 216 MB (jar 53, versions 30,
  libraries 74, cache 60).

Machine and evidence: the developer's Apple silicon Mac, JetBrains JRE 25 as the Gradle daemon, Gradle 9.8.1, the
services build of a worktree. Evidence was 40 numbered log files plus Gradle profile reports; summarized below. Measured.

## Existing files changed

- **`build-logic/build.gradle.kts`**: `xyz.jpenilla:run-task:3.1.0` on the build-logic classpath. Without it the
  download service fails: detekt's sarif4k puts kotlinx-serialization-json 1.4.1 in the settings class loader
  (build-logic is a settings plugin), and run-task 3.1.0 needs 1.11.0 (`NoSuchMethodError
  JsonBuilder.setNamingStrategy`). It also removes the sibling class loader clash (`engine-paper` and `playtest-paper`
  each loading run-paper, so the shared service is a foreign class).
- **`runtime/engine/runtimes/paper/build.gradle.kts`**: run-paper plugin id without version (it is now on the
  classpath).
- **`build-logic/.../coverage-merge.gradle.kts`**: only projects with Kover join the root `kover` configuration;
  otherwise the root resolves the Loom project's Fabric dependencies from Maven Central and `check` fails.
- **`settings.gradle.kts`**: Fabric maven in `pluginManagement`, five `includeProject` lines.
- Also needed for `check`: Kover must skip `gameTest`
  (`kover.currentProject.instrumentation.disabledForTestTasks.add("gameTest")`), because `koverVerify` depends on
  every Test task.

## Configuration time (`help`, warm daemon)

| | Wall | Configuring projects |
|---|---|---|
| Before | 1.50 to 1.75 s | 0.631 s |
| After | 1.42 to 1.55 s | 0.563 s (playtest projects 31 ms) |
| After, configuration cache reused | 0.51 to 0.55 s | none |
| Fresh worktree (no `services/.gradle/loom-cache`) | 1.82 s | |
| Loom user cache removed, other caches warm | 4.33 s | Loom downloads and merges Mojang jars |

## Cache directories

| Path | Written by | Size | In CI cache today |
|---|---|---|---|
| `~/.gradle/caches/fabric-loom/26.3` | Loom at configuration | 161 MB | no |
| `~/.gradle/caches/fabric-loom/minecraftMaven` | Loom at configuration | 73 MB | no |
| `~/.gradle/caches/fabric-loom/assets` | `downloadAssets` | 474 MB | no |
| `services/.gradle/loom-cache` | Loom, per worktree | 73 MB | no |
| `~/.gradle/caches/modules-2` (MC libraries, Fabric) | Loom resolution | about +23 MB | yes |
| `~/.gradle/caches/run-task-jars/paper/jars/26.3/<build>.jar` | run-paper service | 53 MB each | no |
| `services/playtest/paper/build/paper/26.3-<build>` | `preparePaper` | 216 MB | no |
| `~/.gradle/caches/build-cache-1` | `preparePaper` with `--build-cache` | +208 MB per entry | no |

## What the numbered logs showed

| Files | What they show |
|---|---|
| `01` to `03` help | First attempts failed: dependencies cannot be declared against the `gameTestClientLaunch` configuration (19 s, 14 s), then a script compile error for `javaToolchains` in the Paper build file (24 s) |
| `04`, `05`, `baseline`, `after-profile`, `baseline-profile` | `help` works (5 s cold), then the before and after configuration time table above (baseline first run 29.28 s with daemon start; later runs 1.50 to 1.75 s; after 1.42 to 1.55 s) |
| `06` client | `runClient` was launched by Gradle (a real client started, 1 m 53 s, killed with exit 143): the `files(runClient.map { it.classpath })` trap |
| `07`, `08` | `--dry-run` and `writeClientLaunch` plus the agent jar build with `runClient` disabled (2 s) |
| `09` to `11`, `14` | Paper 242 failures: the run-task service type clash (`DownloadsAPIServiceImpl` could not be set from another class loader), service creation failure, then an unresolved import compiling the plugin; each fixed by the build-logic change |
| `12`, `13` | The Gradle daemon JVM and the build-logic runtime classpath, used to find the kotlinx-serialization clash |
| `15`, `16`, `17` | Plugin compiles against the patched jar (5 s), Paper 200 patches (6 s), up-to-date rerun (5 s) |
| `18` | `gameTest` runs the 4 testBalloon tests (4 s) |
| `19` to `22` | `check --dry-run`: first failed resolving `net.fabricmc:fabric-loader:0.20.1` through `koverExternalArtifacts` (the coverage-merge fix), then `check` dry runs pass, with and without coverage, showing `gameTest` still in the graph until Kover skips it |
| `23` to `26` | Configuration cache: `help` stored then reused (508 ms); `gameTest` first discarded with 3 problems (script object references in `writeClientLaunch` and `compileJava`), then 4 problems (file collection not assignable in the Test task), then stored and reused (548 ms) |
| `27`, `28` | Build cache: `preparePaper` runs in 11 s and restores FROM-CACHE in 3 s; `build-cache-1` grew from 6.5 MB |
| `29` to `31`, `cache-before` | Fresh worktree 1.82 s, cold and warm runs with and without Loom caches (warm 1.81 to 2.00 s, Loom cold 4.33 s), and the cache directory sizes |
| `32`, `33` | `check` for the playtest projects: ktlint script violations on the first run, then success (2 s) once fixed |

## Traps

- `files(runClient.map { it.classpath })` makes `runClient` a dependency: Gradle launched a real client. The
  prototype disables `runClient` and reads values from the task object.
- Kover makes `koverVerify` depend on every Test task, so `check` ran `gameTest`, `preparePaper` and
  `writeClientLaunch`.
- `writeClientLaunch` reads Loom's values at configuration: `workingDir` is the project dir, not `runDir`. The
  launch also needs `services/.gradle/loom-cache/projects/playtest-client/launch.cfg` and
  `build/loom-cache/argFiles/runClient`, which are not its outputs.

## Surprises

- The build failure that looked like a Paper problem was a class loader clash: the settings plugin classpath, shaped by
  detekt, decides which kotlinx-serialization every project's parent loader sees.
- Two projects each loading run-paper clash even though each works alone.
- Configuration cache problems were all in the new tasks, none in existing builds.

## What this means for the search

- One services build is the right home; an included build adds nothing. Slice 1 takes the three build file fixes
  (`run-task` in build-logic, Kover skips `gameTest`, coverage-merge takes only Kover projects).
- Open: how CI caches Loom (about 700 MB) and the patched Paper (about 216 MB).

## Rerun

The code lived on branch `proto/gv-build` at commit `abad68436` (`services/playtest/` with `client`, `paper`, `plugin`,
`agent` and `framework` projects) and this branch is deleted, so the commands are kept only as a record: from
`services`, `./gradlew help`, `:playtest-client:writeClientLaunch :playtest-agent:jar`, `:playtest-paper:preparePaper`,
`:playtest-plugin:compileKotlin`, `:playtest:gameTest`, `check --dry-run`, with and without
`--no-configuration-cache`, and `--profile` for the timing tables.

## Reuse

- The `com.typewritermc.game-test` convention plugin and `gameTest` source set.
- `PlaytestClient.java` and `MinecraftMixin.java` (the Loom client mod with one mixin), `Agent.java`,
  `PlaytestPlugin.kt`.
- The `preparePaper` task using `DownloadsAPIService`, and the typed `writeClientLaunch` task.
