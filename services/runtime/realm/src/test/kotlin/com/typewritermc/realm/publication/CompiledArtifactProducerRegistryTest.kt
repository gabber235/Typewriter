package com.typewritermc.realm.publication

import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.ContentDigest
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val CompiledArtifactProducerRegistryTest by testSuite {
    test("one blocked producer keeps the other producer's ready artifact in the same compilation") {
        val ready =
            compiledArtifactProducer("fixture.ready", "application/ready") {
                listOf(CompilationResult.Success(compiledArtifact(compilationRoot("fixture.ready"), "application/ready")))
            }
        val blocked =
            compiledArtifactProducer("fixture.blocked", "application/blocked") {
                listOf(
                    CompilationResult.Blocked(
                        compilationRoot("fixture.blocked"),
                        ContentDigest("a".repeat(64)),
                        listOf(compilationDiagnostic("blocked", "Blocked")),
                    ),
                )
            }

        val result = compileEmptyView(ready, blocked)

        result.filterIsInstance<CompilationResult.Success>().map { it.artifact.root } shouldBe listOf(compilationRoot("fixture.ready"))
        result.filterIsInstance<CompilationResult.Blocked>().map { it.root to it.diagnostics.map { finding -> finding.code } } shouldBe
            listOf(compilationRoot("fixture.blocked") to listOf("blocked"))
    }

    test("two producers with one projection and media type are refused at registration") {
        val first = compiledArtifactProducer("fixture", "application/fixture") { emptyList() }
        val second =
            compiledArtifactProducer("fixture", "application/fixture") { error("Duplicate registration must fail before compilation.") }

        shouldThrow<IllegalArgumentException> { CompiledArtifactProducerRegistry(listOf(first, second)) }.message shouldBe
            "Compiled artifact producers must have unique projection and media type identities."
    }

    test("output in another media type than its producer declares is refused") {
        val wrongMedia =
            compiledArtifactProducer("fixture", "application/fixture") {
                listOf(CompilationResult.Success(compiledArtifact(compilationRoot("fixture"), "application/other")))
            }

        shouldThrow<IllegalArgumentException> { compileEmptyView(wrongMedia) }.message shouldBe
            "Compiled output must match its producer media type."
    }

    test("output for another projection than its producer declares is refused as a root it was not given") {
        val wrongProjection =
            compiledArtifactProducer("fixture", "application/fixture") {
                listOf(CompilationResult.Success(compiledArtifact(compilationRoot("other"), "application/fixture")))
            }

        shouldThrow<IllegalArgumentException> { compileEmptyView(wrongProjection) }.message shouldBe
            "Compilation must report every supplied root exactly once."
    }

    test("two media types of one projection cannot publish the same root") {
        val first =
            compiledArtifactProducer("fixture", "application/first") {
                listOf(CompilationResult.Success(compiledArtifact(compilationRoot("fixture"), "application/first")))
            }
        val second =
            compiledArtifactProducer("fixture", "application/second") {
                listOf(CompilationResult.Success(compiledArtifact(compilationRoot("fixture"), "application/second")))
            }

        shouldThrow<IllegalArgumentException> { compileEmptyView(first, second) }.message shouldBe
            "Compiled roots must be unique within one publication."
    }
}
