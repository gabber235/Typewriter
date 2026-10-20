package com.typewritermc.codegen.fixtures

import com.tschuchort.compiletesting.JvmCompilationResult
import com.tschuchort.compiletesting.KotlinCompilation
import com.tschuchort.compiletesting.SourceFile
import com.tschuchort.compiletesting.configureKsp
import com.tschuchort.compiletesting.kspSourcesDir
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.imprint.codegen.ImprintRuntimeEntrypointProcessorProvider
import com.typewritermc.types.codegen.TypewriterTypeProcessorProvider
import org.jetbrains.kotlin.compiler.plugin.ExperimentalCompilerApi
import java.io.OutputStream
import java.lang.reflect.InvocationTargetException
import java.nio.file.Path
import kotlin.io.path.copyTo
import kotlin.io.path.createParentDirectories
import kotlin.io.path.exists
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.io.path.nameWithoutExtension
import kotlin.io.path.readText

/**
 * Compiles a fixture in process with the module's own processors, on the test classpath (which includes
 * typewriter-api), so a fixture compiles exactly like a Typewriter module.
 */
@OptIn(ExperimentalCompilerApi::class)
object FixtureCompiler {
    /** KSP2 uses each source's directory as a source root, so fixture files are copied into the compilation's own sources. */
    fun compile(fixture: Fixture): CompiledFixture = compile(fixture.files.map { SourceFile.kotlin(it.name, it.readText()) })

    /** The options every Typewriter module passes; tests override them to exercise option validation. */
    val OPTIONS: Map<String, String> =
        mapOf(
            "typewriter.artifactId" to "typewritermc:compiler-fixture",
            "typewriter.sourcePart" to "fixture",
            "typewriter.claimDependencyClosure" to "false",
        )

    fun compile(
        sources: List<SourceFile>,
        options: Map<String, String> = OPTIONS,
    ): CompiledFixture {
        val compilation =
            KotlinCompilation().apply {
                this.sources = sources
                inheritClassPath = true
                jvmTarget = "21"
                kotlincArguments = kotlincArguments + "-Xcontext-parameters"
                messageOutputStream = OutputStream.nullOutputStream()
                configureKsp {
                    symbolProcessorProviders += listOf(TypewriterTypeProcessorProvider(), ImprintRuntimeEntrypointProcessorProvider())
                    processorOptions += options
                }
            }
        return CompiledFixture(compilation.compile(), compilation.kspSourcesDir.toPath())
    }
}

@OptIn(ExperimentalCompilerApi::class)
class CompiledFixture(
    private val result: JvmCompilationResult,
    private val kspSources: Path,
) {
    val exitCode: KotlinCompilation.ExitCode = result.exitCode

    /** The raw compiler and processor messages, for failure output. */
    val messages: String = result.messages

    /**
     * KSP logger errors (`e: [ksp] /abs/File.kt:12: msg`) and compiler errors (`e: file:///abs/File.kt:12:5 msg`).
     * Errors without a location are kept with an empty file, so they count as unexpected.
     */
    val errors: List<ReportedError> =
        result.messages.lines().mapNotNull { line ->
            (KSP_ERROR.matchEntire(line) ?: KOTLIN_ERROR.matchEntire(line))?.destructured?.let { (path, number, message) ->
                ReportedError(Path.of(path).name, number.toInt(), message.trim())
            } ?: UNLOCATED_ERROR.matchEntire(line)?.let { ReportedError("", 0, it.groupValues[1].trim()) }
        }

    /**
     * Runs the fixture's `main(args)` with the artifact (the compiled classes plus the KSP provider index) as its only
     * argument. Fails when [fixture] declares `main` but no compiled file facade exposes it.
     */
    fun runMain(fixture: Fixture) {
        val declaresMain = fixture.files.any { MAIN.containsMatchIn(it.readText()) }
        val artifact = result.outputDirectory.toPath()
        val entry =
            artifact
                .resolve("fixture")
                .takeIf { it.exists() }
                ?.listDirectoryEntries("*.class")
                .orEmpty()
                .filterNot { '$' in it.name }
                .map { result.classLoader.loadClass("fixture.${it.nameWithoutExtension}") }
                .firstNotNullOfOrNull { facade -> runCatching { facade.getMethod("main", Array<String>::class.java) }.getOrNull() }
        if (entry == null) {
            check(!declaresMain) { "Fixture ${fixture.name} declares main, but no compiled file facade exposes main(Array<String>)." }
            return
        }
        val index = kspSources.resolve("resources").resolve(GENERATED_PROVIDER_INDEX_PATH)
        if (index.exists()) index.copyTo(artifact.resolve(GENERATED_PROVIDER_INDEX_PATH).createParentDirectories(), overwrite = true)
        try {
            entry.invoke(null, arrayOf(artifact.toString()))
        } catch (failure: InvocationTargetException) {
            throw failure.targetException
        }
    }

    private companion object {
        val KSP_ERROR = Regex("""e: \[ksp] (/.+\.kt):(\d+): (.+)""")
        val KOTLIN_ERROR = Regex("""e: file://(.+\.kt):(\d+):\d+ (.+)""")

        /** Any other error line, except the generic notice KSP adds before its own located errors. */
        val UNLOCATED_ERROR = Regex("""e: (?:\[ksp] )?(?!Error occurred in KSP, check log for detail)(.+)""")
        val MAIN = Regex("""^fun main\(""", RegexOption.MULTILINE)
    }
}
