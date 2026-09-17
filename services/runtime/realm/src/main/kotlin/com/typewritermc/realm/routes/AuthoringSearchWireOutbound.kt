package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.search.AuthoringSearchHit
import com.typewritermc.realm.repository.search.AuthoringSearchMatch
import com.typewritermc.realm.repository.search.AuthoringSearchResult
import com.typewritermc.realm.repository.search.AuthoringSearchTag
import com.typewritermc.realm.repository.search.AuthoringSelectorKind
import com.typewritermc.realm.repository.search.AuthoringSelectorValidation
import com.typewritermc.realm.repository.utils.toSkirRecordId
import skirout.library.v1.authoring.SearchAuthoringContentResponse
import skirout.library.v1.authoring.AuthoringSearchBook as WireBook
import skirout.library.v1.authoring.AuthoringSearchBookContext as WireBookContext
import skirout.library.v1.authoring.AuthoringSearchElement as WireElement
import skirout.library.v1.authoring.AuthoringSearchHit as WireHit
import skirout.library.v1.authoring.AuthoringSearchMatch as WireMatch
import skirout.library.v1.authoring.AuthoringSearchPage as WirePage
import skirout.library.v1.authoring.AuthoringSearchSnapshot as WireSnapshot
import skirout.library.v1.authoring.AuthoringSearchTag as WireTag
import skirout.library.v1.authoring.AuthoringSelectorKind as WireSelectorKind
import skirout.library.v1.authoring.AuthoringSelectorValidation as WireSelectorValidation

internal fun AuthoringSearchResult.toWireResponse(): SearchAuthoringContentResponse =
    SearchAuthoringContentResponse.SuccessWrapper(
        WireSnapshot(
            hits = hits.map(AuthoringSearchHit::toWire),
            selectorValidations = selectorValidations.map(AuthoringSelectorValidation::toWire),
        ),
    )

private fun AuthoringSelectorValidation.toWire(): WireSelectorValidation =
    WireSelectorValidation(
        selector = kind.toWire(),
        value = value,
        accepted = accepted,
    )

private fun AuthoringSelectorKind.toWire(): WireSelectorKind =
    when (this) {
        AuthoringSelectorKind.BOOK -> WireSelectorKind.BOOK
        AuthoringSelectorKind.PAGE -> WireSelectorKind.PAGE
        AuthoringSelectorKind.TAG -> WireSelectorKind.TAG
        AuthoringSelectorKind.ELEMENT_TYPE -> WireSelectorKind.ELEMENT_TYPE
    }

private fun AuthoringSearchHit.toWire(): WireHit =
    when (this) {
        is AuthoringSearchHit.Book -> {
            WireHit.BookWrapper(
                WireBook(
                    id = id.toSkirRecordId(),
                    title = title,
                    icon = icon.wireValue,
                    color = color.toSkir(),
                    tags = tags.map(AuthoringSearchTag::toWire),
                ),
            )
        }

        is AuthoringSearchHit.Tag -> {
            WireHit.TagWrapper(AuthoringSearchTag(id, title, color).toWire())
        }

        is AuthoringSearchHit.Page -> {
            WireHit.PageWrapper(toWirePage())
        }

        is AuthoringSearchHit.Element -> {
            WireHit.ElementWrapper(
                WireElement(
                    id = id.toSkirRecordId(),
                    name = title,
                    elementType = elementType.value.toString(),
                    placement = placement.toWire(),
                    page = toWirePage(),
                    match = match?.toWire(),
                ),
            )
        }
    }

private fun AuthoringSearchHit.Page.toWirePage(): WirePage =
    WirePage(
        id = id.toSkirRecordId(),
        name = title,
        kind = kind.toSkir(),
        book = WireBookContext(id = book.toSkirRecordId(), title = bookTitle),
        chapter = chapter.value,
    )

private fun AuthoringSearchHit.Element.toWirePage(): WirePage =
    WirePage(
        id = page.toSkirRecordId(),
        name = pageTitle,
        kind = kind.toSkir(),
        book = WireBookContext(id = book.toSkirRecordId(), title = bookTitle),
        chapter = chapter.value,
    )

private fun AuthoringSearchTag.toWire(): WireTag =
    WireTag(
        id = id.toSkirRecordId(),
        name = name,
        color = color.toSkir(),
    )

private fun AuthoringSearchMatch.toWire(): WireMatch =
    WireMatch(
        text = text,
        start = start,
        end = end,
    )
