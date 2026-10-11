package com.typewritermc.discovery

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val CatalogSnapshotImmutabilityTest by testSuite {
    test("catalog snapshots reject outer and nested collection mutation") {
        val types = mutableListOf<com.typewritermc.types.catalog.PublishedType>()
        val parents = mutableListOf(PresentationRole.INSPECTOR)
        val fallbacks = mutableListOf(RoleFallback(PresentationRole.EDITOR, parents))
        val source =
            EditorCatalogSnapshot(
                generation = CatalogGeneration("catalog"),
                types = types,
                relations = emptyList(),
                resourceDefinitions = emptyList(),
                presentations = emptyList(),
                presentationMaterials = emptyList(),
                configuration = emptyList(),
                diagnostics = emptyList(),
                initialization = emptyList(),
                roleFallbacks = fallbacks,
            )

        val retained = source.immutableCopy()
        types.clear()
        parents += PresentationRole.REFERENCE_SUMMARY
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
