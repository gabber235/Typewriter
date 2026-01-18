package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import protokt.v1.typewriter.api.v1.GetSentinelCredentialsResponse

data class SentinelCredentials(
    val jwt: String,
    val seed: String
)

class SentinelCredentialsFetcher(
    private val httpClient: HttpClient,
    private val sentinelUrl: String
) {
    private val logger: KLogger = logger {}

    fun fetchCredentials(): SentinelCredentials {
        logger.debug { "Fetching sentinel credentials from $sentinelUrl" }

        val headers = mapOf("Accept" to "application/x-protobuf")

        val response = try {
            httpClient.get(sentinelUrl, headers)
        } catch (e: Exception) {
            logger.error(e) { "Failed to fetch sentinel credentials: connection error" }
            throw SentinelCredentialsException("Failed to fetch sentinel credentials: ${e.message}", e)
        }

        if (!response.isSuccessful) {
            val errorBody = response.body.bufferedReader().readText()
            logger.error { "Sentinel credentials fetch failed: HTTP ${response.statusCode} - $errorBody" }
            throw SentinelCredentialsException("Failed to fetch sentinel credentials: HTTP ${response.statusCode}")
        }

        val protoResponse = try {
            GetSentinelCredentialsResponse.deserialize(response.body)
        } catch (e: Exception) {
            logger.error(e) { "Failed to parse sentinel credentials response" }
            throw SentinelCredentialsException("Failed to parse sentinel credentials response", e)
        }

        return when (val result = protoResponse.result) {
            is GetSentinelCredentialsResponse.Result.Credentials -> {
                logger.debug { "Successfully fetched sentinel credentials" }
                SentinelCredentials(
                    jwt = result.credentials.jwt,
                    seed = result.credentials.seed
                )
            }

            is GetSentinelCredentialsResponse.Result.Error -> throw SentinelCredentialsException(
                "Failed to fetch sentinel credentials (${result.error.code}): ${result.error.message}"
            )

            null -> throw SentinelCredentialsException("Empty response from identity service")
        }
    }
}

class SentinelCredentialsException(
    message: String,
    cause: Throwable? = null
) : RuntimeException(message, cause)
