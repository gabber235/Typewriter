package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.http.core.*
import com.typewritermc.services.libs.registrar.*
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

sealed interface AccessTokenResult {
    data class Success(val token: RedactedSecret.AccessToken, val expiresInSeconds: Long) : AccessTokenResult
    data class Failure(val failure: RegistrarFailure.AccessToken) : AccessTokenResult
}

fun interface AccessTokenExchanger {
    suspend fun exchange(credentials: IdentityCredentials): AccessTokenResult
}

class AuthentikTokenExchanger(
    private val client: ServiceHttpClient,
    private val uri: URI,
    private val clientId: String,
    scopes: Set<String>,
) : AccessTokenExchanger {
    private val scope = scopes.sorted().joinToString(" ")

    override suspend fun exchange(credentials: IdentityCredentials): AccessTokenResult {
        val values = listOf(
            "grant_type" to "client_credentials",
            "client_id" to clientId,
            "username" to credentials.identity.username,
            "password" to credentials.revealAppPassword(),
            "scope" to scope,
        )
        val body = values.joinToString("&") { (key, value) -> "${encode(key)}=${encode(value)}" }
            .toByteArray(StandardCharsets.UTF_8)
        val result = client.execute(
            HttpRequest(
                HttpOperation("registrar.oauth.exchange"), ErrorSlug.of("oauth-exchange-failed"), HttpMethod.POST,
                uri, HttpHeaders.of("Content-Type" to "application/x-www-form-urlencoded"), body,
                maximumRequestBytes = 64 * 1024, maximumResponseBytes = 64 * 1024,
            ),
        )
        if (result is HttpResult.Failure) return unavailable()
        result as HttpResult.Success
        if (result.response.statusCode in 400..499) return rejected()
        if (result.response.statusCode !in 200..299) return unavailable()
        val response = try {
            oauthJson.decodeFromString<TokenResponse>(result.response.body.toString(StandardCharsets.UTF_8))
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
            return protocol()
        }
        if (
            response.token.isBlank() ||
            !response.tokenType.equals("Bearer", ignoreCase = true) ||
            response.expiresIn <= 0 ||
            !response.expiresIn.seconds.isFinite()
        ) return protocol()
        return AccessTokenResult.Success(RedactedSecret.AccessToken(response.token), response.expiresIn)
    }

    private fun encode(value: String) = URLEncoder.encode(value, StandardCharsets.UTF_8).replace("+", "%20")
    private fun unavailable() = AccessTokenResult.Failure(
        RegistrarFailure.AccessToken(AccessTokenFailureReason.UNAVAILABLE, true),
    )
    private fun rejected() = AccessTokenResult.Failure(
        RegistrarFailure.AccessToken(AccessTokenFailureReason.REJECTED, false),
    )
    private fun protocol() = AccessTokenResult.Failure(
        RegistrarFailure.AccessToken(AccessTokenFailureReason.PROTOCOL, false),
    )
}

@Serializable
private data class TokenResponse(
    @SerialName("access_token") val token: String,
    @SerialName("expires_in") val expiresIn: Long,
    @SerialName("token_type") val tokenType: String,
)

private val oauthJson = Json { ignoreUnknownKeys = true }

class AccessTokenCache(
    private val credentials: IdentityCredentials,
    private val exchanger: AccessTokenExchanger,
    private val clock: TimeSource,
    private val skew: Duration,
) {
    private data class Entry(val result: AccessTokenResult.Success, val created: TimeMark)
    private val mutex = Mutex()
    private var entry: Entry? = null

    init {
        require(skew.isFinite() && !skew.isNegative()) { "Token cache skew must be finite and non-negative" }
    }

    suspend fun get(): AccessTokenResult = mutex.withLock {
        entry?.takeIf { it.created.elapsedNow() + skew < it.result.expiresInSeconds.seconds }?.result
            ?: exchanger.exchange(credentials).also { result ->
                if (result is AccessTokenResult.Success) entry = Entry(result, clock.markNow())
            }
    }

    suspend fun invalidate() = clear()
    suspend fun clear() = mutex.withLock { entry = null }
}
