package com.typewritermc.services.libs.communicator

import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.natskt.NatsClient
import io.natskt.api.Credentials
import io.natskt.api.NatsClient
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.context.loadKoinModules
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.override

/**
 * Manages NATS connection with JWT-based authentication.
 *
 * Uses the JwtProvider factory pattern to obtain fresh JWT tokens
 * for authentication. The JwtProvider implementation is registered
 * late by service-registrar after credentials are initialized.
 */
class NatsCommunicator : KoinComponent {
    private val logger: KLogger = logger {}

    private val natsUrl: String by inject(named("nats-url"))
    private val jwtProvider: JwtProvider by inject()
    private val sentinelCredentialsFetcher: SentinelCredentialsFetcher by inject()

    private var _client: NatsClient? = null

    /**
     * Establish connection to NATS server.
     *
     * Uses JWT token from JwtProvider for authentication.
     * The token is embedded in the connection URL.
     */
    suspend fun connect() {
        logger.info { "Connecting to NATS at $natsUrl" }

        val tokenInfo = jwtProvider.getTokenInfo()
        val token = tokenInfo.accessToken
        val serviceId = extractServiceId(token)
        val sentinelCredentials = sentinelCredentialsFetcher.fetchCredentials()

        val natsClient = NatsClient {
            server = natsUrl
            inboxPrefix = "_INBOX.$serviceId."
            authentication = Credentials.Custom(
                jwt = Credentials.Jwt(
                    token = sentinelCredentials.jwt,
                    nkey = sentinelCredentials.seed
                ),
                password = Credentials.Password(
                    username = serviceId,
                    password = token
                )
            )
        }

        natsClient.connect()

        val natsModule = module {
            factory { natsClient }.override()
        }
        loadKoinModules(natsModule)

        this._client = natsClient
        logger.info { "Connected to NATS successfully" }
    }

    /**
     * Extract the service ID from the JWT token.
     *
     * The service ID is stored in the 'sub' (subject) claim of the JWT.
     */
    private fun extractServiceId(token: String): String {
        val parts = token.split(".")
        if (parts.size != 3) {
            throw IllegalArgumentException("Invalid JWT token format")
        }

        val payload = parts[1]
        val decodedPayload = java.util.Base64.getUrlDecoder().decode(payload)
        val json = String(decodedPayload, Charsets.UTF_8)

        val jwtPayload = Json.decodeFromString<JwtPayload>(json)
        return jwtPayload.sub
            ?: throw IllegalArgumentException("JWT token missing 'sub' claim")
    }

    /**
     * Reconnect with a fresh JWT token.
     * Use this when the token has expired or connection was lost.
     */
    suspend fun reconnect() {
        logger.info { "Reconnecting to NATS with fresh JWT" }
        disconnect()
        connect()
    }

    /**
     * Get the active NATS client.
     *
     * @throws IllegalStateException if not connected
     */
    val client: NatsClient
        get() = _client ?: throw IllegalStateException("NATS not connected. Call connect() first.")

    /**
     * Disconnect from NATS server.
     */
    suspend fun disconnect() {
        logger.info { "Disconnecting from NATS" }
        _client?.disconnect()
        _client = null
        logger.info { "Disconnected from NATS" }
    }
}

@Serializable
private data class JwtPayload(
    val sub: String? = null,
)
