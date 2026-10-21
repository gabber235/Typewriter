package com.typewritermc.discovery

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationRole

val CatalogSnapshotImmutabilityTest by testSuite {
    test("catalog snapshots reject outer and nested collection mutation") {
        val types = mutableListOf<com.typewritermc.types.catalog.PublishedType>()
        val parents = mutableListOf<PresentationRole>(PresentationRole.INSPECTOR)
        val fallbacks = mutableListOf(RoleFallback(PresentationRole.WORKSPACE, parents))
        val source =
            EditorCatalogSnapshot(
                generation = CatalogGeneration("catalog"),
                types = types,
                relations = emptyList(),
                resourceDisplays = emptyList(),
                realmRoot = com.typewritermc.authoring.RealmRootDefinition.id,
                presentations = emptyList(),
                presentationMaterials = emptyList(),
                configuration = emptyList(),
                diagnostics = emptyList(),
                roleFallbacks = fallbacks,
            )

        val retained = source.immutableCopy()
        types.clear()
        parents += PresentationRole.REFERENCE_PREVIEW
        fallbacks.clear()

        retained.roleFallbacks.single().parents shouldBe listOf(PresentationRole.INSPECTOR)
        shouldThrow<UnsupportedOperationException> {
            @Suppress("UNCHECKED_CAST")
            (retained.types as MutableList<com.typewritermc.types.catalog.PublishedType>).clear()
        }
        shouldThrow<UnsupportedOperationException> {
            @Suppress("UNCHECKED_CAST")
            (retained.roleFallbacks.single().parents as MutableList<PresentationRole>).clear()
        }
    }
}
