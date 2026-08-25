package com.typewritermc.realm.routes

import com.typewritermc.realm.TestPageKinds
import com.typewritermc.realm.repository.TEST_ELEMENT_TYPE
import com.typewritermc.realm.repository.createBook
import com.typewritermc.realm.repository.createPage
import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.types.DataValue
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.path.DataPath
import skirout.kernel.v1.color.Color
import skirout.library.v2.authoring.CreateElementsRequest
import skirout.library.v2.authoring.CreateElementsResponse
import skirout.library.v2.authoring.ElementCreate
import skirout.library.v2.authoring.ElementPlacement
import skirout.library.v2.authoring.ElementValueMutation
import skirout.library.v2.authoring.ElementValueUpdate
import skirout.library.v2.authoring.UpdateElementValuesRequest
import skirout.library.v2.authoring.UpdateElementValuesResponse

val ElementBatchRoutesTest by testSuite {
    test("empty element batches return typed invalid responses") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "element.create.v2",
                        CreateElementsRequest(batchId = "empty_elements", elements = emptyList()),
                        CreateElementsRequest.serializer,
                        CreateElementsResponse.serializer,
                    )

                response.kind shouldBe CreateElementsResponse.Kind.INVALID_WRAPPER
            }
        }
    }

    test("element creation and structural update are reachable through V2 routes") {
        runTest {
            RouteFixture().use { fixture ->
                val book =
                    fixture.repositories.books
                        .createBook("route_book", "book", Color(argb = 0), emptyList())
                        .successValue()
                val page =
                    fixture.repositories.pages
                        .createPage(book.bookId, "route_page", TestPageKinds.STATIC, "", 0)
                        .successValue()
                        .pageId
                        .toPageId()
                val elementId = recordId("element", "30000000000000000000000000000001")
                val initial = DataValue.Record(mapOf("text" to DataValue.StringValue("initial")))

                val created =
                    fixture.request(
                        "element.create.v2",
                        CreateElementsRequest(
                            batchId = "create_route_element",
                            elements =
                                listOf(
                                    ElementCreate(
                                        id = elementId,
                                        page = page.toSkirRecordId(),
                                        elementType = TEST_ELEMENT_TYPE.value.toString(),
                                        schemaRevision = 1,
                                        name = "Entry",
                                        value = SkirDataValueCodec.encode(initial).getOrThrow(),
                                        placement = ElementPlacement.createGraphV1(x = 0, y = 0, width = 2, height = 1),
                                    ),
                                ),
                        ),
                        CreateElementsRequest.serializer,
                        CreateElementsResponse.serializer,
                    )
                created shouldBe
                    CreateElementsResponse.createSuccess(
                        batchId = "create_route_element",
                        affectedPages = listOf(page.toSkirRecordId()),
                    )

                val replacement = DataValue.Record(mapOf("text" to DataValue.StringValue("changed")))
                val updated =
                    fixture.request(
                        "element.value.update.v2",
                        UpdateElementValuesRequest(
                            batchId = "update_route_element",
                            updates =
                                listOf(
                                    ElementValueUpdate(
                                        id = elementId,
                                        expectedRevision = 1,
                                        name = "Changed",
                                        mutations =
                                            listOf(
                                                ElementValueMutation.createSetValue(
                                                    path = DataPath(segments = emptyList()),
                                                    value = SkirDataValueCodec.encode(replacement).getOrThrow(),
                                                ),
                                            ),
                                    ),
                                ),
                        ),
                        UpdateElementValuesRequest.serializer,
                        UpdateElementValuesResponse.serializer,
                    )

                updated shouldBe
                    UpdateElementValuesResponse.createSuccess(
                        batchId = "update_route_element",
                        affectedPages = listOf(page.toSkirRecordId()),
                    )
                fixture.repositories.elements.getPageElements(page).single().let {
                    it.name shouldBe "Changed"
                    it.value.valueWithSlots shouldBe replacement
                }
            }
        }
    }
}
