package com.typewritermc.services.libs.communicator.skir

import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.telemetry.ErrorSlug
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.kernel.v1.color.Color
import skirout.service.v1.status.QueryServiceBindingResponse

val SkirAdaptersTest by testSuite {
    val statusAddress =
        "service.status".addressTemplate(
            render = { addressValuesOf() },
            parse = { Unit },
        )

    val statusPolicy =
        ResponsePolicy<QueryServiceBindingResponse>(
            internalFailureResponse = QueryServiceBindingResponse.createInternalError(),
            classifier = { response ->
                when (response.kind) {
                    QueryServiceBindingResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
                        ResponseClassification(
                            ResponseOutcome.INTERNAL_ERROR,
                            ResponseVariant.of("internal-error"),
                        )
                    }

                    QueryServiceBindingResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
                        ResponseClassification(
                            ResponseOutcome.DOMAIN_ERROR,
                            ResponseVariant.of("service-not-found"),
                        )
                    }

                    QueryServiceBindingResponse.Kind.BINDING_WRAPPER -> {
                        ResponseClassification(
                            ResponseOutcome.SUCCESS,
                            ResponseVariant.of("status"),
                        )
                    }

                    QueryServiceBindingResponse.Kind.UNKNOWN -> {
                        ResponseClassification(
                            ResponseOutcome.DOMAIN_ERROR,
                            ResponseVariant.of("unknown"),
                        )
                    }
                }
            },
        )

    test("payload codec rejects malformed binary input") {
        shouldThrow<IllegalArgumentException> {
            Color.serializer.asPayloadCodec().decode(Payload.copyOf(byteArrayOf(1, 2, 3)))
        }
    }

    test("operation names derive the failure slug the generator writes") {
        OperationName.of("editor.authoring.state.query").failureSlug shouldBe
            ErrorSlug.of("editor-authoring-state-query-failed")
        OperationName.of("organization.members.join_codes.watch").failureSlug shouldBe
            ErrorSlug.of("organization-members-join-codes-watch-failed")
    }
}
