package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementRevision
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutation
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.ReferenceDecomposer
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.StoredElementValue
import com.typewritermc.elements.ref
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import kotlin.uuid.Uuid
import com.typewritermc.library.ref as pageRef
import com.typewritermc.realm.TestPageKinds as PageType

val ElementRepositoryTest by testSuite {
    test("create batches persist structured values containment and reference graph edges") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.page()
                val target = element(TARGET_ID, "Target")
                val source = element(SOURCE_ID, "Source", referenceValue(TARGET_ID))

                fixture.elements.createElements(
                    CreateElementsCommand(
                        BatchId("create"),
                        listOf(ElementCreation(page.pageRef(), source), ElementCreation(page.pageRef(), target)),
                    ),
                ) shouldBe ElementBatchResult.Success(BatchId("create"), listOf(source, target).sortedBy { it.id.value }, setOf(page))

                fixture.elements.getPageElements(page) shouldContainExactly listOf(source, target).sortedBy { it.id.value }
                fixture.database
                    .query("RETURN element:${SOURCE_ID.value.toHexString()}->element_reference->element;")
                    .take(0)
                    .getArray()
                    .map { it.getRecordId().id.string } shouldContainExactly listOf(TARGET_ID.value.toHexString())
            }
        }
    }

    test("revision conflict rejects the complete value batch") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.page()
                fixture.elements.createElements(
                    CreateElementsCommand(
                        BatchId("seed"),
                        listOf(
                            ElementCreation(page.pageRef(), element(SOURCE_ID, "Source")),
                            ElementCreation(page.pageRef(), element(TARGET_ID, "Target")),
                        ),
                    ),
                )

                val result =
                    fixture.elements.updateElementValues(
                        UpdateElementValuesCommand(
                            BatchId("update"),
                            listOf(
                                ElementValueUpdate(SOURCE_ID, 1, "Changed", setPlainValue("changed")),
                                ElementValueUpdate(TARGET_ID, 2, "Never", setPlainValue("never")),
                            ),
                        ),
                    )

                result shouldBe
                    ElementBatchResult.Conflict(
                        listOf(ElementConflict(TARGET_ID, 2, element(TARGET_ID, "Target"))),
                    )
                fixture.elements.getPageElements(page).map(StoredElement::name) shouldContainExactly listOf("Source", "Target")
            }
        }
    }

    test("delete batches remove owned and incoming reference edges") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.page()
                fixture.elements.createElements(
                    CreateElementsCommand(
                        BatchId("seed"),
                        listOf(
                            ElementCreation(page.pageRef(), element(SOURCE_ID, "Source", referenceValue(TARGET_ID))),
                            ElementCreation(page.pageRef(), element(TARGET_ID, "Target")),
                        ),
                    ),
                )

                fixture.elements.deleteElements(
                    DeleteElementsCommand(BatchId("delete"), listOf(ElementDeletion(TARGET_ID, 1))),
                )

                fixture.database
                    .query("SELECT VALUE out FROM element_reference WHERE in = element:${SOURCE_ID.value.toHexString()};")
                    .take(0)
                    .getArray()
                    .map { it.getRecordId().id.string } shouldContainExactly emptyList()
            }
        }
    }

    test("repeated batch ids return the original result without another mutation") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.page()
                fixture.elements.createElements(
                    CreateElementsCommand(BatchId("seed"), listOf(ElementCreation(page.pageRef(), element(SOURCE_ID, "Source")))),
                )
                val command =
                    UpdateElementValuesCommand(
                        BatchId("idempotent"),
                        listOf(ElementValueUpdate(SOURCE_ID, 1, "Changed", setPlainValue("changed"))),
                    )

                val first = fixture.elements.updateElementValues(command)
                fixture.elements.updateElementValues(command) shouldBe first
                fixture.elements
                    .getPageElements(page)
                    .single()
                    .revision shouldBe ElementRevision(2)

                fixture.elements.updateElementValues(
                    command.copy(updates = listOf(ElementValueUpdate(SOURCE_ID, 2, "Different", setPlainValue("different")))),
                ) shouldBe ElementBatchResult.ValidationFailure(listOf(ElementBatchDiagnostic("batch-id-reused")))
            }
        }
    }

    test("operation commands reject empty batches") {
        shouldThrow<IllegalArgumentException> { DeleteElementsCommand(BatchId("empty"), emptyList()) }
        shouldThrow<IllegalArgumentException> { MoveGraphElementsCommand(BatchId("empty"), emptyList()) }
    }

    test("successful batches emit one committed page revision") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.page()
                val invalidations = mutableListOf<PageInvalidation>()
                val repository =
                    SurrealElementRepository(
                        fixture.database,
                        fixture.elementTypeGraphs,
                        encodeEvents = {
                            invalidations += it
                            emptyList()
                        },
                    )
                val request =
                    CreateElementsCommand(
                        BatchId("revisioned-element-create"),
                        listOf(ElementCreation(page.pageRef(), element(SOURCE_ID, "Source"))),
                    )

                repository.createElements(request) as ElementBatchResult.Success
                repository.createElements(request) as ElementBatchResult.Success

                invalidations shouldBe
                    listOf(
                        PageInvalidation(
                            BatchId("revisioned-element-create"),
                            revision = 3,
                            pageIds = setOf(page),
                            affectsCompilation = true,
                        ),
                    )
            }
        }
    }
}

private suspend fun RepositoryFixture.page(): com.typewritermc.library.PageId {
    val book = books.createBook("elements_book", "book", Color(argb = 0), emptyList()).successValue()
    return pages
        .createPage(book.bookId, "elements_page", PageType.STATIC, "", 0)
        .successValue()
        .pageId
        .toPageId()
}

private fun element(
    id: ElementInstanceId,
    name: String,
    value: StoredElementValue = plainValue(name.lowercase()),
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

private fun plainValue(value: String): StoredElementValue =
    StoredElementValue(
        DataValue.Record(mapOf("text" to DataValue.StringValue(value))),
        emptyList(),
    )

private fun setPlainValue(value: String): List<ElementValueMutation> =
    listOf(
        ElementValueMutation.SetValue(
            ElementValuePath(),
            DataValue.Record(mapOf("text" to DataValue.StringValue(value))),
        ),
    )

private fun referenceValue(target: ElementInstanceId): StoredElementValue =
    ReferenceDecomposer { ReferenceSlotId("next") }.decompose(
        TypeGraph(REF_EXPRESSION, emptyList()),
        DataValue.StringValue(target.ref<com.typewritermc.elements.Element>().id.referenceString()),
    )

private val SOURCE_ID = ElementInstanceId(Uuid.parseHex("10000000000000000000000000000001"))
private val TARGET_ID = ElementInstanceId(Uuid.parseHex("10000000000000000000000000000002"))
private val ELEMENT_TYPE = TEST_ELEMENT_TYPE
private val REF_EXPRESSION =
    TypeExpression.Named(
        ResolvedTypeRef(
            TypeId.Qualified("typewriter/v1", "Ref"),
            1,
            listOf(TypeExpression.Named(ResolvedTypeRef(TypeId.Qualified("test", "Entry"), 1))),
        ),
    )
