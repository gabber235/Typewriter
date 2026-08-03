package com.typewritermc.services.libs.communicator.skir

import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.telemetry.ErrorSlug
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.kernel.v1.color.Color
import skirout.service.v1.status.GetServiceStatus
import skirout.service.v1.status.GetServiceStatusRequest
import skirout.service.v1.status.GetServiceStatusResponse

private data object StatusEndpoint

private val statusAddress =
    addressTemplate(
        pattern = "service.status",
        render = { addressValuesOf() },
        parse = { StatusEndpoint },
    )

private val statusPolicy =
    ResponsePolicy<GetServiceStatusResponse>(
        internalFailureResponse = GetServiceStatusResponse.createInternalError(),
        classifier = { response ->
            when (response.kind) {
                GetServiceStatusResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
                    ResponseClassification(
                        ResponseOutcome.INTERNAL_ERROR,
                        ResponseVariant.of("internal-error"),
                    )
                }

                GetServiceStatusResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
                    ResponseClassification(
                        ResponseOutcome.DOMAIN_ERROR,
                        ResponseVariant.of("service-not-found"),
                    )
                }

                GetServiceStatusResponse.Kind.STATUS_WRAPPER -> {
                    ResponseClassification(
                        ResponseOutcome.SUCCESS,
                        ResponseVariant.of("status"),
                    )
                }

                GetServiceStatusResponse.Kind.UNKNOWN -> {
                    ResponseClassification(
                        ResponseOutcome.DOMAIN_ERROR,
                        ResponseVariant.of("unknown"),
                    )
                }
            }
        },
    )

val SkirAdaptersTest by testSuite {
    test("payload codec round trips generated values") {
        val codec = Color.serializer.asPayloadCodec()
        codec.decode(codec.encode(Color(argb = 0x12345678))) shouldBe Color(argb = 0x12345678)
    }

    test("payload codec rejects malformed binary input") {
        shouldThrow<IllegalArgumentException> {
            Color.serializer.asPayloadCodec().decode(byteArrayOf(1, 2, 3))
        }
    }

    test("method helper preserves explicit operation and serializers") {
        val contract =
            skirUnaryContract(
                method = GetServiceStatus,
                name = OperationName.of("service-status"),
                address = statusAddress,
                responsePolicy = statusPolicy,
                failureSlug = ErrorSlug.of("service-status-failed"),
            )
        val request = GetServiceStatusRequest()
        contract.name shouldBe OperationName.of("service-status")
        contract.requestCodec.decode(contract.requestCodec.encode(request)) shouldBe request
        contract.responsePolicy shouldBe statusPolicy
    }
}
