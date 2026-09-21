package com.typewritermc.realm.routes

import com.typewritermc.elements.ElementCatalog
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.library.BOOK_PAGES_RELATION_ID
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringResourceKind
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypedValueEnvelope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorOperator
import skirout.library.v1.authoring.SearchFacetId
import skirout.library.v1.authoring.SearchFacetRequest

val AuthoringGraphSearchRoutesTest by testSuite {
    test("selectors follow normalized ownership and inherited tags") {
        val index = fixture()

        index.matchesSelectors(element, listOf(selector("book", "Harbor")), null) shouldBe true
        index.matchesSelectors(element, listOf(selector("page", "Arrival")), null) shouldBe true
        index.matchesSelectors(element, listOf(selector("tag", "Quest")), null) shouldBe true
        index.matchesSelectors(element, listOf(selector("tag", "Missing")), null) shouldBe false
    }

    test("boolean selector expressions retain their structure") {
        val index = fixture()
        val book = selector("book", "Harbor")
        val page = selector("page", "Elsewhere")
        val expression =
            RealmSearchSelectorExpression.createBinary(
                operator_ = RealmSearchSelectorOperator.OR,
                left =
                    RealmSearchSelectorExpression.createSelector(
                        selectorId = book.selectorId,
                        key = book.key,
                        value = book.value,
                    ),
                right =
                    RealmSearchSelectorExpression.createSelector(
                        selectorId = page.selectorId,
                        key = page.key,
                        value = page.value,
                    ),
            )

        index.matchesSelectors(element, listOf(book, page), expression) shouldBe true
    }

    test("search context carries graph owners and chapter") {
        val context = fixture().context(element, listOf("Greeting".lowercase()))

        context.book?.id shouldBe book.id
        context.page?.id shouldBe page.id
        context.chapter shouldBe
            com.typewritermc.library.ChapterPath
                .parse("intro.arrival")
        context.match?.text shouldBe "Greeting"
    }

    test("facets expose useful domain values") {
        val index = fixture()

        index
            .facet(
                listOf(book, page, element),
                SearchFacetRequest(
                    facetId = SearchFacetId(value = "book"),
                    partial = null,
                    validate = emptyList(),
                ),
            ).suggestions
            .toList() shouldContainExactlyInAnyOrder listOf("book", "Harbor")
        index
            .facet(
                listOf(book, page, element),
                SearchFacetRequest(
                    facetId = SearchFacetId(value = "page"),
                    partial = null,
                    validate = emptyList(),
                ),
            ).suggestions
            .toList() shouldContainExactlyInAnyOrder listOf("page", "Arrival")
    }
}

private val ROOT = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("11111111111111111111111111111111")), 1)

private val book = resource("book", AuthoringResourceKind.BOOK, "title" to string("Harbor"), "tags" to references("tag-child"))
private val page =
    resource(
        "page",
        AuthoringResourceKind.PAGE,
        "name" to string("Arrival"),
        "chapter" to string("intro.arrival"),
    )
private val element = resource("element", AuthoringResourceKind.ELEMENT, "name" to string("Greeting"))
private val rootTag = resource("tag-root", AuthoringResourceKind.TAG, "name" to string("Quest"), "parents" to references())
private val childTag =
    resource("tag-child", AuthoringResourceKind.TAG, "name" to string("Story"), "parents" to references("tag-root"))

private fun fixture() =
    SearchGraphIndex(
        listOf(book, page, element, rootTag, childTag),
        listOf(
            declared("book-page", book.id, page.id, BOOK_PAGES_RELATION_ID),
            declared("page-element", page.id, element.id, PAGE_ELEMENTS_RELATION_ID),
            StoredResourceRelation(
                id = "ordinary-reference",
                source = element.id,
                target = rootTag.id,
                origin =
                    ResourceRelationOrigin.Reference(
                        ReferenceSlotId("tag"),
                        DataPath(),
                        TypeExpression.Any,
                    ),
            ),
        ),
        ElementCatalog(emptyList()),
    )

private fun selector(
    id: String,
    value: String,
) = RealmSearchSelector(selectorId = id, key = "$id:", value = value)

private fun resource(
    id: String,
    kind: AuthoringResourceKind,
    vararg fields: Pair<String, DataValue>,
) = AuthoringGraphResource(
    ResourceId(id),
    kind,
    TypedValueEnvelope(TypeExpression.Named(ROOT), DataValue.Record(fields.toMap())),
)

private fun declared(
    id: String,
    source: ResourceId,
    target: ResourceId,
    relation: String,
) = StoredResourceRelation(id, source, target, ResourceRelationOrigin.Declared(RelationId(relation)))

private fun string(value: String) = DataValue.StringValue(value)

private fun references(vararg ids: String) = DataValue.ListValue(ids.map { DataValue.Reference(ResourceId(it)) })
