package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ref
import com.typewritermc.library.PageId
import com.typewritermc.realm.routes.toLibrary
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import com.typewritermc.library.pageId as toLibraryPageId
import com.typewritermc.library.ref as pageRef
import com.typewritermc.realm.TestPageKinds as PageType

val PageDocumentRepositoryTest by testSuite {
    test("page documents include local values and cross page reference summaries") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = fixture.createBook("shared_book")
                val firstPage = fixture.createPage("first_page", book.id, PageType.STATIC.toLibrary()).id
                val secondPage = fixture.createPage("second_page", book.id, PageType.STATIC.toLibrary()).id
                fixture.createElement(secondPage, TARGET_ID, "Target", defaultValue("Target"), TypeGraph(TypeExpression.Any, emptyList()))
                fixture.createElement(firstPage, SOURCE_ID, "Source", referenceValue(TARGET_ID), REFERENCE_GRAPH)
                val documents = SurrealPageDocumentRepository(fixture.database) { null }

                val first = requireNotNull(documents.getPageDocument(firstPage))
                first.elements.map { it.id } shouldContainExactly listOf(SOURCE_ID)
                first.crossPageTargets.single().let { summary ->
                    summary.id shouldBe TARGET_ID.ref<com.typewritermc.elements.Element>().id
                    summary.name shouldBe "Target"
                    summary.page?.toLibraryPageId() shouldBe secondPage
                    summary.exists shouldBe true
                }

                val second = requireNotNull(documents.getPageDocument(secondPage))
                second.crossPageSources.map { it.id } shouldContainExactly
                    listOf(SOURCE_ID.ref<com.typewritermc.elements.Element>().id)
            }
        }
    }

    test("page documents diagnose references whose target never existed") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.page("dangling")
                fixture.createElement(page, MISSING_ID, "Missing", defaultValue("Missing"), TypeGraph(TypeExpression.Any, emptyList()))
                fixture.createElement(page, SOURCE_ID, "Source", referenceValue(MISSING_ID), REFERENCE_GRAPH)
                fixture.deleteElement(MISSING_ID)

                val document = requireNotNull(SurrealPageDocumentRepository(fixture.database) { null }.getPageDocument(page))

                document.crossPageTargets.single().exists shouldBe false
                document.diagnostics.map { it.code }.sorted() shouldContainExactly
                    listOf("dangling-reference", "element-type-unavailable")
            }
        }
    }
}

private suspend fun RepositoryFixture.deleteElement(id: ElementInstanceId) {
    authoring.apply(
        AuthoringBatch(
            BatchId("delete-element-${id.value}"),
            listOf(AuthoringOperation.DeleteElement(id)),
        ),
    )
}

private suspend fun RepositoryFixture.page(name: String): PageId {
    val book = createBook("${name}_book", name)
    return createPage("${name}_page", book.id, PageType.STATIC.toLibrary()).id
}

private suspend fun RepositoryFixture.createElement(
    page: PageId,
    id: ElementInstanceId,
    name: String,
    value: DataValue,
    graph: TypeGraph,
) {
    val type = if (graph.root == REF_EXPRESSION) REFERENCE_ELEMENT_TYPE else ELEMENT_TYPE
    val elementGraph =
        TypeGraph(
            TypeExpression.Record(
                listOf(
                    TypeField("id", TypeExpression.StringType()),
                    TypeField("name", TypeExpression.StringType()),
                    TypeField("payload", graph.root),
                ),
            ),
            graph.definitions,
        )
    registerElementType(type, elementGraph)
    authoring.apply(
        AuthoringBatch(
            BatchId("create-element-${id.value}"),
            listOf(
                AuthoringOperation.CreateElement(
                    AuthoringElement(
                        id = id,
                        page = page.pageRef(),
                        elementType = type,
                        schemaRevision = 1,
                        value =
                            DataValue.Record(
                                mapOf(
                                    "id" to DataValue.StringValue(id.value),
                                    "name" to DataValue.StringValue(name),
                                    "payload" to value,
                                ),
                            ),
                        placement = ElementPlacement.Graph(0, 0, 2, 1),
                    ),
                ),
            ),
        ),
    )
}

private fun defaultValue(name: String): DataValue = DataValue.Record(mapOf("text" to DataValue.StringValue(name)))

private fun referenceValue(target: ElementInstanceId): DataValue = DataValue.Reference(target.ref<com.typewritermc.elements.Element>().id)

private val SOURCE_ID = ElementInstanceId("kd9pn4fa2s7m8q3v6x0z")
private val TARGET_ID = ElementInstanceId("nx9pn4fa2s7m8q3v6x0z")
private val MISSING_ID = ElementInstanceId("30000000000000000000000000000003")
private val ELEMENT_TYPE = ElementTypeId(DeclaredTypeId.parse("40000000000000000000000000000001"))
private val REFERENCE_ELEMENT_TYPE = ElementTypeId(DeclaredTypeId.parse("40000000000000000000000000000002"))
private val REFERENCEABLE_TYPE = ResolvedTypeRef(TypeId.Qualified("com.typewritermc.types", "Referenceable"), 1)
private val ELEMENT_REFERENCE_TYPE = ResolvedTypeRef(TypeId.Qualified("com.typewritermc.elements", "Element"), 1)
private val REF_EXPRESSION = TypeExpression.Reference(ELEMENT_REFERENCE_TYPE)
private val REFERENCE_GRAPH =
    TypeGraph(
        REF_EXPRESSION,
        listOf(
            TypeDefinition(REFERENCEABLE_TYPE, NominalTypeKind.OPEN_ABSTRACT),
            TypeDefinition(ELEMENT_REFERENCE_TYPE, NominalTypeKind.OPEN_ABSTRACT, parents = listOf(REFERENCEABLE_TYPE)),
        ),
    )
