package com.typewritermc.services.integration.messaging

import com.typewritermc.services.integration.IntegrationContext
import com.typewritermc.services.integration.IntegrationGateway
import com.typewritermc.services.integration.IntegrationOperationId
import com.typewritermc.services.integration.IntegrationOperationKind
import com.typewritermc.services.integration.IntegrationResult
import kotlinx.coroutines.flow.Flow

/**
 * Carries one authenticated integration operation across a messaging boundary.
 *
 * The sender owns [payload] and must not mutate it while a custom channel handles the message.
 */
data class AuthenticatedIntegrationMessage(
    val context: IntegrationContext,
    val kind: IntegrationOperationKind,
    val operationId: IntegrationOperationId,
    val payload: ByteArray,
) {
    override fun equals(other: Any?): Boolean =
        other is AuthenticatedIntegrationMessage &&
            context == other.context &&
            kind == other.kind &&
            operationId == other.operationId &&
            payload.contentEquals(other.payload)

    override fun hashCode(): Int =
        31 * (31 * (31 * context.hashCode() + kind.hashCode()) + operationId.hashCode()) + payload.contentHashCode()
}

/** Sends authenticated request, publication, and event messages through an application messaging adapter. */
interface IntegrationMessageChannel {
    suspend fun request(message: AuthenticatedIntegrationMessage): IntegrationResult<ByteArray>

    suspend fun publish(message: AuthenticatedIntegrationMessage): IntegrationResult<Unit>

    fun events(message: AuthenticatedIntegrationMessage): Flow<IntegrationResult<ByteArray>>
}

/**
 * Adapts an [IntegrationMessageChannel] to the transport independent integration gateway.
 *
 * Request and publication payloads are copied before ownership crosses the channel boundary. Events use an empty payload
 * and preserve the channel flow lifecycle.
 */
class MessagingIntegrationGateway(
    private val channel: IntegrationMessageChannel,
) : IntegrationGateway {
    override suspend fun request(
        context: IntegrationContext,
        kind: IntegrationOperationKind,
        operationId: IntegrationOperationId,
        payload: ByteArray,
    ): IntegrationResult<ByteArray> = channel.request(AuthenticatedIntegrationMessage(context, kind, operationId, payload.copyOf()))

    override suspend fun publish(
        context: IntegrationContext,
        eventId: IntegrationOperationId,
        payload: ByteArray,
    ): IntegrationResult<Unit> =
        channel.publish(
            AuthenticatedIntegrationMessage(context, IntegrationOperationKind.EVENT, eventId, payload.copyOf()),
        )

    override fun events(
        context: IntegrationContext,
        eventId: IntegrationOperationId,
    ): Flow<IntegrationResult<ByteArray>> =
        channel.events(
            AuthenticatedIntegrationMessage(context, IntegrationOperationKind.EVENT, eventId, byteArrayOf()),
        )
}
