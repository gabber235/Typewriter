package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.utils.RetryPolicy
import java.net.URI
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** Fully validated registrar policy and endpoint configuration. */
class RegistrarConfiguration(
    val identityIssueUri: URI,
    val sentinelCredentialsUri: URI,
    val oauthTokenUri: URI,
    val oauthClientId: String,
    oauthScopes: Set<String>,
    val natsServerUri: URI,
    roles: List<ServiceRole>,
    val bindingRefreshInterval: Duration = 2.minutes,
    val heartbeatInterval: Duration = 30.seconds,
    val accessTokenRefreshSkew: Duration = 1.minutes,
    val sentinelRefreshAfter: Duration = 1.hours,
    val sentinelMaximumStaleness: Duration = 24.hours,
    val shutdownTimeout: Duration = 30.seconds,
    val retryPolicy: RetryPolicy = RetryPolicy.exponential(1.seconds, 30.seconds, jitterRatio = .2),
) {
    val oauthScopes: Set<String> = oauthScopes.toSet()
    val roles: List<ServiceRole> = roles.toList()

    init {
        listOf(identityIssueUri, sentinelCredentialsUri, oauthTokenUri).forEach { requireUri(it, setOf("http", "https")) }
        requireUri(natsServerUri, setOf("nats", "tls", "ws", "wss"))
        require(oauthClientId.isNotBlank() && oauthClientId == oauthClientId.trim())
        require(this.oauthScopes.isNotEmpty() && this.oauthScopes.all { it.isNotBlank() && it == it.trim() })
        validateRoles(this.roles)
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
