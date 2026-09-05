package com.typewritermc.realm.routes

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.ElementValuePathSegment
import com.typewritermc.elements.ref
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.library.PageCompileStatus
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentDiagnostic
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageReference
import com.typewritermc.library.ResourceSummary
import com.typewritermc.library.Tag
import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringChanged
import com.typewritermc.realm.repository.AuthoringDiagnostic
import com.typewritermc.realm.repository.AuthoringElement
import com.typewritermc.realm.repository.AuthoringPropertyValue
import com.typewritermc.realm.repository.AuthoringResourceChange
import com.typewritermc.realm.repository.AuthoringResourceRef
import com.typewritermc.realm.repository.AuthoringSnapshotResult
import com.typewritermc.realm.repository.AuthoringSnapshotSlice
import com.typewritermc.realm.repository.PropertyConflict
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.path.DataPath
import skirout.editor.v1.path.DataPathSegment
import skirout.library.v1.authoring.ApplyAuthoringBatchResponse
import skirout.library.v1.authoring.GetAuthoringSnapshotResponse
import skirout.library.v1.authoring.GraphPlacement
import skirout.library.v1.authoring.AuthoringConflict as WireConflict
import skirout.library.v1.authoring.AuthoringInvalid as WireInvalid
import skirout.library.v1.authoring.AuthoringPropertyValue as WirePropertyValue
import skirout.library.v1.authoring.AuthoringResourceChange as WireChange
import skirout.library.v1.authoring.AuthoringResourceRef as WireResourceRef
import skirout.library.v1.authoring.AuthoringSnapshot as WireSnapshot
import skirout.library.v1.authoring.AuthoringSnapshotSlice as WireSlice
import skirout.library.v1.authoring.Book as WireBook
import skirout.library.v1.authoring.ElementPlacement as WirePlacement
import skirout.library.v1.authoring.Page as WirePage
import skirout.library.v1.authoring.PageCompileStatus as WireCompileStatus
import skirout.library.v1.authoring.PageDiagnostic as WireDiagnostic
import skirout.library.v1.authoring.PageDocument as WirePageDocument
import skirout.library.v1.authoring.PageElement as WireElement
import skirout.library.v1.authoring.PageReference as WireReference
import skirout.library.v1.authoring.PropertyConflict as WirePropertyConflict
import skirout.library.v1.authoring.ResourceSummary as WireSummary
import skirout.library.v1.authoring.Tag as WireTag

internal fun AuthoringSnapshotResult.toWireResponse(): GetAuthoringSnapshotResponse =
    GetAuthoringSnapshotResponse.SuccessWrapper(
        WireSnapshot(sequence = sequence, slices = slices.map(AuthoringSnapshotSlice::toWire)),
    )

internal fun AuthoringBatchResult.toWireResponse(): ApplyAuthoringBatchResponse =
    when (this) {
        is AuthoringBatchResult.Applied -> {
            ApplyAuthoringBatchResponse.AppliedWrapper(change.toWire())
        }

        is AuthoringBatchResult.Conflict -> {
            ApplyAuthoringBatchResponse.ConflictWrapper(
                WireConflict(
                    conflicts = conflicts.map(PropertyConflict::toWire),
                ),
            )
        }

        is AuthoringBatchResult.Invalid -> {
            ApplyAuthoringBatchResponse.InvalidWrapper(
                WireInvalid(diagnostics = diagnostics.map(AuthoringDiagnostic::toWire)),
            )
        }
    }

internal fun AuthoringChanged.toWire() =
    skirout.library.v1.authoring.AuthoringChanged(
        sequence = sequence,
        batchId = batchId.value,
        changes = changes.map(AuthoringResourceChange::toWire),
        indirectlyAffectedResources = indirectlyAffectedResources.map(AuthoringResourceRef::toWire),
    )

private fun AuthoringSnapshotSlice.toWire(): WireSlice =
    when (this) {
        is AuthoringSnapshotSlice.Library -> {
            WireSlice.createLibrary(books = books.map(Book::toWire), tags = tags.map(Tag::toWire))
        }

        is AuthoringSnapshotSlice.Book -> {
            WireSlice.createBook(bookId = id.toSkirRecordId(), book = book?.toWire(), pages = pages.map(Page::toWire))
        }

        is AuthoringSnapshotSlice.Page -> {
            WireSlice.createPage(pageId = id.toSkirRecordId(), document = document?.toWire())
        }
    }

private fun Book.toWire(): WireBook =
    WireBook(
        id = id.toSkirRecordId(),
        title = title.value,
        icon = icon.wireValue,
        color = color.toSkir(),
        tags = tags.map { it.toSkirRecordId() },
    )

private fun Tag.toWire(): WireTag =
    WireTag(
        id = id.toSkirRecordId(),
        name = name.value,
        color = color.toSkir(),
        parents = parents.map { it.toSkirRecordId() },
        placement =
            GraphPlacement(x = placement.x, y = placement.y, width = placement.width, height = placement.height),
    )

private fun Page.toWire(): WirePage =
    WirePage(
        id = id.toSkirRecordId(),
        book = book.toSkirRecordId(),
        name = name.value,
        kind = kind.toSkir(),
        chapter = chapter.value,
        priority = priority,
    )

private fun AuthoringElement.toWire(): WireElement =
    WireElement(
        id = id.ref<Element>().toSkirRecordId(),
        page = page.toSkirRecordId(),
        elementType = elementType.value.toString(),
        schemaRevision = schemaRevision,
        name = name,
        value = SkirDataValueCodec.encode(value).getOrThrow(),
        placement = placement.toWire(),
    )

private fun PageDocument.toWire(): WirePageDocument =
    WirePageDocument(
        page = page.toWire(),
        elements = elements.map { it.toWire(page) },
        references = references.map(PageReference::toWire),
        crossPageTargets = crossPageTargets.map(ResourceSummary::toWire),
        crossPageSources = crossPageSources.map(ResourceSummary::toWire),
        diagnostics = diagnostics.map(PageDocumentDiagnostic::toWire),
        compileStatus = compileStatus.toWire(),
    )

private fun PageDocumentElement.toWire(page: Page): WireElement =
    WireElement(
        id = id.ref<Element>().toSkirRecordId(),
        page = page.id.toSkirRecordId(),
        elementType = elementType.value.toString(),
        schemaRevision = schemaRevision,
        name = name,
        value = SkirDataValueCodec.encode(value).getOrThrow(),
        placement = placement.toWire(),
    )

private fun ElementPlacement.toWire(): WirePlacement =
    when (this) {
        is ElementPlacement.Graph -> {
            WirePlacement.createGraph(x = x, y = y, width = width, height = height)
        }

        is ElementPlacement.TimelineEntry -> {
            WirePlacement.createTimelineEntry(trackIndex = trackIndex)
        }

        is ElementPlacement.TimelineSegment -> {
            WirePlacement.createTimelineSegment(startFrame = startFrame, endFrame = endFrame)
        }

        is ElementPlacement.TimelineKeyframe -> {
            WirePlacement.createTimelineKeyframe(frame = frame)
        }
    }

private fun PageReference.toWire(): WireReference =
    WireReference(source = source.ref<Element>().toSkirRecordId(), slot = slot.value, target = target.toSkirRecordId())

private fun ResourceSummary.toWire(): WireSummary =
    WireSummary(
        id = id.toSkirRecordId(),
        name = name,
        elementType = elementType?.value?.toString(),
        page = page?.toSkirRecordId(),
        exists = exists,
    )

private fun PageDocumentDiagnostic.toWire(): WireDiagnostic =
    WireDiagnostic(
        code = code,
        message = message,
        element = element?.ref<Element>()?.toSkirRecordId(),
        slot = slot?.value,
        target = target?.toSkirRecordId(),
    )

private fun PageCompileStatus.toWire(): WireCompileStatus =
    when (this) {
        PageCompileStatus.NotCompiled -> {
            WireCompileStatus.NOT_COMPILED
        }

        is PageCompileStatus.Active -> {
            WireCompileStatus.createActive(manifestId = manifestId)
        }

        is PageCompileStatus.Blocked -> {
            WireCompileStatus.createBlocked(
                lastActiveManifestId = lastActiveManifestId,
                diagnosticCount = diagnosticCount,
            )
        }
    }

private fun AuthoringResourceChange.toWire(): WireChange =
    when (this) {
        is AuthoringResourceChange.UpsertBook -> WireChange.UpsertBookWrapper(book.toWire())
        is AuthoringResourceChange.RemoveBook -> WireChange.RemoveBookWrapper(id.toSkirRecordId())
        is AuthoringResourceChange.UpsertTag -> WireChange.UpsertTagWrapper(tag.toWire())
        is AuthoringResourceChange.RemoveTag -> WireChange.RemoveTagWrapper(id.toSkirRecordId())
        is AuthoringResourceChange.UpsertPage -> WireChange.UpsertPageWrapper(page.toWire())
        is AuthoringResourceChange.RemovePage -> WireChange.RemovePageWrapper(id.toSkirRecordId())
        is AuthoringResourceChange.UpsertElement -> WireChange.UpsertElementWrapper(element.toWire())
        is AuthoringResourceChange.RemoveElement -> WireChange.RemoveElementWrapper(id.ref<Element>().toSkirRecordId())
    }

private fun AuthoringResourceRef.toWire(): WireResourceRef =
    when (this) {
        is AuthoringResourceRef.Book -> WireResourceRef.BookWrapper(id.toSkirRecordId())
        is AuthoringResourceRef.Tag -> WireResourceRef.TagWrapper(id.toSkirRecordId())
        is AuthoringResourceRef.Page -> WireResourceRef.PageWrapper(id.toSkirRecordId())
        is AuthoringResourceRef.Element -> WireResourceRef.ElementWrapper(id.ref<Element>().toSkirRecordId())
    }

private fun PropertyConflict.toWire(): WirePropertyConflict =
    WirePropertyConflict(
        resource = resource.toWire(),
        path = path.toWire(),
        expected = expected?.toWire(),
        actual = actual?.toWire(),
    )

private fun AuthoringPropertyValue.toWire(): WirePropertyValue =
    when (this) {
        is AuthoringPropertyValue.StringValue -> {
            WirePropertyValue.StringWrapper(value)
        }

        is AuthoringPropertyValue.IntegerValue -> {
            WirePropertyValue.SignedThirtyTwoWrapper(value)
        }

        is AuthoringPropertyValue.ColorValue -> {
            WirePropertyValue.ColorWrapper(value.toSkir())
        }

        is AuthoringPropertyValue.ResourceValue -> {
            WirePropertyValue.RecordIdWrapper(value.toSkirRecordId())
        }

        is AuthoringPropertyValue.ResourcesValue -> {
            WirePropertyValue.RecordIdsWrapper(value.map { it.toSkirRecordId() })
        }

        is AuthoringPropertyValue.PlacementValue -> {
            WirePropertyValue.ElementPlacementWrapper(value.toWire())
        }

        is AuthoringPropertyValue.DataValueValue -> {
            WirePropertyValue.TypedValueWrapper(SkirDataValueCodec.encode(value).getOrThrow())
        }
    }

private fun AuthoringDiagnostic.toWire(): skirout.library.v1.authoring.AuthoringDiagnostic =
    skirout.library.v1.authoring.AuthoringDiagnostic(
        code = code,
        message = message,
        resource = resource?.toWire(),
        path = path?.toWire(),
    )

private fun ElementValuePath.toWire(): DataPath =
    DataPath(
        segments =
            segments.map {
                when (it) {
                    is ElementValuePathSegment.Field -> {
                        DataPathSegment.createField(fieldName = it.name)
                    }

                    is ElementValuePathSegment.Index -> {
                        DataPathSegment.createIndex(index = it.index)
                    }

                    is ElementValuePathSegment.MapKey -> {
                        DataPathSegment.createMapKey(key = SkirDataValueCodec.encode(it.key).getOrThrow())
                    }
                }
            },
    )
