package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementRevision
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ReferenceDecomposer
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.StoredElementValue
import com.typewritermc.elements.ref
import com.typewritermc.library.PageId
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import kotlin.uuid.Uuid
import com.typewritermc.library.pageId as toLibraryPageId
import com.typewritermc.library.ref as pageRef
import com.typewritermc.realm.TestPageKinds as PageType
import com.typewritermc.realm.repository.utils.toPageId as toDomainPageId

val PageDocumentRepositoryTest by testSuite {
    test("page documents include local values and cross page reference summaries") {
        runTest {
            RepositoryFixture().use { fixture ->
                val firstPage = fixture.page("first")
                val secondPage = fixture.page("second")
                fixture.elements.createElements(
                    CreateElementsCommand(
                        BatchId("page-document-seed"),
                        listOf(
                            ElementCreation(firstPage.pageRef(), element(SOURCE_ID, "Source", referenceValue(TARGET_ID))),
                            ElementCreation(secondPage.pageRef(), element(TARGET_ID, "Target")),
                        ),
                    ),
                )
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
                fixture.elements.createElements(
                    CreateElementsCommand(
                        BatchId("dangling-document-seed"),
                        listOf(ElementCreation(page.pageRef(), element(SOURCE_ID, "Source", referenceValue(MISSING_ID)))),
                    ),
                )

                val document = requireNotNull(SurrealPageDocumentRepository(fixture.database) { null }.getPageDocument(page))

                document.crossPageTargets.single().exists shouldBe false
                document.diagnostics.map { it.code }.sorted() shouldContainExactly
                    listOf("dangling-reference", "element-type-unavailable")
            }
        }
    }
}

private suspend fun RepositoryFixture.page(name: String): PageId {
    val book = books.createBook("${name}_book", name, Color(argb = 0), emptyList()).successValue()
    return pages
        .createPage(book.bookId, "${name}_page", PageType.STATIC, "", 0)
        .successValue()
        .pageId
        .toDomainPageId()
}

private fun element(
    id: ElementInstanceId,
    name: String,
    value: StoredElementValue = StoredElementValue(DataValue.Record(mapOf("text" to DataValue.StringValue(name))), emptyList()),
): StoredElement =
    StoredElement(
        id = id,
        revision = ElementRevision(1),
        elementType = ELEMENT_TYPE,
        schemaRevision = 1,
        name = name,
        value = value,
        placement = ElementPlacement.Graph(0, 0, 2, 1),
    )

private fun referenceValue(target: ElementInstanceId): StoredElementValue =
    ReferenceDecomposer { ReferenceSlotId("next") }.decompose(
        TypeGraph(REF_EXPRESSION, emptyList()),
        DataValue.StringValue(target.ref<com.typewritermc.elements.Element>().id.referenceString()),
    )

private val SOURCE_ID = ElementInstanceId(Uuid.parseHex("30000000000000000000000000000001"))
private val TARGET_ID = ElementInstanceId(Uuid.parseHex("30000000000000000000000000000002"))
private val MISSING_ID = ElementInstanceId(Uuid.parseHex("30000000000000000000000000000003"))
private val ELEMENT_TYPE = ElementTypeId(DeclaredTypeId.parse("40000000000000000000000000000001"))
private val REF_EXPRESSION =
    TypeExpression.Named(
        ResolvedTypeRef(
            TypeId.Qualified("typewriter/v1", "Ref"),
            revision = 1,
            arguments = listOf(TypeExpression.Any),
        ),
    )
