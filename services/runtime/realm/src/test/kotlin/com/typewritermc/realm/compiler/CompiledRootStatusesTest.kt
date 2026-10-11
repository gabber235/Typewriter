package com.typewritermc.realm.compiler

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.PublishedOutput
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val CompiledRootStatusesTest by testSuite {
    test("all roots combines producer roots with the selected publication in stable order") {
        val current = CompilationRoot(CompilationProjectionId("current"), ResourceId("b"))
        val active = CompilationRoot(CompilationProjectionId("active"), ResourceId("a"))
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            val publication = published(active)
            val statuses = CompiledRootStatuses(registry(current), selected(publication))

            val result = statuses.query(capture.root, CompilationStatusSelection.All)

            result.keys.toList() shouldBe listOf(active, current)
            result.getValue(active) shouldBe RegisteredCompiledState.Active(publication.publication)
            result.getValue(current) shouldBe RegisteredCompiledState.NotCompiled
        }
        views.close()
    }

    test("an empty supplied selection queries no roots") {
        val active = CompilationRoot(CompilationProjectionId("active"), ResourceId("a"))
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            CompiledRootStatuses(registry(active), selected(published(active)))
                .query(capture.root, CompilationStatusSelection.Supplied(emptySet())) shouldBe emptyMap()
        }
        views.close()
    }
}

private fun registry(root: CompilationRoot) =
    CompiledArtifactProducerRegistry(
        listOf(
            object : CompiledArtifactProducer {
                override val projection = root.projection
                override val mediaType = "application/fixture"

                override fun roots(view: AuthoringView) = setOf(root)

                context(inputs: CompilationInputs)
                override fun compile(roots: Set<CompilationRoot>) = CompilationOutcome.Ready(emptyList())
            },
        ),
    )

private fun selected(content: PublishedContent) =
    object : PublicationResults {
        override suspend fun selected() = content

        override suspend fun latestReport(): PublicationReport? = null
    }

private fun published(root: CompilationRoot): PublishedContent =
    PublishedContent(
        publication = PublicationId("selected"),
        formatRevision = 2,
        catalog = CatalogGeneration("catalog"),
        implementationToken = "implementation",
        runtimeSignatures = emptySet(),
        outputs =
            listOf(
                PublishedOutput(
                    CompiledArtifactReference(
                        root = root,
                        formatRevision = 2,
                        mediaType = "application/fixture",
                        semanticDigest = ContentDigest("1".repeat(64)),
                    ),
                    CompiledBlobPointer(ContentDigest("2".repeat(64)), 1),
                ),
            ),
    )
