package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

@Serializable
data class TokenResponse(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String? = null,
    @SerialName("expires_in") val expiresIn: Long,
    @SerialName("token_type") val tokenType: String
)

interface JwtExchanger {
    fun exchangeForJwt(credential: Credential): TokenResponse
}

class AuthentikJwtExchanger(
    private val httpClient: HttpClient,
    private val tokenEndpoint: String,
    private val clientId: String,
    private val scopes: String
) : JwtExchanger {
    private val logger: KLogger = logger {}
    private val json = Json { ignoreUnknownKeys = true }

    override fun exchangeForJwt(credential: Credential): TokenResponse {
        logger.debug { "Exchanging credential for JWT: ${credential.name}" }

        val formData = buildFormData(
            "grant_type" to "client_credentials",
            "client_id" to clientId,
            "username" to credential.name,
            "password" to credential.token,
            "scope" to scopes
        )

        val headers = mapOf("Content-Type" to "application/x-www-form-urlencoded")

        val response = try {
            httpClient.post(tokenEndpoint, formData.toByteArray(StandardCharsets.UTF_8), headers)
        } catch (e: Exception) {
            logger.error(e) { "JWT exchange failed: connection error" }
            throw JwtExchangeException("Failed to exchange credential for JWT: ${e.message}", e)
        }

        val responseBody = response.body.bufferedReader().readText()

        if (!response.isSuccessful) {
            logger.error { "JWT exchange failed: ${response.statusCode} - $responseBody" }
            throw JwtExchangeException("Failed to exchange credential for JWT: HTTP ${response.statusCode} - $responseBody")
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

class JwtExchangeException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)
