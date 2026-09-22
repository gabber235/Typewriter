package com.typewritermc.realm.repository

import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.library.BOOK_PAGES_RELATION_ID
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.realm.CoreResourceDefinitionIds
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypedValueEnvelope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder

val AuthoringGraphQueryEngineTest by testSuite {
    test("named selections answer ownership and neighborhood queries together") {
        val result =
            AuthoringGraphQueryEngine(TypeCatalog(emptyList())).evaluate(
                generation = "catalog",
                sequence = 7,
                resources = listOf(book, page, localEntry, externalEntry),
                edges =
                    listOf(
                        declared("book-page", book.id, page.id, BOOK_PAGES_RELATION_ID),
                        declared("page-entry", page.id, localEntry.id, PAGE_ELEMENTS_RELATION_ID),
                        reference("cross-page", localEntry.id, externalEntry.id),
                    ),
                selections =
                    listOf(
                        GraphSelection(
                            key = "pages-in-book",
                            seed = ResourceSeed.Ids(listOf(book.id)),
                            steps =
                                listOf(
                                    RelationStep(
                                        relations = RelationFilter.Declared(setOf(RelationId(BOOK_PAGES_RELATION_ID))),
                                        direction = RelationDirection.OUTGOING,
                                    ),
                                ),
                        ),
                        GraphSelection(
                            key = "page-neighborhood",
                            seed = ResourceSeed.Ids(listOf(page.id)),
                            steps =
                                listOf(
                                    RelationStep(
                                        relations = RelationFilter.Declared(setOf(RelationId(PAGE_ELEMENTS_RELATION_ID))),
                                        direction = RelationDirection.OUTGOING,
                                    ),
                                    RelationStep(
                                        relations = RelationFilter.Any,
                                        direction = RelationDirection.BOTH,
                                    ),
                                ),
                        ),
                        GraphSelection(
                            key = "entry-relations",
                            seed = ResourceSeed.Ids(listOf(localEntry.id)),
                            steps = listOf(RelationStep(direction = RelationDirection.BOTH)),
                        ),
                    ),
            ) as AuthoringGraphQueryResult.Success

        result.snapshot.selections
            .single { it.key == "pages-in-book" }
            .resourceIds shouldContainExactlyInAnyOrder
            listOf(book.id, page.id)
        result.snapshot.selections
            .single { it.key == "page-neighborhood" }
            .resourceIds shouldContainExactlyInAnyOrder
            listOf(page.id, localEntry.id, externalEntry.id)
        result.snapshot.selections
            .single { it.key == "entry-relations" }
            .edgeIds shouldContainExactlyInAnyOrder
            listOf("page-entry", "cross-page")
    }
}

private val rootType =
    ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("11111111111111111111111111111111")), 1)

private val book = resource("book", CoreResourceDefinitionIds.BOOK)
private val page = resource("page", CoreResourceDefinitionIds.PAGE)
private val localEntry = resource("local-entry", CoreResourceDefinitionIds.ELEMENT)
private val externalEntry = resource("external-entry", CoreResourceDefinitionIds.ELEMENT)

private fun resource(
    id: String,
    definition: com.typewritermc.realm.ResourceDefinitionId,
) = AuthoringGraphResource(
    id = ResourceId(id),
    definition = definition,
    content = TypedValueEnvelope(TypeExpression.Named(rootType), DataValue.Record(emptyMap())),
)

private fun declared(
    id: String,
    source: ResourceId,
    target: ResourceId,
    relationId: String,
) = StoredResourceRelation(id, source, target, ResourceRelationOrigin.Declared(RelationId(relationId)))

private fun reference(
    id: String,
    source: ResourceId,
    target: ResourceId,
) = StoredResourceRelation(
    id,
    source,
    target,
    ResourceRelationOrigin.Reference(ReferenceSlotId("target"), DataPath(), TypeExpression.Any),
)
