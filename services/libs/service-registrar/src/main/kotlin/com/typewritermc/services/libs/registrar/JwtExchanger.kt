package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.registrar.http.HttpClient
import com.typewritermc.services.libs.telemetry.withSpan
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer
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
    private val scopes: String,
    private val tracer: Tracer,
) : JwtExchanger {
    private val logger: KLogger = logger {}
    private val json = Json { ignoreUnknownKeys = true }

    override fun exchangeForJwt(credential: Credential): TokenResponse {
        return tracer.withSpan("jwt.exchange", SpanKind.CLIENT) { s ->
            s.setAttribute("http.method", "POST")
                .setAttribute("http.url", tokenEndpoint)
                .setAttribute("credential.name", credential.name)

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
                s.recordException(e)
                s.setStatus(StatusCode.ERROR, "Connection error: ${e.message}")
                logger.error(e) { "JWT exchange failed: connection error" }
                throw JwtExchangeException("Failed to exchange credential for JWT: ${e.message}", e)
            }

            s.setAttribute("http.status_code", response.statusCode.toLong())
            val responseBody = response.body.bufferedReader().readText()

            if (!response.isSuccessful) {
                s.setStatus(StatusCode.ERROR, "HTTP ${response.statusCode}")
                logger.error { "JWT exchange failed: ${response.statusCode} - $responseBody" }
                throw JwtExchangeException("Failed to exchange credential for JWT: HTTP ${response.statusCode} - $responseBody")
            }

            try {
                val tokenResponse = json.decodeFromString<TokenResponse>(responseBody)
                s.setStatus(StatusCode.OK)
                tokenResponse
            } catch (e: Exception) {
                s.recordException(e)
                s.setStatus(StatusCode.ERROR, "Parse error: ${e.message}")
                logger.error(e) { "Failed to parse token response" }
                throw JwtExchangeException("Failed to parse token response", e)
            }
        }
    }

    private fun buildFormData(vararg params: Pair<String, String>): String {
        return params.joinToString("&") { (key, value) ->
            "${URLEncoder.encode(key, StandardCharsets.UTF_8)}=${URLEncoder.encode(value, StandardCharsets.UTF_8)}"
        }
    }
}

class JwtExchangeException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)
