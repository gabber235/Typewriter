package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.search.AuthoringSearchFilter
import com.typewritermc.realm.repository.search.AuthoringSelectorKind
import com.typewritermc.realm.repository.search.SearchFilterExpression
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorBinaryExpression
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorNotExpression
import skirout.editor.v1.search.RealmSearchSelectorOperator
import skirout.library.v1.authoring.SearchAuthoringContentRequest

val AuthoringSearchRoutesTest by testSuite {
    test("route preserves applicable boolean selector structure and values") {
        val book = selector("book", "harbor")
        val page = selector("page", "arrival")
        val unknown = selector("source", "members")
        val expression =
            binary(
                RealmSearchSelectorOperator.AND,
                leaf(book),
                not(binary(RealmSearchSelectorOperator.OR, leaf(page), leaf(unknown))),
            )

        request(listOf(book, page, unknown), expression)
            .toAuthoringSearchRequest()
            .filter shouldBe
            SearchFilterExpression.And(
                filter("book", "harbor"),
                SearchFilterExpression.Not(filter("page", "arrival")),
            )
    }

    test("route retains repeated selectors when the expression is absent") {
        request(
            selectors = listOf(selector("book", "harbor"), selector("book", "forest")),
            expression = null,
        ).toAuthoringSearchRequest().filter shouldBe
            SearchFilterExpression.And(filter("book", "harbor"), filter("book", "forest"))
    }

    test("route leaves an unfiltered query unfiltered") {
        request(emptyList(), null).toAuthoringSearchRequest().filter shouldBe null
    }
}

private fun request(
    selectors: List<RealmSearchSelector>,
    expression: RealmSearchSelectorExpression?,
) = SearchAuthoringContentRequest(
    query =
        RealmSearchQuery(
            normalizedQuery = "greeting",
            terms = listOf("greeting"),
            selectors = selectors,
            selectorExpression = expression,
        ),
    contextPage = null,
)

private fun selector(
    id: String,
    value: String,
) = RealmSearchSelector(selectorId = id, key = "$id:", value = value)

private fun leaf(selector: RealmSearchSelector) = RealmSearchSelectorExpression.SelectorWrapper(selector)

private fun binary(
    operator: RealmSearchSelectorOperator,
    left: RealmSearchSelectorExpression,
    right: RealmSearchSelectorExpression,
) = RealmSearchSelectorExpression.BinaryWrapper(
    RealmSearchSelectorBinaryExpression(operator_ = operator, left = left, right = right),
)

private fun not(expression: RealmSearchSelectorExpression) =
    RealmSearchSelectorExpression.NotWrapper(RealmSearchSelectorNotExpression(expression = expression))

private fun filter(
    id: String,
    value: String,
): SearchFilterExpression<AuthoringSearchFilter> =
    SearchFilterExpression.Value(
        AuthoringSearchFilter(
            when (id) {
                "book" -> AuthoringSelectorKind.BOOK
                "page" -> AuthoringSelectorKind.PAGE
                "tag" -> AuthoringSelectorKind.TAG
                "type" -> AuthoringSelectorKind.ELEMENT_TYPE
                else -> error("Unknown authoring selector $id")
            },
            value,
        ),
    )
