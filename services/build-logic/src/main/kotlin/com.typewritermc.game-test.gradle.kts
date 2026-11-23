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
// out; `cargo xtask e2e game` runs them.
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
 * What this module adds to every Paper the pool boots: [pluginJars] go into `plugins/`, [files] into
 * Paper's folder at the paths it names, and [environment] is set for Paper's process.
 * [typewriterExtensions] go to the game stack's Realm, which deploys them to the Typewriter engine of
 * every game Paper. Every module's
 * gameTest shares the build's pool and its Papers, so the pool takes the union of every module's
 * additions; two modules that disagree on a file or a variable fail before Paper starts.
 *
 * Each Paper runs in a slot, which it finds in `PLAYTEST_PAPER_SLOT`: the shared Paper in 0, the own
 * Papers of restart requirements in 1 and 2, each taking a free slot and freeing it when it ends.
 * [slot] adds environment for one slot's Paper only, and [keptPerSlot] names paths in Paper's folder a
 * slot keeps: what one own Paper wrote there is in the slot's next own Paper too.
 *
 * ```
 * gamePaper {
 *     pluginJars.from(project(":loader-distribution"))
 *     environment.put("TYPEWRITER_CONFIG_FILE", configFile)
 *     slot(0) { environment.put("TYPEWRITER_REGISTRATION_TOKEN_FILE", tokenOfSlot0) }
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

        /**
         * The Typewriter extensions the game stack's Realm deploys to every game Paper's engine, by
         * project: `typewriterExtensions.from(project(":playtest-bridge"))`. Not `extensions`, which every
         * Gradle extension object already has for its own extensions. `cargo xtask e2e game` installs the
         * extensions of every game module into the Realm host's inbox before the stack starts; panel
         * stacks and development Papers never get them.
         */
        val typewriterExtensions = GameExtensions(project)

        fun files(action: Action<CopySpec>) = action.execute(files)

        /** Adds to the Paper of slot [slot] only. */
        fun slot(
            slot: Int,
            action: Action<GamePaperSlot>,
        ) = action.execute(slots.getOrPut(slot) { project.objects.newInstance(GamePaperSlot::class.java) })
    }

/** The extension projects a game module adds to the game stack's Realm, as [GamePaper.typewriterExtensions]. */
class GameExtensions(
    private val project: Project,
) {
    /** Adds the Imprint extension [extension] builds. */
    fun from(extension: Project) {
        project.dependencies.add(SCOPE, project.dependencies.project(mapOf("path" to extension.path, "configuration" to "runtimeElements")))
    }

    companion object {
        /** The dependency scope that holds the extension projects. */
        const val SCOPE = "playtestGameExtensionsScope"
    }
}

/** What one slot's Paper adds to the environment every Paper of the build starts with. */
abstract class GamePaperSlot {
    abstract val environment: MapProperty<String, String>
}

val gameExtensionsScope = configurations.dependencyScope(GameExtensions.SCOPE)
val gamePaper = extensions.create<GamePaper>("gamePaper", project)

// This module's game extensions as one folder of extension jars, which the root project's
// `installGameExtensions` gathers from every game module. Only each extension's own jar, never what
// it depends on: the engine provides those.
val gameExtensionJars =
    configurations.resolvable("playtestGameExtensionJars") {
        extendsFrom(gameExtensionsScope.get())
        isTransitive = false
    }
val gameExtensionsDir = layout.buildDirectory.dir("playtest/game-extensions")
val collectGameExtensions =
    tasks.register<Sync>("playtestGameExtensions") {
        description = "Collects the extension jars this module adds to the game stack's Realm."
        from(gameExtensionJars)
        into(gameExtensionsDir)
    }
configurations.consumable("playtestGameExtensions") {
    outgoing.artifact(gameExtensionsDir) { builtBy(collectGameExtensions) }
}

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

// Every module's additions reach the pool, whichever gameTest task starts it.
val allPaperAdditionsScope = configurations.dependencyScope("playtestAllPaperAdditionsScope")
rootProject.subprojects.forEach { gameModule ->
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

    /** The file of lines the change added; a requirement that covered one reruns in demo mode. */
    @get:Internal abstract val touched: Property<String>

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
                listOf("repeat" to repeat, "quarantine" to quarantine, "touched" to touched)
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
    usesService(gameRun)
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
            clients.set(providers.gradleProperty("playtest.clients").map(String::toInt).orElse(4))
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
            root.set(repositoryRoot.path)
            goldens.set(projectDir.resolve("src/gameTest/goldens").relativeTo(repositoryRoot).invariantSeparatorsPath)
            // `cargo xtask goldens approve` keeps each approved frame here; a run diffs against it.
            goldenImages.set(servicesDirectory.resolve("build/playtest/goldens").path)
            // devenv.nix exports the Mesa it ships, so the pin moves with nixpkgs.
            mesa.set(providers.environmentVariable("PLAYTEST_MESA"))
            // CI's game job runs on the pinned runner and says so; other machines only note frames they cannot check.
            pinnedRunner.set(providers.environmentVariable("PLAYTEST_PINNED_RUNNER").map { it == "1" }.orElse(false))
        }
    jvmArgumentProviders += parts
    // The build's pool runs before the first test JVM starts, which only connects to it.
    doFirst { gameRun.get().ensurePool(parts) }
}

// `cargo xtask e2e game` builds everything gameTest runs in a Gradle of its own first, so the Kotlin
// compile daemons end with that Gradle and hold no memory while the suite runs.
tasks.register("gameTestBuild") {
    description = "Builds everything gameTest runs, and runs nothing."
    group = "build"
    dependsOn(gameTest.output, gameTest.runtimeClasspath, poolPart, paperPart, agentPart, pluginPart, coverageAgentPart, clientLaunchPart, allPaperAdditions)
}
