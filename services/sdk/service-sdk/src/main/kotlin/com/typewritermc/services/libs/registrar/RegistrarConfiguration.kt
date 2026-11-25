package com.typewritermc.services.libs.registrar

import java.net.URI
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * Validates registrar endpoints, identity role, OAuth client and timing.
 *
 * Endpoint URIs require supported schemes, a host, and no embedded user credentials.
 */
class RegistrarConfiguration(
    val identityIssueUri: URI,
    val sentinelCredentialsUri: URI,
    val oauth: OAuthClient,
    val natsServerUri: URI,
    val role: ServiceRole,
    val timing: RegistrarTiming = RegistrarTiming(),
) {
    init {
        listOf(identityIssueUri, sentinelCredentialsUri).forEach { requireUri(it, setOf("http", "https")) }
        requireUri(natsServerUri, setOf("nats", "tls", "ws", "wss"))
    }
}

/** The OAuth client a service exchanges its identity for access tokens as: at [tokenUri], as [clientId], for [scopes]. */
class OAuthClient(
    val tokenUri: URI,
    val clientId: String,
    scopes: Set<String>,
) {
    val scopes: Set<String> = scopes.toSet()

    init {
        requireUri(tokenUri, setOf("http", "https"))
        require(clientId.isNotBlank() && clientId == clientId.trim())
        require(this.scopes.isNotEmpty() && this.scopes.all { it.isNotBlank() && it == it.trim() })
    }
}

/**
 * How often a registrar refreshes and how long it waits. Durations must be positive and finite; binding refresh stays
 * below the registration lease and Sentinel refresh cannot exceed maximum staleness.
 */
data class RegistrarTiming(
    val bindingRefreshInterval: Duration = 2.minutes,
    val heartbeatInterval: Duration = 30.seconds,
    val accessTokenRefreshSkew: Duration = 1.minutes,
    val sentinelRefreshAfter: Duration = 1.hours,
    val sentinelMaximumStaleness: Duration = 24.hours,
    val shutdownTimeout: Duration = 30.seconds,
) {
    init {
        listOf(
            bindingRefreshInterval,
            heartbeatInterval,
            accessTokenRefreshSkew,
            sentinelRefreshAfter,
            sentinelMaximumStaleness,
            shutdownTimeout,
        ).forEach {
            require(it.isFinite() && it.isPositive()) { "durations must be positive and finite" }
        }
        require(bindingRefreshInterval < 150.seconds) { "binding refresh must be below the registration lease" }
        require(sentinelRefreshAfter <= sentinelMaximumStaleness)
    }
}

private fun requireUri(
    uri: URI,
    schemes: Set<String>,
) {
    require(
        uri.isAbsolute && uri.scheme.lowercase() in schemes && !uri.host.isNullOrBlank() && uri.userInfo == null,
    ) { "invalid endpoint URI" }
}
