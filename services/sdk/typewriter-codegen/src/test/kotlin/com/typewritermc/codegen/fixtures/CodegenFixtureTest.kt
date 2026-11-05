package com.typewritermc.codegen.fixtures

import com.tschuchort.compiletesting.KotlinCompilation
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import org.jetbrains.kotlin.compiler.plugin.ExperimentalCompilerApi

/**
 * Every codegen diagnostic has a rejected fixture that asserts its exact file, line and message; accepted fixtures
 * compile without errors and run their `main`.
 */
@OptIn(ExperimentalCompilerApi::class)
val CodegenFixtureTest by testSuite {
    Fixture.all("rejected").forEach { fixture ->
        test("rejects ${fixture.name}") {
            val compiled = FixtureCompiler.compile(fixture)
            val (missing, unexpected) = fixture.expectedErrors.pairWith(compiled.errors)
            withClue(
                "Expected errors:\n${fixture.expectedErrors.joinToString("\n")}\n" +
                    "Reported errors:\n${compiled.errors.joinToString("\n")}\n" +
                    "Missing: $missing\nUnexpected: $unexpected",
            ) {
                fixture.expectedErrors.isEmpty() shouldBe false
                (missing + unexpected).shouldBeEmpty()
                compiled.exitCode shouldBe KotlinCompilation.ExitCode.COMPILATION_ERROR
            }
        }
    }
    Fixture.all("accepted").forEach { fixture ->
        test("accepts ${fixture.name}") {
            val compiled = FixtureCompiler.compile(fixture)
            withClue(compiled.messages) {
                compiled.errors.shouldBeEmpty()
                compiled.exitCode shouldBe KotlinCompilation.ExitCode.OK
            }
            compiled.runMain(fixture)
        }
    }
}
