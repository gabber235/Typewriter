package com.typewritermc.services.integration.messaging

import com.typewritermc.services.integration.GeneratedIntegrationContract
import com.typewritermc.services.integration.IntegrationContext
import com.typewritermc.services.integration.IntegrationRegistration
import com.typewritermc.services.integration.IntegrationResult
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

fun interface IntegrationAuthenticator {
    suspend fun authenticate(context: IntegrationContext): IntegrationRegistration?
}

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
