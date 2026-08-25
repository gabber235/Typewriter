package com.typewritermc.realm.routes

import com.typewritermc.library.Book
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.ResourceRevision
import com.typewritermc.library.Tag
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import skirout.kernel.v1.page_kind.PageKindId as SkirPageKindId
import skirout.kernel.v1.page_kind.PageKindRef as SkirPageKindRef
import skirout.library.v1.book.Book as SkirBook
import skirout.library.v1.page.Page as SkirPage
import skirout.library.v1.tag.Placement as SkirPlacement
import skirout.library.v1.tag.Tag as SkirTag

internal fun Book.toSkir(): SkirBook =
    SkirBook(
        bookId = id.toSkirRecordId(),
        revision = revision.value,
        title = title.value,
        icon = icon.wireValue,
        color = color.toSkir(),
        tagIds = tags.map { it.toSkirRecordId() },
    )

internal fun SkirBook.toLibrary(): Book =
    Book(
        id = bookId.toBookId(),
        revision = ResourceRevision(revision),
        title = LibraryName(title),
        icon = Icon.parse(icon),
        color = color.toLibrary(),
        tags = tagIds.mapTo(linkedSetOf()) { it.toTagId() },
    )

internal fun Tag.toSkir(): SkirTag =
    SkirTag(
        tagId = id.toSkirRecordId(),
        revision = revision.value,
        name = name.value,
        color = color.toSkir(),
        parentIds = parents.map { it.toSkirRecordId() },
        placement = placement.toSkir(),
    )

internal fun SkirTag.toLibrary(): Tag =
    Tag(
        id = tagId.toTagId(),
        revision = ResourceRevision(revision),
        name = LibraryName(name),
        color = color.toLibrary(),
        parents = parentIds.mapTo(linkedSetOf()) { it.toTagId() },
        placement = placement.toLibrary(),
    )

internal fun Page.toSkir(): SkirPage =
    SkirPage(
        pageId = id.toSkirRecordId(),
        revision = revision.value,
        bookId = bookId.toSkirRecordId(),
        name = name.value,
        kind = kind.toSkir(),
        chapter = chapter.value,
        priority = priority,
    )

internal fun SkirPage.toLibrary(): Page =
    Page(
        id = pageId.toPageId(),
        revision = ResourceRevision(revision),
        bookId = bookId.toBookId(),
        name = LibraryName(name),
        kind = kind.toLibrary(),
        chapter = ChapterPath.parse(chapter),
        priority = priority,
    )

internal fun PageKindRef.toSkir(): SkirPageKindRef =
    SkirPageKindRef(
        id = SkirPageKindId(value = id.value.toString()),
        revision = revision,
    )

internal fun SkirPageKindRef.toLibrary(): PageKindRef =
    PageKindRef(
        id = PageKindId(DeclaredTypeId.parse(id.value)),
        revision = revision,
    )

internal fun GridPlacement.toSkir(): SkirPlacement = SkirPlacement(x = x, y = y, width = width, height = height)

internal fun SkirPlacement.toLibrary(): GridPlacement = GridPlacement(x = x, y = y, width = width, height = height)
