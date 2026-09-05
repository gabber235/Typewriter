package com.typewritermc.realm.routes

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.library.v1.authoring.ApplyAuthoringBatchRequest
import skirout.library.v1.authoring.ApplyAuthoringBatchResponse
import skirout.library.v1.authoring.AuthoringChanged
import skirout.library.v1.authoring.AuthoringOperation
import skirout.library.v1.authoring.AuthoringSnapshotScope
import skirout.library.v1.authoring.AuthoringSnapshotSlice
import skirout.library.v1.authoring.Book
import skirout.library.v1.authoring.GetAuthoringSnapshotRequest
import skirout.library.v1.authoring.GetAuthoringSnapshotResponse
import skirout.library.v1.authoring.StringChange

val AuthoringRoutesTest by testSuite {
    test("applied batches publish the canonical response event") {
        runTest {
            RouteFixture().use { fixture ->
                val request = createBookRequest("published-batch")

                val response =
                    fixture.request(
                        "library.authoring.batch.apply",
                        request,
                        ApplyAuthoringBatchRequest.serializer,
                        ApplyAuthoringBatchResponse.serializer,
                    ) as ApplyAuthoringBatchResponse.AppliedWrapper

                fixture.publishedTo("library.authoring.changed", AuthoringChanged.serializer) shouldContainExactly
                    listOf(response.value)
            }
        }
    }

    test("idempotent replays may republish the same canonical event") {
        runTest {
            RouteFixture().use { fixture ->
                val request = createBookRequest("replayed-batch")

                repeat(2) {
                    fixture
                        .request(
                            "library.authoring.batch.apply",
                            request,
                            ApplyAuthoringBatchRequest.serializer,
                            ApplyAuthoringBatchResponse.serializer,
                        ).shouldBeInstanceOf<ApplyAuthoringBatchResponse.AppliedWrapper>()
                }

                val events = fixture.publishedTo("library.authoring.changed", AuthoringChanged.serializer)
                events.size shouldBe 2
                events[1] shouldBe events[0]
            }
        }
    }

    test("conflicts return property details without publishing") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.request(
                    "library.authoring.batch.apply",
                    createBookRequest("conflict-create"),
                    ApplyAuthoringBatchRequest.serializer,
                    ApplyAuthoringBatchResponse.serializer,
                )
                val publicationsBefore = fixture.publishedTo("library.authoring.changed").size

                val response =
                    fixture.request(
                        "library.authoring.batch.apply",
                        ApplyAuthoringBatchRequest(
                            batchId = "conflict-patch",
                            operations =
                                listOf(
                                    AuthoringOperation.createPatchBook(
                                        id = recordId("book", "route-book"),
                                        title = StringChange(expected = "stale", value = "changed"),
                                        icon = null,
                                        color = null,
                                        tags = null,
                                    ),
                                ),
                        ),
                        ApplyAuthoringBatchRequest.serializer,
                        ApplyAuthoringBatchResponse.serializer,
                    ) as ApplyAuthoringBatchResponse.ConflictWrapper

                response.value.conflicts.size shouldBe 1
                fixture.publishedTo("library.authoring.changed").size shouldBe publicationsBefore
            }
        }
    }

    test("snapshots expose canonical data and its sequence") {
        runTest {
            RouteFixture().use { fixture ->
                val applied =
                    fixture.request(
                        "library.authoring.batch.apply",
                        createBookRequest("snapshot-create"),
                        ApplyAuthoringBatchRequest.serializer,
                        ApplyAuthoringBatchResponse.serializer,
                    ) as ApplyAuthoringBatchResponse.AppliedWrapper

                val response =
                    fixture.request(
                        "library.authoring.snapshot.get",
                        GetAuthoringSnapshotRequest(scopes = listOf(AuthoringSnapshotScope.LIBRARY)),
                        GetAuthoringSnapshotRequest.serializer,
                        GetAuthoringSnapshotResponse.serializer,
                    ) as GetAuthoringSnapshotResponse.SuccessWrapper

                response.value.sequence shouldBe applied.value.sequence
                val library = response.value.slices.single() as AuthoringSnapshotSlice.LibraryWrapper
                library.value.books
                    .single()
                    .title shouldBe "route_book"
            }
        }
    }

    test("invalid persisted names return typed diagnostics") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    ApplyAuthoringBatchRequest(
                        batchId = "invalid-name",
                        operations =
                            listOf(
                                AuthoringOperation.createCreateBook(
                                    book =
                                        Book(
                                            id = recordId("book", "invalid-name"),
                                            title = "Invalid name",
                                            icon = "mdi:book",
                                            color = Color(argb = 0),
                                            tags = emptyList(),
                                        ),
                                ),
                            ),
                    )

                val response =
                    fixture.request(
                        "library.authoring.batch.apply",
                        invalid,
                        ApplyAuthoringBatchRequest.serializer,
                        ApplyAuthoringBatchResponse.serializer,
                    ) as ApplyAuthoringBatchResponse.InvalidWrapper

                response.value.diagnostics
                    .single()
                    .code shouldBe "invalid-request"
                fixture.publishedTo("library.authoring.changed") shouldBe emptyList()
            }
        }
    }
}

private fun createBookRequest(batchId: String) =
    ApplyAuthoringBatchRequest(
        batchId = batchId,
        operations =
            listOf(
                AuthoringOperation.createCreateBook(
                    book =
                        Book(
                            id = recordId("book", "route-book"),
                            title = "route_book",
                            icon = "mdi:book",
                            color = Color(argb = 0),
                            tags = emptyList(),
                        ),
                ),
            ),
    )

private fun recordId(
    table: String,
    key: String,
) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))
