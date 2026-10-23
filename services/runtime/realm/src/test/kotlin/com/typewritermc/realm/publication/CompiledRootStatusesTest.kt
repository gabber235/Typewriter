package com.typewritermc.realm.publication

import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TestCatalogLease
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompilationStatusSelection
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.CompiledResourceState
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.publication.PublicationReport
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.ResourceId

val CompiledRootStatusesTest by testSuite {
    test("all roots combines producer roots with the selected publication in stable order") {
        val current = CompilationRoot(projection = CompilationProjectionId(value = "current"), resource = ResourceId(value = "b"))
        val active = CompilationRoot(projection = CompilationProjectionId(value = "active"), resource = ResourceId(value = "a"))
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            val publication = published(active)
            val statuses = CompiledRootStatuses(registry(current), selected(publication))

            val result = statuses.query(capture.root, CompilationStatusSelection.ALL_ROOTS)

            result.keys.toList() shouldBe listOf(active, current)
            result.getValue(active) shouldBe
                CompiledResourceState.ActiveWrapper(
                    skirout.editor.v1.type_catalog
                        .PublicationId(value = publication.publication.value),
                )
            result.getValue(current) shouldBe CompiledResourceState.NOT_COMPILED
        }
        views.close()
    }

    test("an empty supplied selection queries no roots") {
        val active = CompilationRoot(projection = CompilationProjectionId(value = "active"), resource = ResourceId(value = "a"))
        val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap()))
        views.capture().use { capture ->
            CompiledRootStatuses(registry(active), selected(published(active)))
                .query(capture.root, CompilationStatusSelection.SuppliedRootsWrapper(emptySet())) shouldBe emptyMap()
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
                override fun compile(roots: Set<CompilationRoot>) = emptyList<com.typewritermc.engine.CompilationResult>()
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
        publication = PublicationId(value = "selected"),
        formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
        catalog = CatalogGeneration(value = "catalog"),
        implementationToken = "implementation",
        outputs =
            listOf(
                PublishedOutput(
                    reference =
                        CompiledArtifactReference(
                            root = root,
                            formatRevision = 2,
                            mediaType = "application/fixture",
                            semanticDigest = ContentDigest("1".repeat(64)).value,
                        ),
                    blob = CompiledBlobPointer(digest = ContentDigest("2".repeat(64)).value, size = 1),
                ),
            ),
    )
