package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsAuthenticationChallenge
import com.typewritermc.services.libs.communicator.nats.NatsAuthenticationProvider
import com.typewritermc.services.libs.communicator.nats.NatsConfigurationProvider
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration

/** Current registrar-owned Sentinel signing credentials. */
data class SentinelCredentials(val jwt: String, val nkeySeed: String) {
    init {
        require(jwt.isNotBlank()) { "Sentinel JWT must not be blank" }
        require(nkeySeed.isNotBlank()) { "Sentinel NKey seed must not be blank" }
    }
}

/** Supplies fresh Sentinel credentials for a NATS handshake. */
fun interface SentinelCredentialsProvider {
    suspend fun credentials(): SentinelCredentials
}

/** Supplies the current service access token. */
fun interface ServiceAccessTokenProvider {
    suspend fun accessToken(): String
}

/** Builds registrar-specific NATS settings from the current service identity. */
class RegistrarNatsConfigurationProvider(
    private val natsUrl: String,
    private val credentialProvider: suspend () -> Credential,
) : NatsConfigurationProvider {
    override suspend fun configuration(): NatsConnectionConfiguration {
        val serviceId = credentialProvider().id
        return NatsConnectionConfiguration(
            serverUrl = natsUrl,
            clientName = serviceId,
            inboxPrefix = "_INBOX.$serviceId.",
        )
    }
}

/** Authenticates NATS with registrar-owned service and Sentinel credentials. */
class RegistrarNatsAuthenticationProvider(
    private val credentialProvider: suspend () -> Credential,
    private val accessTokenProvider: ServiceAccessTokenProvider,
    private val sentinelCredentialsProvider: SentinelCredentialsProvider,
) : NatsAuthenticationProvider {
    override suspend fun authenticate(challenge: NatsAuthenticationChallenge): NatsAuthentication {
        val serviceId = credentialProvider().id
        val accessToken = accessTokenProvider.accessToken()
        val sentinel = sentinelCredentialsProvider.credentials()
        require(accessToken.isNotBlank()) { "Service access token must not be blank" }
        return NatsAuthentication(
            username = serviceId,
            password = accessToken,
            jwt = sentinel.jwt,
            signature = challenge.signNonce(sentinel.nkeySeed),
        )
    }
}
