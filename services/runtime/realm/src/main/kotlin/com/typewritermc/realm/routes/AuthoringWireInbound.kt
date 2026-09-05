package com.typewritermc.realm.routes

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutation
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.ElementValuePathSegment
import com.typewritermc.library.Book
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.Tag
import com.typewritermc.library.ref
import com.typewritermc.realm.repository.AuthoringBatch
import com.typewritermc.realm.repository.AuthoringElement
import com.typewritermc.realm.repository.AuthoringOperation
import com.typewritermc.realm.repository.AuthoringSnapshotScope
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.realm.repository.ExpectedChange
import com.typewritermc.realm.repository.ExpectedElementValueMutation
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.types.Color
import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.path.DataPath
import skirout.editor.v1.path.DataPathSegment
import skirout.library.v1.authoring.ApplyAuthoringBatchRequest
import skirout.library.v1.authoring.ColorChange
import skirout.library.v1.authoring.ElementPlacementChange
import skirout.library.v1.authoring.Int32Change
import skirout.library.v1.authoring.RecordIdChange
import skirout.library.v1.authoring.RecordIdListChange
import skirout.library.v1.authoring.StringChange
import skirout.library.v1.authoring.AuthoringOperation as WireOperation
import skirout.library.v1.authoring.AuthoringSnapshotScope as WireScope
import skirout.library.v1.authoring.Book as WireBook
import skirout.library.v1.authoring.ElementPlacement as WirePlacement
import skirout.library.v1.authoring.ElementValueMutation as WireMutation
import skirout.library.v1.authoring.Page as WirePage
import skirout.library.v1.authoring.PageElement as WireElement
import skirout.library.v1.authoring.Tag as WireTag

internal fun Iterable<WireScope>.toDomain(): Set<AuthoringSnapshotScope> =
    mapTo(linkedSetOf()) { scope ->
        when (scope) {
            WireScope.LIBRARY -> AuthoringSnapshotScope.Library
            is WireScope.BookWrapper -> AuthoringSnapshotScope.Book(scope.value.bookId.toBookId())
            is WireScope.PageWrapper -> AuthoringSnapshotScope.Page(scope.value.pageId.toPageId())
            is WireScope.Unknown -> error("Unknown authoring snapshot scope")
        }
    }

internal fun ApplyAuthoringBatchRequest.toDomain(): AuthoringBatch =
    AuthoringBatch(BatchId(batchId), operations.map(WireOperation::toDomain))

private fun WireOperation.toDomain(): AuthoringOperation =
    when (this) {
        is WireOperation.CreateBookWrapper -> {
            value.book.toDomain()
        }

        is WireOperation.PatchBookWrapper -> {
            AuthoringOperation.PatchBook(
                id = value.id.toBookId(),
                title = value.title?.toDomain(::LibraryName),
                icon = value.icon?.toDomain(Icon::parse),
                color = value.color?.toDomain { Color(it.argb.toUInt()) },
                tags = value.tags?.toDomain { ids -> ids.map { it.toTagId().ref() } },
            )
        }

        is WireOperation.DeleteBookWrapper -> {
            AuthoringOperation.DeleteBook(value.id.toBookId())
        }

        is WireOperation.CreateTagWrapper -> {
            value.tag.toDomain()
        }

        is WireOperation.PatchTagWrapper -> {
            AuthoringOperation.PatchTag(
                id = value.id.toTagId(),
                name = value.name?.toDomain(::LibraryName),
                color = value.color?.toDomain { Color(it.argb.toUInt()) },
                parents = value.parents?.toDomain { ids -> ids.map { it.toTagId().ref() } },
                x = value.x?.toDomain(),
                y = value.y?.toDomain(),
                width = value.width?.toDomain(),
                height = value.height?.toDomain(),
            )
        }

        is WireOperation.DeleteTagWrapper -> {
            AuthoringOperation.DeleteTag(value.id.toTagId())
        }

        is WireOperation.CreatePageWrapper -> {
            AuthoringOperation.CreatePage(value.page.toDomain())
        }

        is WireOperation.PatchPageWrapper -> {
            AuthoringOperation.PatchPage(
                id = value.id.toPageId(),
                book = value.book?.toDomain { it.toBookId().ref() },
                name = value.name?.toDomain(::LibraryName),
                chapter = value.chapter?.toDomain(ChapterPath::parse),
                priority = value.priority?.toDomain(),
            )
        }

        is WireOperation.DeletePageWrapper -> {
            AuthoringOperation.DeletePage(value.id.toPageId())
        }

        is WireOperation.CreateElementWrapper -> {
            AuthoringOperation.CreateElement(value.element.toDomain())
        }

        is WireOperation.PatchElementWrapper -> {
            AuthoringOperation.PatchElement(
                id = value.id.toElementInstanceId(),
                page = value.page?.toDomain { it.toPageId().ref() },
                name = value.name?.toDomain(),
                placement = value.placement?.toDomain(WirePlacement::toDomain),
                valueMutations =
                    value.valueMutations.map {
                        ExpectedElementValueMutation(
                            expected = SkirDataValueCodec.decode(it.expected).getOrThrow(),
                            mutation = it.mutation.toDomain(),
                        )
                    },
            )
        }

        is WireOperation.DuplicateElementWrapper -> {
            AuthoringOperation.DuplicateElement(
                sourceId = value.sourceId.toElementInstanceId(),
                expectedValue = SkirDataValueCodec.decode(value.expectedValue).getOrThrow(),
                newId = value.newId.toElementInstanceId(),
                page = value.page.toPageId().ref(),
                name = value.name,
                placement = value.placement.toDomain(),
                referenceRewrites =
                    value.referenceRewrites.associate {
                        it.source.toResourceId() to it.target.toResourceId()
                    },
            )
        }

        is WireOperation.DeleteElementWrapper -> {
            AuthoringOperation.DeleteElement(value.id.toElementInstanceId())
        }

        is WireOperation.Unknown -> {
            error("Unknown authoring operation")
        }
    }

private fun WireBook.toDomain(): AuthoringOperation.CreateBook =
    AuthoringOperation.CreateBook(
        id = id.toBookId(),
        title = LibraryName(title),
        icon = Icon.parse(icon),
        color = Color(color.argb.toUInt()),
        tags = tags.map { it.toTagId().ref() },
    )

private fun WireTag.toDomain(): AuthoringOperation.CreateTag =
    AuthoringOperation.CreateTag(
        id = id.toTagId(),
        name = LibraryName(name),
        color = Color(color.argb.toUInt()),
        parents = parents.map { it.toTagId().ref() },
        placement = GridPlacement(placement.x, placement.y, placement.width, placement.height),
    )

private fun WirePage.toDomain(): Page =
    Page(
        id = id.toPageId(),
        book = book.toBookId().ref(),
        name = LibraryName(name),
        kind = PageKindRef(PageKindId(DeclaredTypeId.parse(kind.id.value)), kind.revision),
        chapter = ChapterPath.parse(chapter),
        priority = priority,
    )

private fun WireElement.toDomain(): AuthoringElement =
    AuthoringElement(
        id = id.toElementInstanceId(),
        page = page.toPageId().ref(),
        elementType = ElementTypeId(DeclaredTypeId.parse(elementType)),
        schemaRevision = schemaRevision,
        name = name,
        value = SkirDataValueCodec.decode(value).getOrThrow(),
        placement = placement.toDomain(),
    )

private fun WireMutation.toDomain(): ElementValueMutation =
    when (this) {
        is WireMutation.SetValueWrapper -> {
            ElementValueMutation.SetValue(value.path.toDomain(), SkirDataValueCodec.decode(value.value).getOrThrow())
        }

        is WireMutation.InsertListItemsWrapper -> {
            ElementValueMutation.InsertListItems(
                value.path.toDomain(),
                value.index,
                value.values.map { SkirDataValueCodec.decode(it).getOrThrow() },
            )
        }

        is WireMutation.RemoveListItemsWrapper -> {
            ElementValueMutation.RemoveListItems(value.path.toDomain(), value.index, value.count)
        }

        is WireMutation.ReorderListItemsWrapper -> {
            ElementValueMutation.ReorderListItems(
                value.path.toDomain(),
                value.sourceIndex,
                value.count,
                value.destinationIndex,
            )
        }

        is WireMutation.DuplicateListItemsWrapper -> {
            ElementValueMutation.DuplicateListItems(
                value.path.toDomain(),
                value.sourceIndex,
                value.count,
                value.destinationIndex,
            )
        }

        is WireMutation.PutMapEntriesWrapper -> {
            ElementValueMutation.PutMapEntries(
                value.path.toDomain(),
                value.entries.map {
                    DataMapEntry(
                        SkirDataValueCodec.decode(it.key).getOrThrow(),
                        SkirDataValueCodec.decode(it.value).getOrThrow(),
                    )
                },
            )
        }

        is WireMutation.RemoveMapEntriesWrapper -> {
            ElementValueMutation.RemoveMapEntries(
                value.path.toDomain(),
                value.keys.map { SkirDataValueCodec.decode(it).getOrThrow() },
            )
        }

        is WireMutation.ReplaceConcreteTypeWrapper -> {
            ElementValueMutation.ReplaceConcreteType(
                value.path.toDomain(),
                SkirTypeCodec.decode(value.concreteType).getOrThrow(),
                SkirDataValueCodec.decode(value.value).getOrThrow(),
            )
        }

        is WireMutation.Unknown -> {
            error("Unknown element value mutation")
        }
    }

private fun DataPath.toDomain(): ElementValuePath =
    ElementValuePath(
        segments.map {
            when (it) {
                is DataPathSegment.FieldWrapper -> {
                    ElementValuePathSegment.Field(it.value.fieldName)
                }

                is DataPathSegment.IndexWrapper -> {
                    ElementValuePathSegment.Index(it.value.index)
                }

                is DataPathSegment.MapKeyWrapper -> {
                    ElementValuePathSegment.MapKey(
                        SkirDataValueCodec.decode(it.value.key).getOrThrow(),
                    )
                }

                is DataPathSegment.Unknown -> {
                    error("Unknown data path segment")
                }
            }
        },
    )

private fun WirePlacement.toDomain(): ElementPlacement =
    when (this) {
        is WirePlacement.GraphWrapper -> ElementPlacement.Graph(value.x, value.y, value.width, value.height)
        is WirePlacement.TimelineEntryWrapper -> ElementPlacement.TimelineEntry(value.trackIndex)
        is WirePlacement.TimelineSegmentWrapper -> ElementPlacement.TimelineSegment(value.startFrame, value.endFrame)
        is WirePlacement.TimelineKeyframeWrapper -> ElementPlacement.TimelineKeyframe(value.frame)
        is WirePlacement.Unknown -> error("Unknown element placement")
    }

private fun <T> StringChange.toDomain(transform: (String) -> T): ExpectedChange<T> =
    ExpectedChange(
        transform(expected),
        transform(value),
    )

private fun StringChange.toDomain(): ExpectedChange<String> = ExpectedChange(expected, value)

private fun Int32Change.toDomain(): ExpectedChange<Int> = ExpectedChange(expected, value)

private fun <T> ColorChange.toDomain(transform: (skirout.kernel.v1.color.Color) -> T): ExpectedChange<T> =
    ExpectedChange(transform(expected), transform(value))

private fun <T> RecordIdChange.toDomain(transform: (skirout.kernel.v1.record_id.RecordId) -> T): ExpectedChange<T> =
    ExpectedChange(transform(expected), transform(value))

private typealias RecordIdListTransform<T> = (List<skirout.kernel.v1.record_id.RecordId>) -> T

private fun <T> RecordIdListChange.toDomain(transform: RecordIdListTransform<T>): ExpectedChange<T> =
    ExpectedChange(transform(expected), transform(value))

private fun <T> ElementPlacementChange.toDomain(transform: (WirePlacement) -> T): ExpectedChange<T> =
    ExpectedChange(transform(expected), transform(value))
