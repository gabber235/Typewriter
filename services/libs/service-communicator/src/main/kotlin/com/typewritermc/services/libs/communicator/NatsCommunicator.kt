package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.telemetry.withSuspendSpan
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.natskt.NatsClient
import io.natskt.api.AuthPayload
import io.natskt.api.Credentials
import io.natskt.api.NatsClient
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Manages NATS connection with JWT-based authentication.
 *
 * Uses constructor injection for all dependencies. The jwtProvider
 * is a DeferredProvider that allows late binding of values that become
 * available after initialization. The natsClientProvider is a StateProvider
 * that can be updated on reconnection.
 */
class NatsCommunicator(
    private val natsUrl: String,
    private val jwtProvider: DeferredProvider<JwtProvider>,
    private val sentinelCredentialsFetcher: SentinelCredentialsFetcher,
    private val json: Json,
    private val natsClientProvider: StateProvider<NatsClient?>,
    private val tracer: Tracer
) : Reconnector {
    private val logger: KLogger = logger {}

    private var _client: NatsClient? = null

    /**
     * Establish connection to NATS server.
     *
     * Uses JWT token from JwtProvider for authentication.
     * The token is embedded in the connection URL.
     */
    suspend fun connect() {
        tracer.withSuspendSpan(
            name = "nats.connect",
            kind = SpanKind.CLIENT
        ) { span ->
            span.addEvent("connecting")
            span.setAttribute("messaging.system", "nats")
            span.setAttribute("server.address", natsUrl)

            val jwt = jwtProvider.get()
            val tokenInfo = jwt.getTokenInfo()
            val token = tokenInfo.accessToken
            val serviceId = extractServiceId(token)
            val sentinelCredentials = sentinelCredentialsFetcher.fetchCredentials()

            val natsClient = NatsClient {
                server = natsUrl
                inboxPrefix = "_INBOX.$serviceId."
                authentication = Credentials.Custom(
                    provider = { info ->
                        AuthPayload(
                            jwt = sentinelCredentials.jwt,
                            signature = signNonce(sentinelCredentials.seed, info),
                            username = serviceId,
                            password = token
                        )
                    }
                )
            }

            val result = natsClient.connect()
            result.onFailure {
                span.recordException(it)
                span.setStatus(StatusCode.ERROR, "Failed to connect to NATS: ${it.message}")
                throw it
            }

            natsClientProvider.set(natsClient)

            this._client = natsClient
            span.addEvent("connected")
        }
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
        val jsonString = String(decodedPayload, Charsets.UTF_8)

        val jwtPayload = json.decodeFromString<JwtPayload>(jsonString)
        return jwtPayload.sub
            ?: throw IllegalArgumentException("JWT token missing 'sub' claim")
    }

    /**
     * Reconnect with a fresh JWT token.
     * Use this when the token has expired or connection was lost.
     */
    override suspend fun reconnect() {
        logger.info { "Reconnecting to NATS with fresh JWT" }
        disconnect()
        connect()
    }

    /**
     * Disconnect from NATS server.
     */
    suspend fun disconnect() = tracer.withSuspendSpan(
        name = "nats.disconnect",
        kind = SpanKind.CLIENT
    ) { span ->
        span.addEvent("disconnecting")
        _client?.disconnect()
        _client = null
        natsClientProvider.set(null)
        span.addEvent("disconnected")
    }
}

@Serializable
private data class JwtPayload(
    val sub: String? = null,
)
