package com.typewritermc.realm.repository

import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.library.BOOK_PAGES_RELATION_ID
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.realm.CoreResourceDefinitionIds
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypedValueEnvelope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder

val AuthoringGraphQueryEngineTest by testSuite {
    test("assignability rejects a generic argument mismatch") {
        val parent = type("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        val candidate = type("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(
                        id = candidate,
                        kind = NominalTypeKind.CONCRETE,
                        parameters = listOf(TypeParameter("T")),
                        parents = listOf(parent.withArguments(listOf(TypeExpression.Parameter("T")))),
                    ),
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                ),
            )
        val result =
            AuthoringGraphQueryEngine(catalog).evaluate(
                generation = "catalog",
                sequence = 1,
                resources =
                    listOf(
                        resource(
                            "generic",
                            CoreResourceDefinitionIds.ELEMENT,
                            candidate.withArguments(listOf(named("cccccccccccccccccccccccccccccccc"))),
                        ),
                    ),
                edges = emptyList(),
                selections =
                    listOf(
                        GraphSelection(
                            key = "generic",
                            seed =
                                ResourceSeed.Ids(
                                    listOf(ResourceId("generic")),
                                    TypeExpression.Named(parent.withArguments(listOf(named("dddddddddddddddddddddddddddddddd")))),
                                ),
                        ),
                    ),
            ) as AuthoringGraphQueryResult.Success

        result.snapshot.selections
            .single()
            .incompatibleIds shouldContainExactlyInAnyOrder listOf(ResourceId("generic"))
    }

    test("assignability rejects a revision mismatch") {
        val type = type("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        val resource = resource("revision", CoreResourceDefinitionIds.ELEMENT, type)
        val result =
            AuthoringGraphQueryEngine(TypeCatalog(emptyList())).evaluate(
                generation = "catalog",
                sequence = 1,
                resources = listOf(resource),
                edges = emptyList(),
                selections =
                    listOf(
                        GraphSelection(
                            key = "revision",
                            seed = ResourceSeed.Ids(listOf(resource.id), TypeExpression.Named(type.copy(revision = 2))),
                        ),
                    ),
            ) as AuthoringGraphQueryResult.Success

        result.snapshot.selections
            .single()
            .incompatibleIds shouldContainExactlyInAnyOrder listOf(resource.id)
    }

    test("assignability substitutes generic parent arguments") {
        val parent = type("ffffffffffffffffffffffffffffffff")
        val child = type("12121212121212121212121212121212")
        val argument = named("13131313131313131313131313131313")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(
                        id = child,
                        kind = NominalTypeKind.CONCRETE,
                        parameters = listOf(TypeParameter("T")),
                        parents = listOf(parent.withArguments(listOf(TypeExpression.Parameter("T")))),
                    ),
                ),
            )
        val value = resource("parent", CoreResourceDefinitionIds.ELEMENT, child.withArguments(listOf(argument)))
        val result =
            AuthoringGraphQueryEngine(catalog).evaluate(
                generation = "catalog",
                sequence = 1,
                resources = listOf(value),
                edges = emptyList(),
                selections =
                    listOf(
                        GraphSelection(
                            key = "parent",
                            seed = ResourceSeed.Ids(listOf(value.id), TypeExpression.Named(parent.withArguments(listOf(argument)))),
                        ),
                    ),
            ) as AuthoringGraphQueryResult.Success

        result.snapshot.selections
            .single()
            .resourceIds shouldContainExactlyInAnyOrder listOf(value.id)
    }

    test("assignability substitutes nested generic parent arguments") {
        val parent = type("14141414141414141414141414141414")
        val middle = type("15151515151515151515151515151515")
        val child = type("16161616161616161616161616161616")
        val argument = named("17171717171717171717171717171717")
        val nestedArgument = TypeExpression.ListType(argument)
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(
                        id = middle,
                        kind = NominalTypeKind.OPEN_ABSTRACT,
                        parameters = listOf(TypeParameter("T")),
                        parents =
                            listOf(
                                parent.withArguments(
                                    listOf(TypeExpression.ListType(TypeExpression.Parameter("T"))),
                                ),
                            ),
                    ),
                    TypeDefinition(
                        id = child,
                        kind = NominalTypeKind.CONCRETE,
                        parameters = listOf(TypeParameter("T")),
                        parents = listOf(middle.withArguments(listOf(TypeExpression.Parameter("T")))),
                    ),
                ),
            )
        val value = resource("nested-parent", CoreResourceDefinitionIds.ELEMENT, child.withArguments(listOf(argument)))
        val result =
            AuthoringGraphQueryEngine(catalog).evaluate(
                generation = "catalog",
                sequence = 1,
                resources = listOf(value),
                edges = emptyList(),
                selections =
                    listOf(
                        GraphSelection(
                            key = "nested-parent",
                            seed =
                                ResourceSeed.Ids(
                                    listOf(value.id),
                                    TypeExpression.Named(parent.withArguments(listOf(nestedArgument))),
                                ),
                        ),
                    ),
            ) as AuthoringGraphQueryResult.Success

        result.snapshot.selections
            .single()
            .resourceIds shouldContainExactlyInAnyOrder listOf(value.id)
    }

    test("policy dependency traversal expands every relation family from the same frontier") {
        val referenced = resource("referenced", CoreResourceDefinitionIds.ELEMENT)
        val requirement =
            GraphReadRequirement(
                relations = setOf(RelationId(BOOK_PAGES_RELATION_ID)),
                direction = GraphReadRequirement.Direction.OUTGOING,
                outgoingReferences = true,
                maximumDepth = 1,
            )
        val result =
            AuthoringGraphQueryEngine(TypeCatalog(emptyList())).evaluate(
                generation = "catalog",
                sequence = 1,
                resources = listOf(book, page, referenced),
                edges =
                    listOf(
                        declared("book-page", book.id, page.id, BOOK_PAGES_RELATION_ID),
                        reference("book-reference", book.id, referenced.id),
                    ),
                selections =
                    listOf(
                        requirement.toSelection(
                            key = "policy",
                            seed = ResourceSeed.Ids(listOf(book.id)),
                        ),
                    ),
            ) as AuthoringGraphQueryResult.Success

        result.snapshot.selections
            .single()
            .resourceIds shouldContainExactlyInAnyOrder listOf(book.id, page.id, referenced.id)
    }

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
    root: ResolvedTypeRef = rootType,
) = AuthoringGraphResource(
    id = ResourceId(id),
    definition = definition,
    content = TypedValueEnvelope(TypeExpression.Named(root), DataValue.Record(emptyMap())),
)

private fun type(value: String) = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse(value)), 1)

private fun named(value: String) = TypeExpression.Named(type(value))

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
