package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.createTag
import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.WatchTagRequest
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTagsRequest
import skirout.library.v1.tag.WatchTagsResponse

val TagRoutesTest by testSuite {
    test("tag read watches return persisted resources") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "test_tag",
                            Color(argb = 0),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 2, height = 1),
                        ).successValue()

                val tags =
                    fixture.request(
                        "tag.watch",
                        WatchTagsRequest(),
                        WatchTagsRequest.serializer,
                        WatchTagsResponse.serializer,
                    )
                val resource =
                    fixture.request(
                        "tag.resource.watch",
                        WatchTagRequest(tagId = tag.tagId),
                        WatchTagRequest.serializer,
                        WatchTagResponse.serializer,
                    )

                tags shouldBe WatchTagsResponse.ListWrapper(listOf(tag))
                resource shouldBe WatchTagResponse.InitialWrapper(tag)
            }
        }
    }

    test("tag resource watch rejects wrong tables and missing records") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "tag.resource.watch",
                        WatchTagRequest(tagId = recordId("book", "wrong")),
                        WatchTagRequest.serializer,
                        WatchTagResponse.serializer,
                    )
                val missingId = recordId("tag", "missing")
                val missing =
                    fixture.request(
                        "tag.resource.watch",
                        WatchTagRequest(tagId = missingId),
                        WatchTagRequest.serializer,
                        WatchTagResponse.serializer,
                    )

                invalid.kind shouldBe WatchTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing shouldBe WatchTagResponse.createTagNotFoundError(tagId = missingId)
            }
        }
    }
}
