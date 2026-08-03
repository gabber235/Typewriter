package com.typewritermc.services.libs.communicator.nats

import java.net.URI
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** Validated settings used to construct one NATS.kt client. */
data class NatsConnectionConfiguration(
    val serverUrl: String,
    val clientName: String? = null,
    val inboxPrefix: String = "_INBOX.",
    val connectTimeout: Duration = 5.seconds,
    /** Number of reconnect retries after the initial connection attempt; `null` retries indefinitely. */
    val maxReconnects: Int? = null,
    val reconnectDelay: Duration = 2.seconds,
    val shutdownTimeout: Duration = 30.seconds,
) {
    init {
        require(serverUrl.isNotBlank()) { "NATS server URL must not be blank" }
        val uri = runCatching { URI(serverUrl) }.getOrElse { throw IllegalArgumentException("Invalid NATS server URL", it) }
        require(uri.scheme in supportedSchemes && !uri.host.isNullOrBlank()) { "Invalid NATS server URL '$serverUrl'" }
        require(clientName == null || clientName.isNotBlank()) { "NATS client name must not be blank" }
        require(
            inboxPrefix.isNotBlank() && inboxPrefix.none(Char::isWhitespace),
        ) { "NATS inbox prefix must not be blank or contain whitespace" }
        connectTimeout.toPositiveMilliseconds("NATS connect timeout")
        reconnectDelay.toPositiveMilliseconds("NATS reconnect delay")
        require(shutdownTimeout.isFinite() && shutdownTimeout.isPositive()) { "NATS shutdown timeout must be positive and finite" }
        require(maxReconnects == null || maxReconnects >= 0) { "NATS maximum reconnects must not be negative" }
    }

    private companion object {
        val supportedSchemes = setOf("nats", "tls", "ws", "wss")
    }
}

internal val NatsConnectionConfiguration.normalizedConnectTimeout: Duration
    get() = connectTimeout.toPositiveMilliseconds("NATS connect timeout").milliseconds

internal val NatsConnectionConfiguration.normalizedReconnectDelay: Duration
    get() = reconnectDelay.toPositiveMilliseconds("NATS reconnect delay").milliseconds

internal val NatsConnectionConfiguration.natsMaxConnectionAttempts: Int?
    get() = maxReconnects?.let { if (it == Int.MAX_VALUE) Int.MAX_VALUE else it + 1 }

/** Supplies fresh connection settings for each connection attempt. */
fun interface NatsConfigurationProvider {
    suspend fun configuration(): NatsConnectionConfiguration
}
