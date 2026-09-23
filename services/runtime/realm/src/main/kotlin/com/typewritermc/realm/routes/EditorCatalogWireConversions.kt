package com.typewritermc.realm.routes

import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.elements.AvailabilityExpression
import com.typewritermc.elements.ContentCatalogEntry
import com.typewritermc.elements.ContentDescriptor
import com.typewritermc.elements.ContentRole
import com.typewritermc.elements.ContentSearchDefinition
import com.typewritermc.elements.ContentSearchMode
import com.typewritermc.elements.ContentSearchPolicy
import com.typewritermc.elements.ContentSearchPropertyOverride
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageCatalogEntry
import com.typewritermc.pages.PageDescriptor
import com.typewritermc.pages.PageDiagnostic
import com.typewritermc.pages.ResolvedPageEditorDefinition
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.skir.toSkir
import skirout.editor.v1.catalog_presentation.CatalogPresentationSubject
import skirout.editor.v1.element_catalog.AvailabilityAll
import skirout.editor.v1.element_catalog.AvailabilityAny
import skirout.editor.v1.element_catalog.AvailabilityFact
import skirout.editor.v1.element_catalog.AvailabilityNot
import skirout.editor.v1.element_catalog.ContentEligibility
import skirout.editor.v1.element_catalog.ContentTypeId
import skirout.editor.v1.element_catalog.ContentRole as SkirContentRole
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.element_catalog.AvailabilityExpression as SkirAvailabilityExpression
import skirout.editor.v1.element_catalog.ContentCatalogEntry as SkirContentCatalogEntry
import skirout.editor.v1.element_catalog.ContentDescriptor as SkirContentDescriptor
import skirout.editor.v1.element_catalog.ContentSearchDefinition as SkirContentSearchDefinition
import skirout.editor.v1.element_catalog.ContentSearchMode as SkirContentSearchMode
import skirout.editor.v1.element_catalog.ContentSearchPolicy as SkirContentSearchPolicy
import skirout.editor.v1.element_catalog.ContentSearchPropertyOverride as SkirContentSearchPropertyOverride
import skirout.editor.v1.page_catalog.GraphDirection as SkirGraphDirection
import skirout.editor.v1.page_catalog.PageCatalogEntry as SkirPageCatalogEntry
import skirout.editor.v1.page_catalog.PageDescriptor as SkirPageDescriptor
import skirout.editor.v1.page_catalog.PageDiagnostic as SkirPageDiagnostic
import skirout.editor.v1.page_catalog.PageEditorDefinition as SkirPageEditorDefinition

/**
 * Preserves descriptor metadata, eligibility, and availability when exposing elements to the editor.
 *
 * Unavailable entries remain visible with reasons so the panel can explain deployment constraints.
 */
internal fun ContentCatalogEntry.toSkir(prototypes: TypePrototypeRegistry): SkirContentCatalogEntry =
    SkirContentCatalogEntry(
        originArtifactId = origin.value,
        sourcePart = sourcePart,
        descriptor = descriptor.toSkir(),
        presentationSubject =
            catalogPresentationSubject(
                target = descriptor.type,
                descriptor =
                    ResourceTypeDescriptor(
                        type = descriptor.type,
                        name = descriptor.name,
                        description = descriptor.description,
                        icon = descriptor.icon,
                        color = descriptor.color,
                    ),
                identity = descriptor.type,
                prototypes = prototypes,
            ),
        eligibility =
            if (eligible) {
                ContentEligibility.createEligible()
            } else {
                ContentEligibility.createIneligible(reasons = ineligibilityReasons)
            },
        available = available,
    )

private fun ContentDescriptor.toSkir(): SkirContentDescriptor =
    SkirContentDescriptor(
        contentTypeId = ContentTypeId(value = DeclaredTypeId(value = id.value.toString())),
        type = type.toSkir().getOrThrow(),
        name = name,
        description = description,
        icon = icon.toSkir(),
        color = color.toSkir(),
        availability = availability.toSkir(),
        searchDefinition = searchDefinition?.toSkir(),
        role = when (role) {
            ContentRole.ELEMENT -> SkirContentRole.createElement()
            ContentRole.CUE -> SkirContentRole.createCue()
        },
    )

private fun ContentSearchDefinition.toSkir(): SkirContentSearchDefinition =
    SkirContentSearchDefinition(
        policy = policy.toSkir(),
        propertyOverrides = propertyOverrides.map(ContentSearchPropertyOverride::toSkir),
        revisionFingerprintInputs = revisionFingerprintInputs.map { it.toSkir().getOrThrow() },
    )

private fun ContentSearchPropertyOverride.toSkir(): SkirContentSearchPropertyOverride =
    SkirContentSearchPropertyOverride(
        ownerType = ownerType.toSkir().getOrThrow(),
        field = field,
        mode = mode.toSkir(),
    )

private fun ContentSearchPolicy.toSkir(): SkirContentSearchPolicy =
    when (this) {
        ContentSearchPolicy.ORDINARY_TEXT -> SkirContentSearchPolicy.createOrdinaryText()
    }

private fun ContentSearchMode.toSkir(): SkirContentSearchMode =
    when (this) {
        ContentSearchMode.SUMMARY -> SkirContentSearchMode.createSummary()
        ContentSearchMode.BODY -> SkirContentSearchMode.createBody()
        ContentSearchMode.KEYWORD -> SkirContentSearchMode.createKeyword()
        ContentSearchMode.NONE -> SkirContentSearchMode.createNone()
    }

private fun AvailabilityExpression.toSkir(): SkirAvailabilityExpression =
    when (this) {
        AvailabilityExpression.Always -> {
            SkirAvailabilityExpression.createAlways()
        }

        is AvailabilityExpression.Fact -> {
            SkirAvailabilityExpression.FactWrapper(AvailabilityFact(key = key, expected = expected))
        }

        is AvailabilityExpression.All -> {
            SkirAvailabilityExpression.AllWrapper(AvailabilityAll(expressions = expressions.map { it.toSkir() }))
        }

        is AvailabilityExpression.Any -> {
            SkirAvailabilityExpression.AnyWrapper(AvailabilityAny(expressions = expressions.map { it.toSkir() }))
        }

        is AvailabilityExpression.Not -> {
            SkirAvailabilityExpression.NotWrapper(AvailabilityNot(expression = expression.toSkir()))
        }
    }

/**
 * Encodes a page schema and origin with resolved role references for panel use.
 */
internal fun PageCatalogEntry.toSkir(prototypes: TypePrototypeRegistry): SkirPageCatalogEntry =
    SkirPageCatalogEntry(
        originArtifactId = originArtifactId,
        sourcePart = sourcePart,
        descriptor = descriptor.toSkir(),
        presentationSubject =
            catalogPresentationSubject(
                target = presentationTarget,
                descriptor =
                    ResourceTypeDescriptor(
                        type = presentationTarget,
                        name = descriptor.name,
                        description = descriptor.description.orEmpty(),
                        icon = descriptor.icon,
                        color = descriptor.color,
                    ),
                identity = presentationTarget,
                prototypes = prototypes,
            ),
    )

private fun catalogPresentationSubject(
    target: com.typewritermc.types.ResolvedTypeRef,
    descriptor: ResourceTypeDescriptor,
    identity: Any,
    prototypes: TypePrototypeRegistry,
) = CatalogPresentationSubject(
    target = target.toSkir().getOrThrow(),
    descriptor = prototypes.encode(descriptor).toWire(),
    identity = prototypes.encode(identity).toWire(),
)

private fun PageDescriptor.toSkir(): SkirPageDescriptor =
    SkirPageDescriptor(
        type = type.toSkir().getOrThrow(),
        name = name,
        description = description,
        icon = icon.toSkir(),
        color = color.toSkir(),
        editor = editor.toSkir(),
    )

internal fun PageDiagnostic.toSkir(): SkirPageDiagnostic =
    SkirPageDiagnostic(
        code = code,
        message = message,
        originArtifactId = namespace,
        sourcePart = sourcePart,
        declarationName = declarationName,
        type = type?.toSkir()?.getOrThrow(),
    )

private fun ResolvedPageEditorDefinition.toSkir(): SkirPageEditorDefinition =
    when (this) {
        is ResolvedPageEditorDefinition.Graph -> {
            SkirPageEditorDefinition.createGraph(
                direction = direction.toSkir(),
            )
        }

        is ResolvedPageEditorDefinition.Timeline -> SkirPageEditorDefinition.createTimeline()
    }

private fun GraphDirection.toSkir(): SkirGraphDirection =
    when (this) {
        GraphDirection.LEFT_TO_RIGHT -> SkirGraphDirection.LEFT_TO_RIGHT
        GraphDirection.RIGHT_TO_LEFT -> SkirGraphDirection.RIGHT_TO_LEFT
        GraphDirection.TOP_TO_BOTTOM -> SkirGraphDirection.TOP_TO_BOTTOM
        GraphDirection.BOTTOM_TO_TOP -> SkirGraphDirection.BOTTOM_TO_TOP
    }
