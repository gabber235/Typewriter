package com.typewritermc.codegen.fixtures

import com.tschuchort.compiletesting.SourceFile
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldContain
import org.jetbrains.kotlin.compiler.plugin.ExperimentalCompilerApi

/** The processor reports invalid KSP options once, without a location, instead of failing the run. */
@OptIn(ExperimentalCompilerApi::class)
val ProcessorOptionsTest by testSuite {
    val source = listOf(SourceFile.kotlin("Empty.kt", "package fixture\n"))

    test("missing options are reported") {
        val compiled = FixtureCompiler.compile(source, FixtureCompiler.OPTIONS - "typewriter.artifactId")
        withClue(compiled.messages) {
            compiled.errors shouldContain ReportedError("", 0, "Missing KSP option typewriter.artifactId.")
        }
    }

    test("a source part that cannot be an index column is reported") {
        val compiled = FixtureCompiler.compile(source, FixtureCompiler.OPTIONS + ("typewriter.sourcePart" to "two words"))
        withClue(compiled.messages) {
            compiled.errors shouldContain
                ReportedError("", 0, "KSP option typewriter.sourcePart must be a letter followed by letters, digits or underscores.")
        }
    }
}
