package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.telemetry.withSpan
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.Tracer
import protokt.v1.typewriter.api.v1.GetSentinelCredentialsResponse

data class SentinelCredentials(
    val jwt: String,
    val seed: String
)

class SentinelCredentialsFetcher(
    private val httpClient: HttpClient,
    private val sentinelUrl: String,
    private val tracer: Tracer
) {
    fun fetchCredentials(): SentinelCredentials = tracer.withSpan(
        name = "sentinel.fetch",
        kind = SpanKind.CLIENT
    ) { s ->
        s.addEvent("fetching_credentials")
        s.setAttribute("server.address", sentinelUrl)

        val headers = mapOf("Accept" to "application/x-protobuf")

        val response = try {
            httpClient.get(sentinelUrl, headers)
        } catch (e: Exception) {
            throw SentinelCredentialsException("Failed to fetch sentinel credentials: ${e.message}", e)
        }

        if (!response.isSuccessful) {
            val errorBody = response.body.bufferedReader().readText()
            s.setAttribute("http.response.status_code", response.statusCode.toLong())
            s.setAttribute("http.response.body", errorBody)
            throw SentinelCredentialsException("Failed to fetch sentinel credentials: HTTP ${response.statusCode}")
        }

        val protoResponse = try {
            GetSentinelCredentialsResponse.deserialize(response.body)
        } catch (e: Exception) {
            throw SentinelCredentialsException("Failed to parse sentinel credentials response", e)
        }

        when (val result = protoResponse.result) {
            is GetSentinelCredentialsResponse.Result.Credentials -> {
                s.addEvent("credentials_fetched")
                val jwt = result.credentials.jwt.ifBlank {
                    throw SentinelCredentialsException("Sentinel response missing jwt")
                }
                val seed = result.credentials.seed.ifBlank {
                    throw SentinelCredentialsException("Sentinel response missing seed")
                }
                SentinelCredentials(jwt = jwt, seed = seed)
            }

            is GetSentinelCredentialsResponse.Result.Error -> {
                val code = result.error.code ?: 0u
                val msg = result.error.message ?: "unknown error"
                s.setAttribute("response.error.code", code.toLong())
                s.setAttribute("response.error.message", msg)
                throw SentinelCredentialsException(
                    "Failed to fetch sentinel credentials ($code): $msg"
                )
            }

            null -> {
                throw SentinelCredentialsException("Empty response from identity service")
            }
        }
    }
}

class SentinelCredentialsException(
    message: String,
    cause: Throwable? = null
) : RuntimeException(message, cause)
