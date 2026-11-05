package com.typewritermc.realm.publication

import com.typewritermc.realm.testing.RealmFixture
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compiled_content.CompilationStatusSelection
import skirout.editor.v1.compiled_content.CompiledResourceState
import skirout.editor.v1.type_catalog.PublicationId

val CompiledRootStatusesTest by testSuite {
    test("all roots combines producer roots with the selected publication in stable order") {
        val current = compilationRoot("current", "b")
        val active = compilationRoot("active", "a")
        RealmFixture.core().use { realm ->
            val publication = publishedContent(listOf(compiledArtifact(active)))
            val statuses =
                CompiledRootStatuses(
                    CompiledArtifactProducerRegistry(listOf(compiledArtifactProducer("current", roots = setOf(current)))),
                    selectedPublication(publication),
                )

            val result = realm.views.capture().use { statuses.query(it.root, CompilationStatusSelection.ALL_ROOTS) }

            result.keys.toList() shouldBe listOf(active, current)
            result.getValue(active) shouldBe
                CompiledResourceState.ActiveWrapper(PublicationId(value = publication.publication.value))
            result.getValue(current) shouldBe CompiledResourceState.NOT_COMPILED
        }
    }

    test("an empty supplied selection queries no roots") {
        val active = compilationRoot("active", "a")
        RealmFixture.core().use { realm ->
            realm.views.capture().use { capture ->
                CompiledRootStatuses(
                    CompiledArtifactProducerRegistry(listOf(compiledArtifactProducer("active", roots = setOf(active)))),
                    selectedPublication(publishedContent(listOf(compiledArtifact(active)))),
                ).query(capture.root, CompilationStatusSelection.SuppliedRootsWrapper(emptySet())) shouldBe emptyMap()
            }
        }
    }
}
