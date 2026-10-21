package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.PublicationFixture
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.publication.QueryPublicationViewRequest
import skirout.editor.v1.publication.QueryPublicationViewResponse

val PublicationRoutesTest by testSuite {
    test("review returns one identified view and obsolete queries return its current identity") {
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
                    routes
                        .request(
                            "editor.authoring.publication.query",
                            QueryPublicationViewRequest(expected = reviewed.id),
                            QueryPublicationViewRequest.serializer,
                            QueryPublicationViewResponse.serializer,
                        ).shouldBeInstanceOf<QueryPublicationViewResponse.ViewWrapper>()
                        .value shouldBe reviewed
                    publication.update("Later saved content")
                    publication.publisher.refresh()
                    val current =
                        publication.publisher.views.value
                            .toWire()
                    routes
                        .request(
                            "editor.authoring.publication.query",
                            QueryPublicationViewRequest(expected = reviewed.id),
                            QueryPublicationViewRequest.serializer,
                            QueryPublicationViewResponse.serializer,
                        ).shouldBeInstanceOf<QueryPublicationViewResponse.ViewChangedErrorWrapper>()
                        .value.current shouldBe current.id
                    publication.attempts.started shouldBe 0
                    publication.blobRequests shouldBe 0
                }
            } finally {
                publication.close()
            }
        }
    }
    test("publication findings retain exact locations and captured evidence on the wire") {
        val resource = com.typewritermc.types.ResourceId("page")
        val location =
            com.typewritermc.authoring.ValueLocation(
                resource,
                com.typewritermc.authoring.ValuePath(
                    listOf(
                        com.typewritermc.authoring.PathSegment
                            .Field("name"),
                    ),
                ),
            )
        val finding =
            com.typewritermc.realm.compiler.compilationDiagnostic(
                "unfinished_value",
                "A required value is unfinished.",
                location = location,
            )
        val captured =
            com.typewritermc.realm.compiler.DiagnosticEvidence(
                com.typewritermc.checking.CatalogGeneration("catalog"),
                listOf(
                    com.typewritermc.authoring.EditExpectation
                        .Value(location, com.typewritermc.types.DataValue.Unfilled),
                ),
            )
        val status =
            com.typewritermc.realm.compiler.PublicationStatus.Blocked(
                com.typewritermc.realm.compiler.PublicationBaseline.Initial,
                com.typewritermc.realm.compiler.PublicationBlockers
                    .from(listOf(finding)),
                emptyList(),
                emptyList(),
                emptyList(),
            )
        val review =
            com.typewritermc.realm.compiler.PublicationView(
                com.typewritermc.realm.compiler
                    .PublicationViewId("review"),
                status,
                mapOf(finding.id to captured),
            )
        val details =
            review
                .toWire()
                .status
                .shouldBeInstanceOf<skirout.editor.v1.publication.PublicationStatus.BlockedWrapper>()
                .value.blockers.first.details
        details.primary!!
            .path.segments.size shouldBe 1
        details.evidence!!.catalog.value shouldBe "catalog"
        details.evidence!!.expectations.size shouldBe 1
        val noEvidence =
            review
                .copy(
                    evidence = emptyMap(),
                ).toWire()
                .status
                .shouldBeInstanceOf<skirout.editor.v1.publication.PublicationStatus.BlockedWrapper>()
                .value.blockers.first.details
        noEvidence.evidence shouldBe null
    }
}
