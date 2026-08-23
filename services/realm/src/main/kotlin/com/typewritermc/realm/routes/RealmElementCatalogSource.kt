package com.typewritermc.realm.routes

import com.typewritermc.elements.AvailabilityExpression
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.elements.ElementCatalogEntry
import com.typewritermc.elements.ElementDescriptor
import com.typewritermc.elements.ElementKind
import com.typewritermc.types.Icon
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.skir.toSkir
import skirout.editor.v1.catalog.CatalogGeneration
import skirout.editor.v1.element_catalog.AvailabilityAll
import skirout.editor.v1.element_catalog.AvailabilityAny
import skirout.editor.v1.element_catalog.AvailabilityFact
import skirout.editor.v1.element_catalog.AvailabilityNot
import skirout.editor.v1.element_catalog.ElementCatalogRequest
import skirout.editor.v1.element_catalog.ElementCatalogResult
import skirout.editor.v1.element_catalog.ElementCatalogSuccess
import skirout.editor.v1.element_catalog.ElementEligibility
import skirout.editor.v1.element_catalog.ElementTypeId
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.element_catalog.AvailabilityExpression as SkirAvailabilityExpression
import skirout.editor.v1.element_catalog.ElementCatalogEntry as SkirElementCatalogEntry
import skirout.editor.v1.element_catalog.ElementDescriptor as SkirElementDescriptor
import skirout.editor.v1.element_catalog.ElementKind as SkirElementKind
import skirout.kernel.v1.color.Color as SkirColor
import skirout.kernel.v1.icon.Icon as SkirIcon

data class RealmElementCatalogSnapshot(
    val generation: String,
    val catalog: ElementCatalog,
)

fun interface RealmElementCatalogSnapshotProvider {
    suspend fun snapshot(): RealmElementCatalogSnapshot?
}

fun interface RealmElementCatalogSource {
    suspend fun fetch(request: ElementCatalogRequest): ElementCatalogResult
}

class SnapshotRealmElementCatalogSource(
    private val provider: RealmElementCatalogSnapshotProvider,
) : RealmElementCatalogSource {
    override suspend fun fetch(request: ElementCatalogRequest): ElementCatalogResult {
        val snapshot =
            provider.snapshot() ?: return ElementCatalogResult.UnavailableWrapper(listOf("Realm discovery snapshot is unavailable"))
        if (request.expectedGeneration?.value != null && request.expectedGeneration?.value != snapshot.generation) {
            return ElementCatalogResult.createGenerationMismatch(value = snapshot.generation)
        }
        return ElementCatalogResult.createSuccess(
            generation = CatalogGeneration(value = snapshot.generation),
            entries = snapshot.catalog.entries.map(ElementCatalogEntry::toSkir),
        )
    }
}

class UnavailableRealmElementCatalogSource : RealmElementCatalogSource {
    override suspend fun fetch(request: ElementCatalogRequest): ElementCatalogResult =
        ElementCatalogResult.UnavailableWrapper(listOf("Realm element catalog source is unavailable"))
}

private fun ElementCatalogEntry.toSkir(): SkirElementCatalogEntry =
    SkirElementCatalogEntry(
        originArtifactId = origin.value,
        sourcePart = sourcePart,
        descriptor = descriptor.toSkir(),
        eligibility =
            if (eligible) {
                ElementEligibility.createEligible()
            } else {
                ElementEligibility.createIneligible(reasons = ineligibilityReasons)
            },
        available = available,
    )

private fun ElementDescriptor.toSkir(): SkirElementDescriptor =
    SkirElementDescriptor(
        elementTypeId = ElementTypeId(value = DeclaredTypeId(value = id.value.toString())),
        kind =
            when (kind) {
                ElementKind.ENTRY -> SkirElementKind.ENTRY
                ElementKind.CUE -> SkirElementKind.CUE
            },
        type = type.toSkir().getOrThrow(),
        name = name,
        description = description,
        icon =
            when (val icon = icon) {
                is Icon.Iconify -> SkirIcon.IconifyWrapper(icon.value)
                is Icon.Svg -> SkirIcon.SvgWrapper(icon.source)
            },
        color = SkirColor(argb = color.argb.toInt()),
        availability = availability.toSkir(),
    )

private fun AvailabilityExpression.toSkir(): SkirAvailabilityExpression =
    when (this) {
        AvailabilityExpression.Always -> {
            SkirAvailabilityExpression.createAlways()
        }

        is AvailabilityExpression.Fact -> {
            SkirAvailabilityExpression.FactWrapper(AvailabilityFact(key = key, expected = expected))
        }

        is AvailabilityExpression.All -> {
            SkirAvailabilityExpression.AllWrapper(
                AvailabilityAll(expressions = expressions.map { it.toSkir() }),
            )
        }

        is AvailabilityExpression.Any -> {
            SkirAvailabilityExpression.AnyWrapper(
                AvailabilityAny(expressions = expressions.map { it.toSkir() }),
            )
        }

        is AvailabilityExpression.Not -> {
            SkirAvailabilityExpression.NotWrapper(AvailabilityNot(expression = expression.toSkir()))
        }
    }
