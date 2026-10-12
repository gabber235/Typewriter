package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.PublicationFixture
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.publication.PublicationView
import skirout.editor.v1.publication.QueryPublicationViewRequest
import skirout.editor.v1.publication.QueryPublicationViewResponse

val PublicationRoutesTest by testSuite {
    test("bounded review returns one identified snapshot and obsolete queries return its current identity") {
        runTest {
            val publication = PublicationFixture()
            try {
                publication.publisher.refresh()
                val reviewed =
                    publication.publisher.views.value
                        .toWire()
                RouteFixture { contracts, address, _ ->
                    communicatorRoutes { PublicationRoutes(publication.publisher, contracts, address).register(this) }
                }.use { routes ->
                    val response =
                        routes
                            .request(
                                "editor.authoring.publication.query",
                                QueryPublicationViewRequest(expected = reviewed.id, transferId = "review_transfer"),
                                QueryPublicationViewRequest.serializer,
                                QueryPublicationViewResponse.serializer,
                            ).shouldBeInstanceOf<QueryPublicationViewResponse.ChunkWrapper>()
                            .value
                    response.view shouldBe reviewed.id
                    response.transfer.transferId shouldBe "review_transfer"
                    response.transfer.chunkCount shouldBe 1
                    PublicationView.serializer.fromBytes(response.transfer.payload) shouldBe reviewed
                    publication.update("Later saved content")
                    publication.publisher.refresh()
                    val current =
                        publication.publisher.views.value
                            .toWire()
                    routes
                        .request(
                            "editor.authoring.publication.query",
                            QueryPublicationViewRequest(expected = reviewed.id, transferId = "obsolete_transfer"),
                            QueryPublicationViewRequest.serializer,
                            QueryPublicationViewResponse.serializer,
                        ).shouldBeInstanceOf<QueryPublicationViewResponse.ChangedWrapper>()
                        .value.current shouldBe current.id
                    publication.attempts.started shouldBe 0
                    publication.blobRequests shouldBe 0
                }
            } finally {
                publication.close()
            }
        }
    }
}
