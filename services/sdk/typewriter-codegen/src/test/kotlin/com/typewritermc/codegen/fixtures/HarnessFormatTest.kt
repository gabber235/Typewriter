package com.typewritermc.codegen.fixtures

import com.tschuchort.compiletesting.SourceFile
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import org.jetbrains.kotlin.compiler.plugin.ExperimentalCompilerApi

/**
 * Pins the error formats [CompiledFixture] parses. A kctfork, KSP or Kotlin upgrade that changes them would otherwise
 * make every fixture assertion vacuous; here it fails loudly instead.
 */
@OptIn(ExperimentalCompilerApi::class)
val HarnessFormatTest by testSuite {
    test("processor errors parse with their file and line") {
        val compiled =
            FixtureCompiler.compile(
                listOf(
                    SourceFile.kotlin(
                        "Probe.kt",
                        """
                        package fixture

                        import com.typewritermc.discovery.TypewriterRegistrar

                        @TypewriterRegistrar("probe")
                        class Probe
                        """.trimIndent(),
                    ),
                ),
            )
        withClue(compiled.messages) {
            compiled.errors shouldContain ReportedError("Probe.kt", 6, "Typewriter registrars must implement RuntimeRegistrar.")
        }
    }

    test("compiler errors parse with their file and line") {
        val compiled =
            FixtureCompiler.compile(
                listOf(
                    SourceFile.kotlin(
                        "Probe.kt",
                        """
                        package fixture

                        val probe: Int = "text"
                        """.trimIndent(),
                    ),
                ),
            )
        withClue(compiled.messages) {
            compiled.errors.single { it.file == "Probe.kt" }.let { error ->
                (error.line to ("String" in error.message)) shouldBe (3 to true)
            }
        }
    }
}
