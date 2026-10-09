package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

val CompiledArtifactProducerRegistryTest by testSuite {
    test("one blocked producer prevents a partial ready batch and every producer receives the retained inputs") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            val inputs = CompilationInputs(capture.root, emptyList())
            val received = mutableListOf<CompilationInputs>()
            val ready =
                producer("fixture.ready", "application/ready") { incoming ->
                    received += incoming
                    CompilationOutcome.Ready(listOf(artifact("fixture.ready", "application/ready")))
                }
            val blocked =
                producer("fixture.blocked", "application/blocked") { incoming ->
                    received += incoming
                    CompilationOutcome.Blocked(emptyList())
                }

            val result = CompiledArtifactProducerRegistry(listOf(ready, blocked)).compile(inputs)

            result.shouldBeInstanceOf<CompilationOutcome.Blocked>().findings shouldBe emptyList()
            received.size shouldBe 2
            received.all { it === inputs && it.view === capture.root } shouldBe true
        }
        views.close()
    }

    test("rejects duplicate producer identity before compilation") {
        val first = producer("fixture", "application/fixture") { CompilationOutcome.Ready(emptyList()) }
        val second = producer("fixture", "application/fixture") { error("Duplicate registration must fail before compilation.") }

        shouldThrow<IllegalArgumentException> { CompiledArtifactProducerRegistry(listOf(first, second)) }
    }

    test("rejects output that disagrees with its declared producer identity") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            val wrongMedia =
                producer("fixture", "application/fixture") {
                    CompilationOutcome.Ready(listOf(artifact("fixture", "application/other")))
                }
            val wrongProjection =
                producer("fixture", "application/fixture") {
                    CompilationOutcome.Ready(listOf(artifact("other", "application/fixture")))
                }
            listOf(wrongMedia, wrongProjection).forEach { producer ->
                shouldThrow<IllegalArgumentException> {
                    CompiledArtifactProducerRegistry(listOf(producer)).compile(CompilationInputs(capture.root, emptyList()))
                }
            }
        }
        views.close()
    }

    test("distinct media types cannot publish ambiguous roots within the same projection") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            val first =
                producer("fixture", "application/first") {
                    CompilationOutcome.Ready(listOf(artifact("fixture", "application/first")))
                }
            val second =
                producer("fixture", "application/second") {
                    CompilationOutcome.Ready(listOf(artifact("fixture", "application/second")))
                }

            shouldThrow<IllegalArgumentException> {
                CompiledArtifactProducerRegistry(listOf(first, second)).compile(CompilationInputs(capture.root, emptyList()))
            }
        }
        views.close()
    }
}

private fun producer(
    projection: String,
    mediaType: String,
    compile: (CompilationInputs) -> CompilationOutcome,
): CompiledArtifactProducer =
    object : CompiledArtifactProducer {
        override val projection = CompilationProjectionId(projection)
        override val mediaType = mediaType

        override fun compile(inputs: CompilationInputs): CompilationOutcome = compile.invoke(inputs)
    }

private fun artifact(
    projection: String,
    mediaType: String,
) = CompiledArtifact(
    root = CompilationRoot(CompilationProjectionId(projection), ResourceId("root")),
    formatRevision = 2,
    mediaType = mediaType,
    inputFingerprint = ContentDigest("1".repeat(64)),
    semanticDigest = ContentDigest("2".repeat(64)),
    payload = "fixture".encodeToByteArray(),
)
