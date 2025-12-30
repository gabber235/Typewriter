package com.typewritermc.services.libs.communicator

import io.github.oshai.kotlinlogging.KotlinLogging.logger
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import protokt.v1.typewriter.api.v1.GetSentinelCredentialsResponse
import java.net.HttpURLConnection
import java.net.URI

/**
 * Data class containing sentinel credentials for NATS authentication.
 */
data class SentinelCredentials(
    val jwt: String,
    val seed: String
)

/**
 * Fetches sentinel credentials from the identity service.
 *
 * Sentinel credentials are used for initial NATS connection before
 * full authentication occurs. These credentials have no permissions
 * and are only used to identify the account during NATS auth callout.
 */
class SentinelCredentialsFetcher : KoinComponent {
    private val logger = logger {}

    private val sentinelUrl: String by inject(named("sentinel-url"))

    /**
     * Fetch sentinel credentials from the identity service.
     *
     * @return SentinelCredentials containing the JWT and seed
     * @throws SentinelCredentialsException if credentials cannot be fetched
     */
    fun fetchCredentials(): SentinelCredentials {
        logger.debug { "Fetching sentinel credentials from $sentinelUrl" }

        val url = URI(sentinelUrl).toURL()
        val connection = url.openConnection() as HttpURLConnection

        connection.requestMethod = "GET"
        connection.setRequestProperty("Accept", "application/x-protobuf")

        val responseCode = connection.responseCode
        val stream = if (responseCode in 200..299) {
            connection.inputStream
        } else {
            connection.errorStream
        }

        val response = GetSentinelCredentialsResponse.deserialize(stream)

        return when (val result = response.result) {
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

/**
 * Exception thrown when sentinel credentials cannot be fetched.
 */
class SentinelCredentialsException(
    message: String,
    cause: Throwable? = null
) : RuntimeException(message, cause)
