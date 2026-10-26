package com.typewritermc.realm.publication

import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TestCatalogLease
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.kernel.v1.resource_id.ResourceId

val CompiledArtifactProducerRegistryTest by testSuite {
    test("one blocked producer keeps the other producer's ready artifact in the same compilation") {
        val ready =
            producer("fixture.ready", "application/ready") {
                listOf(CompilationResult.Success(artifact("fixture.ready", "application/ready")))
            }
        val blocked =
            producer("fixture.blocked", "application/blocked") {
                listOf(
                    CompilationResult.Blocked(
                        root("fixture.blocked"),
                        ContentDigest("a".repeat(64)),
                        listOf(compilationDiagnostic("blocked", "Blocked")),
                    ),
                )
            }

        val result = compile(ready, blocked)

        result.filterIsInstance<CompilationResult.Success>().map { it.artifact.root } shouldBe listOf(root("fixture.ready"))
        result.filterIsInstance<CompilationResult.Blocked>().map { it.root to it.diagnostics.map { finding -> finding.code } } shouldBe
            listOf(root("fixture.blocked") to listOf("blocked"))
    }

    test("two producers with one projection and media type are refused at registration") {
        val first = producer("fixture", "application/fixture") { emptyList() }
        val second = producer("fixture", "application/fixture") { error("Duplicate registration must fail before compilation.") }

        shouldThrow<IllegalArgumentException> { CompiledArtifactProducerRegistry(listOf(first, second)) }.message shouldBe
            "Compiled artifact producers must have unique projection and media type identities."
    }

    test("output in another media type than its producer declares is refused") {
        val wrongMedia =
            producer("fixture", "application/fixture") {
                listOf(CompilationResult.Success(artifact("fixture", "application/other")))
            }

        shouldThrow<IllegalArgumentException> { compile(wrongMedia) }.message shouldBe "Compiled output must match its producer media type."
    }

    test("output for another projection than its producer declares is refused as a root it was not given") {
        val wrongProjection =
            producer("fixture", "application/fixture") {
                listOf(CompilationResult.Success(artifact("other", "application/fixture")))
            }

        shouldThrow<IllegalArgumentException> { compile(wrongProjection) }.message shouldBe
            "Compilation must report every supplied root exactly once."
    }

    test("two media types of one projection cannot publish the same root") {
        val first =
            producer("fixture", "application/first") {
                listOf(CompilationResult.Success(artifact("fixture", "application/first")))
            }
        val second =
            producer("fixture", "application/second") {
                listOf(CompilationResult.Success(artifact("fixture", "application/second")))
            }

        shouldThrow<IllegalArgumentException> { compile(first, second) }.message shouldBe
            "Compiled roots must be unique within one publication."
    }
}

/** Compiles an empty saved view with [producers]. */
private fun compile(vararg producers: CompiledArtifactProducer): List<CompilationResult> =
    InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap())).use { views ->
        views.capture().use { capture ->
            with(CompilationInputs(capture.root, emptyMap())) { CompiledArtifactProducerRegistry(producers.toList()).compile() }
        }
    }

private fun root(projection: String) =
    CompilationRoot(projection = CompilationProjectionId(value = projection), resource = ResourceId(value = "root"))

private fun producer(
    projection: String,
    mediaType: String,
    compile: (CompilationInputs) -> List<CompilationResult>,
): CompiledArtifactProducer =
    object : CompiledArtifactProducer {
        override val projection = CompilationProjectionId(value = projection)
        override val mediaType = mediaType

        override fun roots(view: com.typewritermc.realm.authoring.AuthoringView): Set<CompilationRoot> =
            setOf(CompilationRoot(projection = this.projection, resource = ResourceId(value = "root")))

        context(inputs: CompilationInputs)
        override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> = compile.invoke(inputs)
    }

private fun artifact(
    projection: String,
    mediaType: String,
) = CompiledArtifact(
    root = root(projection),
    formatRevision = 2,
    mediaType = mediaType,
    inputFingerprint = ContentDigest("1".repeat(64)),
    semanticDigest = ContentDigest("2".repeat(64)),
    payload = "fixture".encodeToByteArray(),
)
