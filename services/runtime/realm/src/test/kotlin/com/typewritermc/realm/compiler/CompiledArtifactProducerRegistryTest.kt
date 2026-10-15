package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
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
    test("one blocked producer retains a partial ready batch and every producer receives the retained inputs") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            val inputs = CompilationInputs(capture.root, emptyMap())
            val received = mutableListOf<CompilationInputs>()
            val ready =
                producer("fixture.ready", "application/ready") { incoming ->
                    received += incoming
                    listOf(CompilationResult.Success(artifact("fixture.ready", "application/ready")))
                }
            val blocked =
                producer("fixture.blocked", "application/blocked") { incoming ->
                    received += incoming
                    listOf(
                        CompilationResult.Blocked(
                            CompilationRoot(CompilationProjectionId("fixture.blocked"), ResourceId("root")),
                            ContentDigest("a".repeat(64)),
                            listOf(compilationDiagnostic("blocked", "Blocked")),
                        ),
                    )
                }

            val result = with(inputs) { CompiledArtifactProducerRegistry(listOf(ready, blocked)).compile() }

            result.size shouldBe 2
            result.filterIsInstance<CompilationResult.Success>().size shouldBe 1
            result
                .filterIsInstance<CompilationResult.Blocked>()
                .single()
                .diagnostics
                .single()
                .code shouldBe "blocked"
            received.size shouldBe 2
            received.all { it === inputs && it.view === capture.root } shouldBe true
        }
        views.close()
    }

    test("rejects duplicate producer identity before compilation") {
        val first = producer("fixture", "application/fixture") { emptyList() }
        val second = producer("fixture", "application/fixture") { error("Duplicate registration must fail before compilation.") }

        shouldThrow<IllegalArgumentException> { CompiledArtifactProducerRegistry(listOf(first, second)) }
    }

    test("rejects output that disagrees with its declared producer identity") {
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            val wrongMedia =
                producer("fixture", "application/fixture") {
                    listOf(CompilationResult.Success(artifact("fixture", "application/other")))
                }
            val wrongProjection =
                producer("fixture", "application/fixture") {
                    listOf(CompilationResult.Success(artifact("other", "application/fixture")))
                }
            listOf(wrongMedia, wrongProjection).forEach { producer ->
                shouldThrow<IllegalArgumentException> {
                    val inputs = CompilationInputs(capture.root, emptyMap())
                    with(inputs) { CompiledArtifactProducerRegistry(listOf(producer)).compile() }
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
                    listOf(CompilationResult.Success(artifact("fixture", "application/first")))
                }
            val second =
                producer("fixture", "application/second") {
                    listOf(CompilationResult.Success(artifact("fixture", "application/second")))
                }

            shouldThrow<IllegalArgumentException> {
                val inputs = CompilationInputs(capture.root, emptyMap())
                with(inputs) { CompiledArtifactProducerRegistry(listOf(first, second)).compile() }
            }
        }
        views.close()
    }
}

private fun producer(
    projection: String,
    mediaType: String,
    compile: (CompilationInputs) -> List<CompilationResult>,
): CompiledArtifactProducer =
    object : CompiledArtifactProducer {
        override val projection = CompilationProjectionId(projection)
        override val mediaType = mediaType

        override fun roots(view: com.typewritermc.realm.authoring.AuthoringView): Set<CompilationRoot> =
            setOf(CompilationRoot(this.projection, ResourceId("root")))

        context(inputs: CompilationInputs)
        override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> = compile.invoke(inputs)
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
