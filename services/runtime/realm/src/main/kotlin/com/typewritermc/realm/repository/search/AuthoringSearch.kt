package com.typewritermc.realm.repository.search

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.TagId
import com.typewritermc.realm.repository.AuthoringResourceRef
import com.typewritermc.types.Color
import com.typewritermc.types.Icon

internal interface AuthoringSearchRepository {
    fun search(request: AuthoringSearchRequest): AuthoringSearchResult

    fun suggest(request: AuthoringSelectorSuggestionRequest): AuthoringSelectorSuggestions
}

internal data class AuthoringSearchRequest(
    val query: String,
    val terms: List<String>,
    val filter: SearchFilterExpression<AuthoringSearchFilter>? = null,
    val contextPage: PageId? = null,
)

internal data class AuthoringSearchFilter(
    val kind: AuthoringSelectorKind,
    val value: String,
)

internal enum class AuthoringSelectorKind {
    BOOK,
    PAGE,
    TAG,
    ELEMENT_TYPE,
}

internal data class AuthoringSelectorSuggestionRequest(
    val kind: AuthoringSelectorKind,
    val partial: String,
    val filter: SearchFilterExpression<AuthoringSearchFilter>? = null,
    val contextPage: PageId? = null,
)

internal data class AuthoringSearchResult(
    val hits: List<AuthoringSearchHit>,
    val selectorValidations: List<AuthoringSelectorValidation> = emptyList(),
)

internal data class AuthoringSelectorSuggestions(
    val values: List<String>,
    val exhaustive: Boolean,
)

internal data class AuthoringSelectorValidation(
    val kind: AuthoringSelectorKind,
    val value: String,
    val accepted: Boolean,
)

internal data class AuthoringSearchTag(
    val id: TagId,
    val name: String,
    val color: Color,
)

internal data class AuthoringSearchCandidate(
    val hit: AuthoringSearchHit,
    val evidence: AuthoringMatchEvidence,
)

internal data class AuthoringMatchEvidence(
    val term: String?,
    val kind: AuthoringMatchKind,
    val score: Double,
)

internal enum class AuthoringMatchKind {
    IDENTITY,
    EXACT_NAME,
    LEXICAL_NAME,
    PREFIX_NAME,
    EXACT_CONTENT,
    APPROXIMATE_NAME,
    APPROXIMATE_CONTENT,
}

internal sealed interface AuthoringSearchHit {
    val resource: AuthoringResourceRef
    val title: String
    val contextBook: BookId?
    val contextPage: PageId?
    val contextChapter: ChapterPath?
    val match: AuthoringSearchMatch?

    data class Book(
        val id: BookId,
        override val title: String,
        val icon: Icon,
        val color: Color,
        val tagIds: List<TagId>,
        val tags: List<AuthoringSearchTag> = emptyList(),
    ) : AuthoringSearchHit {
        override val resource = AuthoringResourceRef.Book(id)
        override val contextBook = id
        override val contextPage: PageId? = null
        override val contextChapter: ChapterPath? = null
        override val match: AuthoringSearchMatch? = null
    }

    data class Tag(
        val id: TagId,
        override val title: String,
        val color: Color,
    ) : AuthoringSearchHit {
        override val resource = AuthoringResourceRef.Tag(id)
        override val contextBook: BookId? = null
        override val contextPage: PageId? = null
        override val contextChapter: ChapterPath? = null
        override val match: AuthoringSearchMatch? = null
    }

    data class Page(
        val id: PageId,
        override val title: String,
        val book: BookId,
        val bookTitle: String,
        val chapter: ChapterPath,
        val kind: PageKindRef,
    ) : AuthoringSearchHit {
        override val resource = AuthoringResourceRef.Page(id)
        override val contextBook = book
        override val contextPage = id
        override val contextChapter = chapter
        override val match: AuthoringSearchMatch? = null
    }

    data class Element(
        val id: ElementInstanceId,
        override val title: String,
        val elementType: ElementTypeId,
        val page: PageId,
        val pageTitle: String,
        val book: BookId,
        val bookTitle: String,
        val chapter: ChapterPath,
        val kind: PageKindRef,
        val placement: ElementPlacement,
        override val match: AuthoringSearchMatch? = null,
    ) : AuthoringSearchHit {
        override val resource = AuthoringResourceRef.Element(id)
        override val contextBook = book
        override val contextPage = page
        override val contextChapter = chapter
    }
}

internal data class AuthoringSearchMatch(
    val text: String,
    val start: Int,
    val end: Int,
)

internal sealed interface SearchFilterExpression<out Filter> {
    data class Value<Filter>(
        val filter: Filter,
    ) : SearchFilterExpression<Filter>

    data class And<Filter>(
        val left: SearchFilterExpression<Filter>,
        val right: SearchFilterExpression<Filter>,
    ) : SearchFilterExpression<Filter>

    data class Or<Filter>(
        val left: SearchFilterExpression<Filter>,
        val right: SearchFilterExpression<Filter>,
    ) : SearchFilterExpression<Filter>

    data class Not<Filter>(
        val expression: SearchFilterExpression<Filter>,
    ) : SearchFilterExpression<Filter>
}

internal fun <Filter> List<Filter>.conjunction(): SearchFilterExpression<Filter>? {
    var expression: SearchFilterExpression<Filter>? = null
    forEach { filter ->
        val value: SearchFilterExpression<Filter> = SearchFilterExpression.Value(filter)
        expression = expression?.let { SearchFilterExpression.And(it, value) } ?: value
    }
    return expression
}
