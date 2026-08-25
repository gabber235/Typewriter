package com.typewritermc.realm.routes

import com.typewritermc.elements.AvailabilityExpression
import com.typewritermc.elements.ElementCatalogEntry
import com.typewritermc.elements.ElementDescriptor
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageCatalogEntry
import com.typewritermc.pages.PageDescriptor
import com.typewritermc.pages.PageDiagnostic
import com.typewritermc.pages.ResolvedPageEditorDefinition
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.skir.toSkir
import skirout.editor.v1.element_catalog.AvailabilityAll
import skirout.editor.v1.element_catalog.AvailabilityAny
import skirout.editor.v1.element_catalog.AvailabilityFact
import skirout.editor.v1.element_catalog.AvailabilityNot
import skirout.editor.v1.element_catalog.ElementEligibility
import skirout.editor.v1.element_catalog.ElementTypeId
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.element_catalog.AvailabilityExpression as SkirAvailabilityExpression
import skirout.editor.v1.element_catalog.ElementCatalogEntry as SkirElementCatalogEntry
import skirout.editor.v1.element_catalog.ElementDescriptor as SkirElementDescriptor
import skirout.editor.v1.page_catalog.GraphDirection as SkirGraphDirection
import skirout.editor.v1.page_catalog.PageCatalogEntry as SkirPageCatalogEntry
import skirout.editor.v1.page_catalog.PageDescriptor as SkirPageDescriptor
import skirout.editor.v1.page_catalog.PageDiagnostic as SkirPageDiagnostic
import skirout.editor.v1.page_catalog.PageEditorDefinition as SkirPageEditorDefinition

internal fun ElementCatalogEntry.toSkir(): SkirElementCatalogEntry =
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
        type = type.toSkir().getOrThrow(),
        name = name,
        description = description,
        icon = icon.toSkir(),
        color = color.toSkir(),
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
            SkirAvailabilityExpression.AllWrapper(AvailabilityAll(expressions = expressions.map { it.toSkir() }))
        }

        is AvailabilityExpression.Any -> {
            SkirAvailabilityExpression.AnyWrapper(AvailabilityAny(expressions = expressions.map { it.toSkir() }))
        }

        is AvailabilityExpression.Not -> {
            SkirAvailabilityExpression.NotWrapper(AvailabilityNot(expression = expression.toSkir()))
        }
    }

internal fun PageCatalogEntry.toSkir(): SkirPageCatalogEntry =
    SkirPageCatalogEntry(
        originArtifactId = originArtifactId,
        sourcePart = sourcePart,
        descriptor = descriptor.toSkir(),
    )

private fun PageDescriptor.toSkir(): SkirPageDescriptor =
    SkirPageDescriptor(
        kind = kind.toSkir(),
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
        kind = kind?.toSkir(),
    )

private fun ResolvedPageEditorDefinition.toSkir(): SkirPageEditorDefinition =
    when (this) {
        is ResolvedPageEditorDefinition.Graph -> {
            SkirPageEditorDefinition.createGraph(
                direction = direction.toSkir(),
                nodeTypes = nodes.map { it.toSkir().getOrThrow() },
            )
        }

        is ResolvedPageEditorDefinition.Timeline -> {
            SkirPageEditorDefinition.createTimeline(
                trackTypes = tracks.map { it.toSkir().getOrThrow() },
                segmentTypes = segments.map { it.toSkir().getOrThrow() },
                keyframeTypes = keyframes.map { it.toSkir().getOrThrow() },
            )
        }
    }

private fun GraphDirection.toSkir(): SkirGraphDirection =
    when (this) {
        GraphDirection.LEFT_TO_RIGHT -> SkirGraphDirection.LEFT_TO_RIGHT
        GraphDirection.RIGHT_TO_LEFT -> SkirGraphDirection.RIGHT_TO_LEFT
        GraphDirection.TOP_TO_BOTTOM -> SkirGraphDirection.TOP_TO_BOTTOM
        GraphDirection.BOTTOM_TO_TOP -> SkirGraphDirection.BOTTOM_TO_TOP
    }
