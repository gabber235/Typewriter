package com.typewritermc.realm.routes

import com.typewritermc.authoring.id
import com.typewritermc.authoring.of
import com.typewritermc.realm.compiler.PublicationFixture
import com.typewritermc.realm.compiler.blocker
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.publication.QueryPublicationViewRequest
import skirout.editor.v1.publication.QueryPublicationViewResponse
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val PublicationRoutesTest by testSuite {
    test("review returns one identified view and obsolete queries return its current identity") {
        runTest {
            val publication = PublicationFixture()
            try {
                publication.publisher.refresh()
                val reviewed = publication.publisher.views.value
                RouteFixture { address, _ ->
                    communicatorRoutes { PublicationRoutes(publication.publisher, address).register(this) }
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
                    val current = publication.publisher.views.value
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
    test("publication blockers retain exact locations and captured evidence") {
        val resource =
            skirout.kernel.v1.resource_id
                .ResourceId(value = "page")
        val location =
            ValueLocation.of(
                resource,
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "name"),
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
            skirout.editor.v1.publication.DiagnosticEvidence(
                catalog =
                    skirout.editor.v1.type_catalog
                        .CatalogGeneration(value = "catalog"),
                expectations =
                    listOf(
                        skirout.editor.v1.authoring_facts.EditExpectation
                            .createValue(at = location, expected = skirout.editor.v1.type_catalog.DataValue.UNFILLED),
                    ),
            )
        val details = finding.blocker(captured).details
        details.primary!!
            .path.segments.size shouldBe 1
        details.evidence!!.catalog.value shouldBe "catalog"
        details.evidence!!.expectations.size shouldBe 1
        finding.blocker(evidence = null).details.evidence shouldBe null
    }
}
