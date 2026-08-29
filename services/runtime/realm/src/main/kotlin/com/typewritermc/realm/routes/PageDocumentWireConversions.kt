package com.typewritermc.realm.routes

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ref
import com.typewritermc.library.PageCompileStatus
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentDiagnostic
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageReference
import com.typewritermc.library.ResourceSummary
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.library.v2.authoring.Book as SkirBook
import skirout.library.v2.authoring.ElementPlacement as SkirElementPlacement
import skirout.library.v2.authoring.Page as SkirPage
import skirout.library.v2.authoring.PageCompileStatus as SkirPageCompileStatus
import skirout.library.v2.authoring.PageDiagnostic as SkirPageDiagnostic
import skirout.library.v2.authoring.PageDocument as SkirPageDocument
import skirout.library.v2.authoring.PageElement as SkirPageElement
import skirout.library.v2.authoring.PageReference as SkirPageReference
import skirout.library.v2.authoring.ResourceSummary as SkirResourceSummary
import skirout.library.v2.authoring.Tag as SkirTag

internal fun PageDocument.toWire(): SkirPageDocument =
    SkirPageDocument(
        revision = revision.value,
        page = page.toV2Wire(),
        elements = elements.map(PageDocumentElement::toWire),
        references = references.map(PageReference::toWire),
        crossPageTargets = crossPageTargets.map(ResourceSummary::toWire),
        crossPageSources = crossPageSources.map(ResourceSummary::toWire),
        diagnostics = diagnostics.map(PageDocumentDiagnostic::toWire),
        compileStatus = compileStatus.toWire(),
    )

internal fun com.typewritermc.library.Page.toV2Wire(): SkirPage =
    SkirPage(
        id = id.toSkirRecordId(),
        revision = revision.value,
        book = book.toSkirRecordId(),
        name = name.value,
        kind = kind.toSkir(),
        chapter = chapter.value,
        priority = priority,
    )

internal fun com.typewritermc.library.Book.toV2Wire(): SkirBook =
    SkirBook(
        id = id.toSkirRecordId(),
        revision = revision.value,
        title = title.value,
        icon = icon.wireValue,
        color = color.toSkir(),
        tags = tags.map { it.toSkirRecordId() },
    )

internal fun com.typewritermc.library.Tag.toV2Wire(): SkirTag =
    SkirTag(
        id = id.toSkirRecordId(),
        revision = revision.value,
        name = name.value,
        color = color.toSkir(),
        parents = parents.map { it.toSkirRecordId() },
        placement =
            skirout.library.v2.authoring.GraphPlacement(
                x = placement.x,
                y = placement.y,
                width = placement.width,
                height = placement.height,
            ),
    )

private fun PageDocumentElement.toWire(): SkirPageElement =
    SkirPageElement(
        id = id.ref<Element>().toSkirRecordId(),
        revision = revision.value,
        elementType = elementType.value.toString(),
        schemaRevision = schemaRevision,
        name = name,
        value = SkirDataValueCodec.encode(value).getOrThrow(),
        placement = placement.toWire(),
    )

private fun ElementPlacement.toWire(): SkirElementPlacement =
    when (this) {
        is ElementPlacement.Graph -> {
            SkirElementPlacement.createGraphV1(x = x, y = y, width = width, height = height)
        }

        is ElementPlacement.TimelineEntry -> {
            SkirElementPlacement.createTimelineEntryV1(trackIndex = trackIndex)
        }

        is ElementPlacement.TimelineSegment -> {
            SkirElementPlacement.createTimelineSegmentV1(startFrame = startFrame, endFrame = endFrame)
        }

        is ElementPlacement.TimelineKeyframe -> {
            SkirElementPlacement.createTimelineKeyframeV1(frame = frame)
        }
    }

private fun PageReference.toWire(): SkirPageReference =
    SkirPageReference(
        source = source.ref<Element>().toSkirRecordId(),
        slot = slot.value,
        target = target.toSkirRecordId(),
    )

private fun ResourceSummary.toWire(): SkirResourceSummary =
    SkirResourceSummary(
        id = id.toSkirRecordId(),
        name = name,
        elementType = elementType?.value?.toString(),
        page = page?.toSkirRecordId(),
        exists = exists,
    )

private fun PageDocumentDiagnostic.toWire(): SkirPageDiagnostic =
    SkirPageDiagnostic(
        code = code,
        message = message,
        element = element?.ref<Element>()?.toSkirRecordId(),
        slot = slot?.value,
        target = target?.toSkirRecordId(),
    )

private fun PageCompileStatus.toWire(): SkirPageCompileStatus =
    when (this) {
        PageCompileStatus.NotCompiled -> {
            SkirPageCompileStatus.NOT_COMPILED
        }

        is PageCompileStatus.Active -> {
            SkirPageCompileStatus.createActive(manifestId = manifestId)
        }

        is PageCompileStatus.Blocked -> {
            SkirPageCompileStatus.createBlocked(
                lastActiveManifestId = lastActiveManifestId,
                diagnosticCount = diagnosticCount,
            )
        }
    }
