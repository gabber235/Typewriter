package com.typewritermc.services.integration.messaging

import com.typewritermc.services.integration.GeneratedIntegrationContract
import com.typewritermc.services.integration.IntegrationContext
import com.typewritermc.services.integration.IntegrationRegistration
import com.typewritermc.services.integration.IntegrationResult
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/** Resolves a credential context to its authoritative current registration. */
fun interface IntegrationAuthenticator {
    suspend fun authenticate(context: IntegrationContext): IntegrationRegistration?
}

/** Dispatches only messages already authenticated and authorized by the surrounding handler. */
interface IntegrationDispatcher {
    suspend fun request(
        registration: IntegrationRegistration,
        message: AuthenticatedIntegrationMessage,
    ): IntegrationResult<ByteArray>

    suspend fun publish(
        registration: IntegrationRegistration,
        message: AuthenticatedIntegrationMessage,
    ): IntegrationResult<Unit>

    fun events(
        registration: IntegrationRegistration,
        message: AuthenticatedIntegrationMessage,
    ): Flow<IntegrationResult<ByteArray>>
}

/**
 * Enforces generated contract permissions before integration messages reach application dispatch.
 *
 * Authentication must return the same integration and Realm identities carried by the message. Unknown operations and
 * insufficient permissions produce typed failures for requests, publications, and event subscriptions alike.
 */
class AuthenticatedIntegrationMessageHandler(
    private val contract: GeneratedIntegrationContract,
    private val authenticator: IntegrationAuthenticator,
    private val dispatcher: IntegrationDispatcher,
) : IntegrationMessageChannel {
    override suspend fun request(message: AuthenticatedIntegrationMessage): IntegrationResult<ByteArray> =
        when (val authorization = authorize(message)) {
            is Authorization.Granted -> dispatcher.request(authorization.registration, message)
            is Authorization.Denied -> authorization.result
        }

    override suspend fun publish(message: AuthenticatedIntegrationMessage): IntegrationResult<Unit> =
        when (val authorization = authorize(message)) {
            is Authorization.Granted -> dispatcher.publish(authorization.registration, message)
            is Authorization.Denied -> authorization.result
        }

    override fun events(message: AuthenticatedIntegrationMessage): Flow<IntegrationResult<ByteArray>> =
        flow {
            when (val authorization = authorize(message)) {
                is Authorization.Granted -> dispatcher.events(authorization.registration, message).collect(::emit)
                is Authorization.Denied -> emit(authorization.result)
            }
        }

    private suspend fun authorize(message: AuthenticatedIntegrationMessage): Authorization {
        val registration =
            authenticator.authenticate(message.context)
                ?: return Authorization.Denied(IntegrationResult.AuthenticationFailed)
        if (registration.id != message.context.integrationId || registration.realmId != message.context.realmId) {
            return Authorization.Denied(IntegrationResult.AuthenticationFailed)
        }
        val permission =
            contract.requiredPermission(message.kind, message.operationId)
                ?: return Authorization.Denied(IntegrationResult.UnknownOperation(message.kind, message.operationId))
        if (permission !in registration.permissions) {
            return Authorization.Denied(IntegrationResult.PermissionDenied(permission))
        }
        return Authorization.Granted(registration)
    }
}

private sealed interface Authorization {
    data class Granted(
        val registration: IntegrationRegistration,
    ) : Authorization

    data class Denied(
        val result: IntegrationResult<Nothing>,
    ) : Authorization
}
