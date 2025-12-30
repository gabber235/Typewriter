package com.typewritermc.services.libs.registrar

import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.net.HttpURLConnection
import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

/**
 * Response from OAuth2 token endpoint.
 */
@Serializable
data class TokenResponse(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String? = null,
    @SerialName("expires_in") val expiresIn: Long,
    @SerialName("token_type") val tokenType: String
)

/**
 * Interface for exchanging service credentials for JWT tokens.
 *
 * Implementations are responsible for exchanging a [Credential]'s username
 * and token (app password) for a JWT access token from the authentication provider.
 */
interface JwtExchanger {
    /**
     * Exchanges the given credential for a JWT access token.
     *
     * @param credential The service credential containing username and app password
     * @return TokenResponse containing the access token and metadata
     * @throws JwtExchangeException if the exchange fails
     */
    fun exchangeForJwt(credential: Credential): TokenResponse
}

/**
 * Implementation of [JwtExchanger] that exchanges credentials via Authentik OAuth2.
 *
 * Uses the client credentials grant type with username/password to exchange
 * service credentials (username + app password) for JWT tokens.
 */
class AuthentikJwtExchanger : JwtExchanger, KoinComponent {
    private val logger: KLogger = logger {}
    private val json = Json { ignoreUnknownKeys = true }

    private val tokenEndpoint: String by inject(named("jwt-token-endpoint"))
    private val clientId: String by inject(named("jwt-client-id"))
    private val scopes: String by inject(named("jwt-scopes"))

    override fun exchangeForJwt(credential: Credential): TokenResponse {
        logger.debug { "Exchanging credential for JWT: ${credential.name}" }

        val formData = buildFormData(
            "grant_type" to "client_credentials",
            "client_id" to clientId,
            "username" to credential.name,
            "password" to credential.token,
            "scope" to scopes
        )

        val url = URI(tokenEndpoint).toURL()
        val connection = url.openConnection() as HttpURLConnection

        connection.requestMethod = "POST"
        connection.doOutput = true
        connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")

        connection.outputStream.use { outputStream ->
            outputStream.write(formData.toByteArray(StandardCharsets.UTF_8))
        }

        val responseCode = connection.responseCode
        val responseBody = if (responseCode in 200..299) {
            connection.inputStream.bufferedReader().readText()
        } else {
            val errorBody = connection.errorStream?.bufferedReader()?.readText() ?: "No error body"
            logger.error { "JWT exchange failed: $responseCode - $errorBody" }
            throw JwtExchangeException("Failed to exchange credential for JWT: HTTP $responseCode - $errorBody")
        }

        return try {
            json.decodeFromString<TokenResponse>(responseBody)
        } catch (e: Exception) {
            logger.error(e) { "Failed to parse token response" }
            throw JwtExchangeException("Failed to parse token response", e)
        }
    }

    private fun buildFormData(vararg params: Pair<String, String>): String {
        return params.joinToString("&") { (key, value) ->
            "${URLEncoder.encode(key, StandardCharsets.UTF_8)}=${URLEncoder.encode(value, StandardCharsets.UTF_8)}"
        }
    }
}

/**
 * Exception thrown when JWT exchange fails.
 */
class JwtExchangeException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)
