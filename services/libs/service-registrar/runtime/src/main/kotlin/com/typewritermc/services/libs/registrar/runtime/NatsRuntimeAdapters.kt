package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsAuthenticationChallenge
import com.typewritermc.services.libs.communicator.nats.NatsAuthenticationProvider
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import skirout.access.v1.permission.EntityPermissionQualifier
import java.util.Base64

internal class MissingNatsNonceException : IllegalStateException("NATS server nonce is required")

internal fun serviceNatsConfiguration(
    configuration: RegistrarConfiguration,
    credentials: IdentityCredentials,
) = NatsConnectionConfiguration(
    serverUrl = configuration.natsServerUri.toString(),
    clientName = credentials.identity.serviceId,
    inboxPrefix = "_INBOX.${credentials.identity.serviceId}.",
    shutdownTimeout = configuration.shutdownTimeout,
)

internal fun serviceNatsAuthenticationProvider(
    accessTokens: AccessTokenCache,
    sentinel: SentinelCache,
    credentials: IdentityCredentials,
): NatsAuthenticationProvider =
    NatsAuthenticationProvider { challenge ->
        val access = accessTokens.get()
        if (access is AccessTokenResult.Failure) throw RegistrarAuthenticationException(access.failure)
        access as AccessTokenResult.Success
        val sentinelResult = sentinel.get()
        if (sentinelResult is SentinelResult.Failure) throw RegistrarAuthenticationException(sentinelResult.failure)
        sentinelResult as SentinelResult.Success
        try {
            authenticateService(challenge, access.token, sentinelResult.credentials)
        } catch (_: MissingNatsNonceException) {
            throw RegistrarAuthenticationException(
                com.typewritermc.services.libs.registrar.RegistrarFailure.Messaging(
                    com.typewritermc.services.libs.registrar.MessagingOperation.CONNECT,
                    recoverable = false,
                ),
            )
        }
    }

internal suspend fun authenticateService(
    challenge: NatsAuthenticationChallenge,
    accessToken: com.typewritermc.services.libs.registrar.RedactedSecret.AccessToken,
    sentinel: SentinelCredentials,
): NatsAuthentication =
    createServiceAuthentication(
        challenge.hasNonce,
        { challenge.signNonce(it) },
        accessToken,
        sentinel,
    )

internal suspend fun createServiceAuthentication(
    hasNonce: Boolean,
    signer: suspend (String) -> String?,
    accessToken: com.typewritermc.services.libs.registrar.RedactedSecret.AccessToken,
    sentinel: SentinelCredentials,
): NatsAuthentication {
    if (!hasNonce) throw MissingNatsNonceException()
    val signature = signer(sentinel.seed.reveal()) ?: throw MissingNatsNonceException()
    return NatsAuthentication(
        username = null,
        password = accessToken.reveal(),
        jwt = sentinel.jwt.reveal(),
        signature = signature,
        nkey = encodedServiceQualifier(),
    )
}

internal fun encodedServiceQualifier(): String {
    val qualifier = EntityPermissionQualifier.createService()
    val bytes = EntityPermissionQualifier.serializer.toBytes(qualifier).toByteArray()
    return Base64.getEncoder().encodeToString(bytes)
}
