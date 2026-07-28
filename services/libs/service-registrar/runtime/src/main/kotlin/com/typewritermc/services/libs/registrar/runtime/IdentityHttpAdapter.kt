package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.http.core.*
import com.typewritermc.services.libs.registrar.*
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import skirout.service.v1.identity.IssueServiceIdentityRequest
import skirout.service.v1.identity.IssueServiceIdentityResponse
import skirout.service.v1.service.ServiceRole as SkirRole
import java.net.URI

class TypewriterIdentityIssuer(private val client: ServiceHttpClient, private val uri: URI) : IdentityIssuer {
    override suspend fun issue(roles: List<ServiceRole>): IdentityIssueResult {
        val body = IssueServiceIdentityRequest.serializer.toBytes(
            IssueServiceIdentityRequest(roles = roles.map(ServiceRole::toSkir)),
        ).toByteArray()
        val result = client.execute(
            HttpRequest(
                HttpOperation("registrar.identity.issue"), ErrorSlug.of("identity-issue-failed"), HttpMethod.POST,
                uri, skirRequestHeaders, body, maximumRequestBytes = MAXIMUM_SKIR_BODY,
                maximumResponseBytes = MAXIMUM_SKIR_BODY,
            ),
        )
        if (result is HttpResult.Failure) {
            val error = result.error
            if (error is HttpError.RequestTooLarge || error is HttpError.Invalid) {
                return IdentityIssueResult.Failure(
                    IdentityIssueError.Protocol("invalid_request", false)
                )
            }
            return IdentityIssueResult.Failure(IdentityIssueError.Unavailable(true))
        }
        result as HttpResult.Success
        val status = result.response.statusCode
        val ambiguous = status == 200
        if (!result.response.headers.hasSkirMediaType()) {
            return IdentityIssueResult.Failure(IdentityIssueError.Protocol("unexpected_media_type", ambiguous))
        }
        val response = try {
            IssueServiceIdentityResponse.serializer.fromBytes(result.response.body)
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
            return IdentityIssueResult.Failure(IdentityIssueError.Protocol("malformed_response", ambiguous))
        }
        return mapIdentityResponse(status, response, roles)
    }
}

private fun mapIdentityResponse(
    status: Int,
    response: IssueServiceIdentityResponse,
    roles: List<ServiceRole>,
): IdentityIssueResult {
    val expectedStatuses = when (response.kind) {
        IssueServiceIdentityResponse.Kind.SUCCESS_WRAPPER -> setOf(200)
        IssueServiceIdentityResponse.Kind.MALFORMED_REQUEST_ERROR_WRAPPER -> setOf(400, 413, 415)
        IssueServiceIdentityResponse.Kind.UNKNOWN_ROLE_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.ROLES_REQUIRED_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.ROLE_UNKNOWN_PROPERTY_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.ROLE_TYPE_INVALID_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.ROLE_VERSION_BLANK_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.ROLE_INVALID_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.CUSTOM_ROLE_NAME_REQUIRED_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.CUSTOM_ROLE_NAME_INVALID_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.BUILTIN_ROLE_NAME_FORBIDDEN_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.ENGINE_ROLE_DUPLICATE_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.REALM_ROLE_DUPLICATE_ERROR_WRAPPER,
        IssueServiceIdentityResponse.Kind.CUSTOM_ROLE_DUPLICATE_ERROR_WRAPPER -> setOf(400)
        IssueServiceIdentityResponse.Kind.INTERNAL_ERROR_WRAPPER -> setOf(500)
        IssueServiceIdentityResponse.Kind.IDENTITY_PROVIDER_UNAVAILABLE_ERROR_WRAPPER -> setOf(503)
        IssueServiceIdentityResponse.Kind.UNKNOWN -> return IdentityIssueResult.Failure(
            IdentityIssueError.Protocol("unknown_variant", status == 200),
        )
    }
    if (status !in expectedStatuses) {
        return IdentityIssueResult.Failure(IdentityIssueError.Protocol("unexpected_status", status == 200))
    }
    if (response is IssueServiceIdentityResponse.SuccessWrapper) {
        return try {
            val value = response.value
            IdentityIssueResult.Success(
                IdentityCredentials(
                    ServiceIdentity(value.serviceId, value.displayName, value.username, roles),
                    RedactedSecret.AppPassword(value.token),
                ),
            )
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
            IdentityIssueResult.Failure(IdentityIssueError.Protocol("invalid_success", true))
        }
    }
    if (response is IssueServiceIdentityResponse.InternalErrorWrapper ||
        response is IssueServiceIdentityResponse.IdentityProviderUnavailableErrorWrapper
    ) return IdentityIssueResult.Failure(IdentityIssueError.Unavailable(false))
    return IdentityIssueResult.Failure(IdentityIssueError.Rejected(response.rejectionReason()))
}

private fun IssueServiceIdentityResponse.rejectionReason(): IdentityRejectionReason = when (kind) {
    IssueServiceIdentityResponse.Kind.MALFORMED_REQUEST_ERROR_WRAPPER -> IdentityRejectionReason.MALFORMED_REQUEST
    IssueServiceIdentityResponse.Kind.UNKNOWN_ROLE_ERROR_WRAPPER -> IdentityRejectionReason.UNKNOWN_ROLE
    IssueServiceIdentityResponse.Kind.ROLES_REQUIRED_ERROR_WRAPPER -> IdentityRejectionReason.ROLES_REQUIRED
    IssueServiceIdentityResponse.Kind.ROLE_UNKNOWN_PROPERTY_ERROR_WRAPPER -> IdentityRejectionReason.ROLE_UNKNOWN_PROPERTY
    IssueServiceIdentityResponse.Kind.ROLE_TYPE_INVALID_ERROR_WRAPPER -> IdentityRejectionReason.ROLE_TYPE_INVALID
    IssueServiceIdentityResponse.Kind.ROLE_VERSION_BLANK_ERROR_WRAPPER -> IdentityRejectionReason.ROLE_VERSION_BLANK
    IssueServiceIdentityResponse.Kind.ROLE_INVALID_ERROR_WRAPPER -> IdentityRejectionReason.ROLE_INVALID
    IssueServiceIdentityResponse.Kind.CUSTOM_ROLE_NAME_REQUIRED_ERROR_WRAPPER -> IdentityRejectionReason.CUSTOM_ROLE_NAME_REQUIRED
    IssueServiceIdentityResponse.Kind.CUSTOM_ROLE_NAME_INVALID_ERROR_WRAPPER -> IdentityRejectionReason.CUSTOM_ROLE_NAME_INVALID
    IssueServiceIdentityResponse.Kind.BUILTIN_ROLE_NAME_FORBIDDEN_ERROR_WRAPPER -> IdentityRejectionReason.BUILTIN_ROLE_NAME_FORBIDDEN
    IssueServiceIdentityResponse.Kind.ENGINE_ROLE_DUPLICATE_ERROR_WRAPPER -> IdentityRejectionReason.ENGINE_ROLE_DUPLICATE
    IssueServiceIdentityResponse.Kind.REALM_ROLE_DUPLICATE_ERROR_WRAPPER -> IdentityRejectionReason.REALM_ROLE_DUPLICATE
    IssueServiceIdentityResponse.Kind.CUSTOM_ROLE_DUPLICATE_ERROR_WRAPPER -> IdentityRejectionReason.CUSTOM_ROLE_DUPLICATE
    else -> error("Response is not an identity rejection: $kind")
}

private fun ServiceRole.toSkir(): SkirRole = when (this) {
    is ServiceRole.Engine -> SkirRole.EngineWrapper(SkirRole.Engine(version = version))
    is ServiceRole.Realm -> SkirRole.RealmWrapper(SkirRole.Realm(version = version))
    is ServiceRole.Custom -> SkirRole.CustomWrapper(SkirRole.Custom(name = name, version = version))
}
