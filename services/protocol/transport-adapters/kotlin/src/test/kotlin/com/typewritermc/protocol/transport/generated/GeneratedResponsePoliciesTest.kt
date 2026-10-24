package com.typewritermc.protocol.transport.generated

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.telemetry.ErrorSlug
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.AuthoringState
import skirout.editor.v1.authoring.CatalogChanged
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.kernel.v1.errors.InternalError
import skirout.service.v1.artifact.PublishSharedArtifactResponse

private val scope = RealmRouteScope(organizationId = "writers", realmId = "quests")

val GeneratedResponsePoliciesTest by testSuite {
    test("variant names classify the responses of a generated route") {
        val policy = scope.authoringStateQuery.responsePolicy

        policy.classify(QueryAuthoringStateResponse.StateWrapper(AuthoringState.partial())) shouldBe
            ResponseClassification.success("state")
        policy.classify(QueryAuthoringStateResponse.CatalogChangedErrorWrapper(CatalogChanged.partial())) shouldBe
            ResponseClassification.domainError("catalog-changed-error")
        policy.classify(QueryAuthoringStateResponse.UNKNOWN) shouldBe ResponseClassification.internalError("unknown")
    }

    test("the internal_error wrapper is the fallback reply") {
        val policy = scope.authoringStateQuery.responsePolicy

        policy.internalFailureResponse shouldBe QueryAuthoringStateResponse.InternalErrorWrapper(InternalError.partial())
        policy.classify(policy.internalFailureResponse) shouldBe ResponseClassification.internalError("internal-error")
    }

    test("artifact conflicts are domain errors rather than successes") {
        val conflict = PublishSharedArtifactResponse.ConflictErrorWrapper(null)

        scope.sharedPublish.responsePolicy
            .classify(conflict)
            .outcome shouldBe ResponseOutcome.DOMAIN_ERROR
    }

    test("route failures use the slug derived from the operation name") {
        scope.authoringStateQuery.failureSlug shouldBe ErrorSlug.of("editor-authoring-state-query-failed")
        scope.editorCatalogWatch.failureSlug shouldBe ErrorSlug.of("editor-catalog-invalidate-failed")
        scope.authoringChanged.failureSlug shouldBe ErrorSlug.of("editor-authoring-changed-failed")
    }
}
