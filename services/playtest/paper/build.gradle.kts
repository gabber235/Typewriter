import org.gradle.internal.logging.progress.ProgressLoggerFactory
import org.gradle.process.ExecOperations
import xyz.jpenilla.runtask.service.DownloadsAPIService
import javax.inject.Inject

// The stock Paper server the game pool boots: downloaded through run-paper's shared download service
// and patched once here, so no boot pays for Paperclip's patching. The framework plugin compiles
// against the patched jars.
plugins {
    `java-base`
}

@CacheableTask
abstract class PreparePaper : DefaultTask() {
    @get:Internal
    abstract val downloads: Property<DownloadsAPIService>

    @get:Input
    abstract val minecraftVersion: Property<String>

    @get:Input
    abstract val paperBuild: Property<Int>

    @get:Nested
    abstract val launcher: Property<JavaLauncher>

    @get:OutputDirectory
    abstract val patched: DirectoryProperty

    @get:Inject
    abstract val progressLoggerFactory: ProgressLoggerFactory

    @get:Inject
    abstract val exec: ExecOperations

    @get:Inject
    abstract val files: FileSystemOperations

    @TaskAction
    fun prepare() {
        val download =
            downloads.get().resolveBuild(
                progressLoggerFactory,
                minecraftVersion.get(),
                DownloadsAPIService.Build.Specific(paperBuild.get()),
            )
        val target = patched.get().asFile
        files.delete { delete(target) }
        target.mkdirs()
        val paperclip = target.resolve("paper.jar")
        download.toFile().copyTo(paperclip)
        exec.exec {
            executable = launcher.get().executablePath.asFile.absolutePath
            args("-Dpaperclip.patchonly=true", "-jar", paperclip.absolutePath)
            workingDir = target
        }
    }
}

val minecraftRelease = libs.versions.minecraft.get()
val paperBuildNumber = 242

val preparePaper =
    tasks.register<PreparePaper>("preparePaper") {
        group = "playtest"
        description = "Downloads Paper $minecraftRelease build $paperBuildNumber and patches it once."
        val service = DownloadsAPIService.paper(project)
        downloads.set(service)
        @Suppress("UNCHECKED_CAST")
        usesService(service as Provider<out BuildService<*>>)
        minecraftVersion.set(minecraftRelease)
        paperBuild.set(paperBuildNumber)
        launcher.set(javaToolchains.launcherFor { languageVersion.set(JavaLanguageVersion.of(25)) })
        patched.set(layout.buildDirectory.dir("paper/$minecraftRelease-$paperBuildNumber"))
    }

configurations.consumable("patchedPaper") {
    outgoing.artifact(preparePaper.flatMap { it.patched })
}
