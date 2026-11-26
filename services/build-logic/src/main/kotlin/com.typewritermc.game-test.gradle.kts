import com.typewritermc.buildlogic.repositoryRoot
import com.typewritermc.buildlogic.servicesDirectory
import com.typewritermc.playtest.launch.PoolFile
import com.typewritermc.playtest.launch.PoolProcess
import java.nio.file.Path
import java.util.Properties
import java.util.UUID
import javax.inject.Inject

// Game requirements: tests in the `gameTest` source set run against real Minecraft clients on a
// stepped Paper, which the game pool boots. They are slow and need a desktop, so `check` leaves them
// out; `cargo xtask e2e playtest` runs the framework's own, and `cargo xtask e2e game` the product's.
plugins {
    id("com.typewritermc.basic-conventions")
}

val gameTest = sourceSets.create("gameTest")

configurations.named(gameTest.implementationConfigurationName) { extendsFrom(configurations.getByName("testImplementation")) }
configurations.named(gameTest.runtimeOnlyConfigurationName) { extendsFrom(configurations.getByName("testRuntimeOnly")) }
kotlin.target.compilations.named("gameTest") { associateWith(kotlin.target.compilations.getByName("main")) }

kover {
    currentProject { instrumentation { disabledForTestTasks.add("gameTest") } }
}

/** A resolvable path to one part of the game another project builds. */
fun gamePart(
    name: String,
    path: String,
    configuration: String,
): NamedDomainObjectProvider<ResolvableConfiguration> {
    val scope =
        configurations.dependencyScope("${name}Scope") {
            dependencies.add(project.dependencies.project(mapOf("path" to path, "configuration" to configuration)))
        }
    return configurations.resolvable(name) { extendsFrom(scope.get()) }
}

val poolPart = gamePart("playtestPool", ":playtest-pool", "runtimeElements")
val paperPart = gamePart("playtestPaper", ":playtest-paper", "patchedPaper")
val agentPart = gamePart("playtestAgent", ":playtest-agent", "runtimeElements")
val pluginPart = gamePart("playtestPlugin", ":playtest-plugin", "playtestPlugin")
val clientLaunchPart = gamePart("playtestClientLaunch", ":playtest-client", "playtestClientLaunch")
val coverageAgentPart = gamePart("playtestCoverageAgent", ":playtest-plugin", "playtestCoverageAgent")

/**
 * The game suite a module's requirements belong to: `playtest` for the framework's own modules (under
 * `services/playtest`), whose Papers need no stack, and `game` for the product's, which run inside it.
 */
fun Project.gameSuite(): String = if (projectDir.startsWith(servicesDirectory.resolve("playtest"))) "playtest" else "game"

/**
 * The suite this build runs (`-Pplaytest.suite`, which `cargo xtask e2e <suite>` passes): only that
 * suite's modules run their requirements, and its Papers carry only their additions. A build that names
 * none runs every module's requirements on one pool.
 */
val runSuite: String? = providers.gradleProperty("playtest.suite").orNull

/** Whether this module's requirements run in this build: it belongs to the suite the build runs. */
val inRun = runSuite == null || project.gameSuite() == runSuite

/**
 * How this module's requirements are judged. [pacing] says what a requirement whose windows hold at
 * another tick at another pace does: `gates` (the default) fails it, `reports` lists it without
 * blocking, for a module whose code still waits on work no tick waits for.
 *
 * ```
 * gameRequirements {
 *     pacing.set("reports")
 * }
 * ```
 */
abstract class GameRequirements {
    abstract val pacing: Property<String>
}

val gameRequirements = extensions.create<GameRequirements>("gameRequirements").apply { pacing.convention("gates") }

/**
 * What this module adds to every Paper the pool boots: [pluginJars] go into `plugins/`, [files] into
 * Paper's folder at the paths it names, and [environment] is set for Paper's process. Every module's
 * gameTest shares the build's pool and its Papers, so the pool takes the union of the additions of every
 * module of the suite the build runs; two modules that disagree on a file or a variable fail before
 * Paper starts.
 *
 * Each Paper runs in a slot, which it finds in `PLAYTEST_PAPER_SLOT`: the shared Paper in 0, the own
 * Papers of restart requirements in 1 and 2, each taking a free slot and freeing it when it ends.
 * [slot] adds environment for one slot's Paper only, and [keptPerSlot] names paths in Paper's folder a
 * slot keeps: what one own Paper wrote there is in the slot's next own Paper too.
 *
 * A value only the run knows, such as a path the running stack publishes, comes from the environment the
 * game suite runs in through [fromRun]: the build never reads it, so the game build needs no stack.
 *
 * ```
 * gamePaper {
 *     pluginJars.from(project(":loader-distribution"))
 *     environment.put("TYPEWRITER_CONFIG_FILE", fromRun("TYPEWRITER_CONFIG_FILE"))
 *     slot(0) { environment.put("TYPEWRITER_REGISTRATION_TOKEN_FILE", "${fromRun("ENGINES")}/0/registration-token") }
 *     keptPerSlot.add("plugins/Typewriter/state")
 * }
 * ```
 */
abstract class GamePaper
    @Inject
    constructor(
        private val project: Project,
    ) {
        abstract val pluginJars: ConfigurableFileCollection

        abstract val environment: MapProperty<String, String>

        /** Paths in Paper's folder each slot keeps across its own Papers. */
        abstract val keptPerSlot: ListProperty<String>

        /** The files that go into Paper's folder, by their path in it. */
        val files: CopySpec = project.copySpec()

        /** What only the Paper of each slot adds, by slot. */
        val slots: MutableMap<Int, GamePaperSlot> = mutableMapOf()

        fun files(action: Action<CopySpec>) = action.execute(files)

        /** The variable [name] of the environment the game suite runs in, which the pool fills in as each Paper boots. */
        fun fromRun(name: String): String = "\${$name}"

        /** Adds to the Paper of slot [slot] only. */
        fun slot(
            slot: Int,
            action: Action<GamePaperSlot>,
        ) = action.execute(slots.getOrPut(slot) { project.objects.newInstance(GamePaperSlot::class.java) })
    }

/** What one slot's Paper adds to the environment every Paper of the build starts with. */
abstract class GamePaperSlot {
    abstract val environment: MapProperty<String, String>
}

val gamePaper = extensions.create<GamePaper>("gamePaper", project)

val paperAdditionsDir = layout.buildDirectory.dir("playtest/paper-additions")

/** This module's files for Paper's folder, as the pool reads them: `files/` of its additions. */
val paperAdditionFiles =
    tasks.register<Sync>("playtestPaperFiles") {
        description = "Collects the files this module adds to every Paper of the game pool."
        into(paperAdditionsDir.map { it.dir("files") })
        into("plugins") { from(gamePaper.pluginJars) }
        with(gamePaper.files)
    }

/**
 * This module's environment and kept paths for Paper, as the pool reads them from its additions:
 * `env.properties` for every Paper, `slots/<n>/env.properties` for slot n's, and `kept.txt`.
 */
abstract class WritePaperEnvironment : DefaultTask() {
    @get:Input abstract val environment: MapProperty<String, String>

    /** Each slot's environment, by slot. */
    @get:Input abstract val slotEnvironments: MapProperty<Int, Map<String, String>>

    @get:Input abstract val kept: ListProperty<String>

    @get:OutputFile abstract val file: RegularFileProperty

    @get:OutputDirectory abstract val slots: DirectoryProperty

    @get:OutputFile abstract val keptFile: RegularFileProperty

    @TaskAction
    fun write() {
        write(file.get().asFile, environment.get())
        slots.get().asFile.apply { deleteRecursively() }
        slotEnvironments.get().forEach { (slot, environment) ->
            write(slots.get().dir(slot.toString()).file("env.properties").asFile.also { it.parentFile.mkdirs() }, environment)
        }
        slots.get().asFile.mkdirs()
        keptFile.get().asFile.writeText(kept.get().joinToString("\n"))
    }

    private fun write(
        file: File,
        environment: Map<String, String>,
    ) {
        val properties = Properties().apply { putAll(environment) }
        file.outputStream().use { properties.store(it, null) }
    }
}

val paperAdditionEnvironment =
    tasks.register<WritePaperEnvironment>("playtestPaperEnvironment") {
        description = "Writes the environment and the kept paths this module sets for the Papers of the game pool."
        environment.set(gamePaper.environment)
        slotEnvironments.set(provider { gamePaper.slots.mapValues { (_, slot) -> slot.environment.get() } })
        kept.set(gamePaper.keptPerSlot)
        file.set(paperAdditionsDir.map { it.file("env.properties") })
        slots.set(paperAdditionsDir.map { it.dir("slots") })
        keptFile.set(paperAdditionsDir.map { it.file("kept.txt") })
    }

configurations.consumable("playtestPaperAdditions") {
    outgoing.artifact(paperAdditionsDir) { builtBy(paperAdditionFiles, paperAdditionEnvironment) }
}

// The additions of every module of the run's suite reach the pool, whichever of their gameTest tasks starts it.
val allPaperAdditionsScope = configurations.dependencyScope("playtestAllPaperAdditionsScope")
rootProject.subprojects.forEach { gameModule ->
    if (runSuite != null && gameModule.gameSuite() != runSuite) return@forEach
    gameModule.pluginManager.withPlugin("com.typewritermc.game-test") {
        dependencies.add(
            allPaperAdditionsScope.name,
            dependencies.project(mapOf("path" to gameModule.path, "configuration" to "playtestPaperAdditions")),
        )
    }
}
val allPaperAdditions = configurations.resolvable("playtestAllPaperAdditions") { extendsFrom(allPaperAdditionsScope.get()) }

/**
 * One run per build: every gameTest task of the build, in whichever project, reports into the same run
 * file under the same run id, as their test JVMs share one pool. The run owns that pool: the first
 * gameTest task to run starts it, and the build's end closes it, so Gradle exits, and `cargo xtask`
 * gives up the heavy lock, only once the pool and its game are gone. A pool that crashed is not started
 * again: the sessions after it fail at once, and its run file reads cut short.
 */
abstract class GameRun :
    BuildService<GameRun.Params>,
    AutoCloseable {
    interface Params : BuildServiceParameters {
        val id: Property<String>
    }

    val id: String get() = parameters.id.get()

    private var started = false
    private var pool: PoolProcess? = null

    /** Starts the run's pool from [parts], unless an earlier gameTest task of the build started it. */
    @Synchronized
    fun ensurePool(parts: GameParts) {
        if (started) return
        started = true
        pool =
            PoolProcess.start(
                PoolProcess.command(parts.java.get(), parts.properties(), parts.pool.asPath),
                Path.of(parts.logs.get(), "pool.log"),
                Path.of(parts.poolDir.get(), PoolFile.NAME),
                id,
            )
    }

    /** Ends the pool's run, as the build ends: the pool stops its game and exits, or is killed. */
    @Synchronized
    override fun close() {
        pool?.close()
    }
}

val gameRun =
    gradle.sharedServices.registerIfAbsent("playtestGameRun", GameRun::class) {
        // `cargo xtask e2e game` names the run, so it tells its run file from one an earlier run left;
        // a build outside xtask makes a fresh one.
        parameters.id.set(providers.gradleProperty("playtest.runId").orElse(UUID.randomUUID().toString()))
    }

/** The `-Dplaytest.*` properties of the run, which the session reads and the build's pool starts with. */
abstract class GameParts : CommandLineArgumentProvider {
    @get:Classpath abstract val pool: ConfigurableFileCollection

    @get:InputFiles @get:PathSensitive(PathSensitivity.RELATIVE) abstract val paper: ConfigurableFileCollection

    @get:Classpath abstract val agent: ConfigurableFileCollection

    @get:Classpath abstract val plugin: ConfigurableFileCollection

    @get:Classpath abstract val coverageAgent: ConfigurableFileCollection

    @get:InputFiles @get:PathSensitive(PathSensitivity.NONE) abstract val clientLaunch: ConfigurableFileCollection

    /** Every game module's additions to Paper, one folder each. */
    @get:InputFiles @get:PathSensitive(PathSensitivity.RELATIVE) abstract val paperAdditions: ConfigurableFileCollection

    @get:Input abstract val java: Property<String>

    /** The packages of the build's own code, the only classes coverage counts. */
    @get:Input abstract val coveredPackages: ListProperty<String>

    /** How many warm clients the pool keeps. */
    @get:Input abstract val clients: Property<Int>

    @get:Internal abstract val runId: Property<String>

    @get:Internal abstract val poolDir: Property<String>

    @get:Internal abstract val testRun: Property<String>

    /** The run's logs folder: the pool's, every Paper's and every client's. */
    @get:Internal abstract val logs: Property<String>

    /** Attempts of each requirement; absent, a failed attempt runs again up to 4 in total. */
    @get:Internal abstract val repeat: Property<String>

    /** The requirements the quarantine holds: they run once and never block. */
    @get:Internal abstract val quarantine: Property<String>

    /** The file of lines the change added; a requirement it touched runs again at each of [paces]. */
    @get:Internal abstract val touched: Property<String>

    /** The paces, in milliseconds between ticks, a touched requirement whose attempts passed runs at once more each. */
    @get:Internal abstract val paces: Property<String>

    /** Whether a window held at another tick at another pace gates or reports, as the module's [GameRequirements] say. */
    @get:Internal abstract val pacing: Property<String>

    /** Whether the run is a demo: each requirement runs once, its clients recording clips. */
    @get:Internal abstract val demo: Property<String>

    /** The repository root, which golden paths start from. */
    @get:Internal abstract val root: Property<String>

    /** This project's golden files, from the repository root. */
    @get:Internal abstract val goldens: Property<String>

    /** The local golden images, each named by the hash of its frame. */
    @get:Internal abstract val goldenImages: Property<String>

    /** The Mesa release devenv ships, which the pinned renderer draws with. */
    @get:Internal abstract val mesa: Property<String>

    /** Whether this machine is the pinned runner, where a frame from another renderer fails its golden. */
    @get:Internal abstract val pinnedRunner: Property<Boolean>

    /** The cgroup the run's tree gives the game, where the pool runs each part in a leaf of its own. */
    @get:Internal abstract val cgroup: Property<String>

    override fun asArguments() = properties().map { (name, value) -> "-D$name=$value" }

    /** Every property by its full name. */
    fun properties(): Map<String, String> =
        (
            mapOf(
                "poolDir" to poolDir.get(),
                "java" to java.get(),
                "paper" to paper.singleFile.path,
                "agent" to agent.singleFile.path,
                "plugin" to plugin.singleFile.path,
                "coverageAgent" to coverageAgent.singleFile.path,
                "clientLaunch" to clientLaunch.singleFile.path,
                "paperAdditions" to paperAdditions.files.joinToString(File.pathSeparator) { it.path },
                "clients" to clients.get().toString(),
                "coveredPackages" to coveredPackages.get().joinToString(","),
                "run" to runId.get(),
                "testRun" to testRun.get(),
                "logs" to logs.get(),
                "root" to root.get(),
                "goldens" to goldens.get(),
                "goldenImages" to goldenImages.get(),
                "mesa" to mesa.get(),
                "pinnedRunner" to pinnedRunner.get().toString(),
            ) +
                listOf(
                    "repeat" to repeat,
                    "quarantine" to quarantine,
                    "touched" to touched,
                    "paces" to paces,
                    "pacing" to pacing,
                    "demo" to demo,
                    "cgroup" to cgroup,
                )
                    .mapNotNull { (name, value) -> value.orNull?.let { name to it } }
        ).mapKeys { (name, _) -> "playtest.$name" }
}

tasks.register<Test>("gameTest") {
    description = "Runs the game requirements against real Minecraft clients on a stepped Paper."
    group = "verification"
    testClassesDirs = gameTest.output.classesDirs
    classpath = gameTest.runtimeClasspath
    // The game's state lives outside Gradle's view, so a game run is never up to date.
    outputs.upToDateWhen { false }
    // `cargo xtask e2e game --only` selects across every game module, so a module may hold none of
    // the selected requirements. Whether a selected id matched nothing is the whole run's question,
    // and xtask's selection check (`results::selection_matches`) answers it from the run file.
    filter.isFailOnNoMatchingTests = false
    // The test JVM only drives the game and compares what it reports; the clients and Papers hold the
    // game's memory. Its heap counts toward Gradle's test run limit (`cgroup::GRADLE_TEST_MIB`).
    maxHeapSize = "512m"
    usesService(gameRun)
    val runs = inRun
    onlyIf("its module is in the suite the build runs") { runs }
    val parts =
        objects.newInstance<GameParts>().apply {
            pool.from(poolPart)
            paper.from(paperPart)
            agent.from(agentPart)
            plugin.from(pluginPart)
            coverageAgent.from(coverageAgentPart)
            clientLaunch.from(clientLaunchPart)
            paperAdditions.from(allPaperAdditions)
            // Libraries the plugins bundle stay out: two plugins can bundle one in different versions.
            coveredPackages.set(listOf("com.typewritermc"))
            java.set(javaToolchains.launcherFor { languageVersion.set(JavaLanguageVersion.of(25)) }.map { it.executablePath.asFile.path })
            // `cargo xtask e2e game --clients 1` passes `-Pplaytest.clients=1`: a pool of one client.
            clients.set(providers.gradleProperty("playtest.clients").map(String::toInt).orElse(3))
            runId.set(gameRun.map { it.id })
            poolDir.set(servicesDirectory.resolve("build/playtest/pool").path)
            // `cargo xtask e2e game` names the run file it gates on; other runs keep theirs in the build.
            testRun.set(providers.gradleProperty("playtest.testRun").orElse(servicesDirectory.resolve("build/playtest/test_run.json").path))
            // It names a logs folder of the run's own too; other runs share one in the build.
            logs.set(providers.gradleProperty("playtest.logs").orElse(servicesDirectory.resolve("build/playtest/logs").path))
            repeat.set(providers.gradleProperty("playtest.repeat"))
            quarantine.set(providers.gradleProperty("playtest.quarantine"))
            // `cargo xtask e2e game` writes it against the merge base with the default branch.
            touched.set(providers.gradleProperty("playtest.touched"))
            // `cargo xtask e2e` names the paces a touched requirement runs at again, and a demo run.
            paces.set(providers.gradleProperty("playtest.paces"))
            pacing.set(gameRequirements.pacing)
            demo.set(providers.gradleProperty("playtest.demo"))
            root.set(repositoryRoot.path)
            goldens.set(projectDir.resolve("src/gameTest/goldens").relativeTo(repositoryRoot).invariantSeparatorsPath)
            // `cargo xtask goldens approve` keeps each approved frame here; a run diffs against it.
            goldenImages.set(servicesDirectory.resolve("build/playtest/goldens").path)
            // devenv.nix exports the Mesa it ships, so the pin moves with nixpkgs.
            mesa.set(providers.environmentVariable("PLAYTEST_MESA"))
            // CI's game job runs on the pinned runner and says so; other machines only note frames they cannot check.
            pinnedRunner.set(providers.environmentVariable("PLAYTEST_PINNED_RUNNER").map { it == "1" }.orElse(false))
            // `cargo xtask e2e` names it where the machine delegates a cgroup to the run (Linux CI).
            cgroup.set(providers.environmentVariable("PLAYTEST_CGROUP"))
        }
    jvmArgumentProviders += parts
    // The build's pool runs before the first test JVM starts, which only connects to it.
    doFirst { gameRun.get().ensurePool(parts) }
}

// `cargo xtask e2e game` builds everything gameTest runs in a Gradle of its own first, so the Kotlin
// compile daemons end with that Gradle and hold no memory while the suite runs.
val gameTestBuild =
    tasks.register("gameTestBuild") {
        description = "Builds everything gameTest runs, and runs nothing."
        group = "build"
        if (inRun) {
            dependsOn(gameTest.output, gameTest.runtimeClasspath, poolPart, paperPart, agentPart, pluginPart, coverageAgentPart, clientLaunchPart, allPaperAdditions)
        }
    }

// The game build needs no running stack, so the stack's builds and this one can share one Gradle.
// `check` runs where no stack runs, which holds that requirement.
tasks.named("check") { dependsOn(gameTestBuild) }
