package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.http.core.HttpMethod
import com.typewritermc.services.libs.http.core.HttpOperation
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.http.core.HttpResult
import com.typewritermc.services.libs.http.core.ServiceHttpClient
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.SentinelFailureReason
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import skirout.access.v1.sentinel.GetSentinelCredentialsResponse
import java.net.URI
import kotlin.time.Duration
import kotlin.time.TimeMark
import kotlin.time.TimeSource

class SentinelCredentials(
    val jwt: RedactedSecret.SentinelJwt,
    val seed: RedactedSecret.SentinelSeed,
) {
    override fun toString() = "SentinelCredentials(jwt=[REDACTED], seed=[REDACTED])"
}

sealed interface SentinelResult {
    data class Success(
        val credentials: SentinelCredentials,
    ) : SentinelResult

    data class Failure(
        val failure: RegistrarFailure.Sentinel,
    ) : SentinelResult
}

fun interface SentinelProvider {
    suspend fun fetch(): SentinelResult
}

class TypewriterSentinelProvider(
    private val client: ServiceHttpClient,
    private val uri: URI,
) : SentinelProvider {
    override suspend fun fetch(): SentinelResult {
        val result =
            client.execute(
                HttpRequest(
                    HttpOperation("registrar.sentinel.get"),
                    ErrorSlug.of("sentinel-get-failed"),
                    HttpMethod.GET,
                    uri,
                    skirGetHeaders,
                    maximumResponseBytes = MAXIMUM_SKIR_BODY,
                ),
            )
        if (result is HttpResult.Failure) return unavailable()
        result as HttpResult.Success
        val status = result.response.statusCode
        if (!result.response.headers.hasSkirMediaType()) return protocol()
        val response =
            try {
                GetSentinelCredentialsResponse.serializer.fromBytes(result.response.body)
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                return protocol()
            }
        return when (response.kind) {
            GetSentinelCredentialsResponse.Kind.SUCCESS_WRAPPER -> {
                if (status != 200) return protocol()
                response as GetSentinelCredentialsResponse.SuccessWrapper
                try {
                    SentinelResult.Success(
                        SentinelCredentials(
                            RedactedSecret.SentinelJwt(response.value.jwt),
                            RedactedSecret.SentinelSeed(response.value.seed),
                        ),
                    )
                } catch (failure: Throwable) {
                    rethrowExceptionalThrowable(failure)
                    protocol()
                }
            }

            GetSentinelCredentialsResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
                if (status != 500) protocol() else unavailable()
            }

            GetSentinelCredentialsResponse.Kind.UNKNOWN -> {
                protocol()
            }
        }
    }

    private fun unavailable() =
        SentinelResult.Failure(
            RegistrarFailure.Sentinel(SentinelFailureReason.UNAVAILABLE, true),
        )

    private fun protocol() =
        SentinelResult.Failure(
            RegistrarFailure.Sentinel(SentinelFailureReason.PROTOCOL, false),
        )
}

class SentinelCache(
    private val provider: SentinelProvider,
    private val refreshAfter: Duration,
    private val maximumStaleness: Duration,
    private val clock: TimeSource,
) {
    private data class Entry(
        val credentials: SentinelCredentials,
        val created: TimeMark,
    )

    private val mutex = Mutex()
    private var entry: Entry? = null

    init {
        require(refreshAfter.isFinite() && !refreshAfter.isNegative()) { "Refresh age must be finite and non-negative" }
        require(maximumStaleness.isFinite() && maximumStaleness >= refreshAfter) {
            "Maximum staleness must be finite and at least the refresh age"
        }
    }

    suspend fun get(): SentinelResult =
        mutex.withLock {
            val current = entry
            if (current != null && current.created.elapsedNow() < refreshAfter) {
                return@withLock SentinelResult.Success(current.credentials)
            }
            when (val fetched = provider.fetch()) {
                is SentinelResult.Success -> {
                    fetched.also { entry = Entry(it.credentials, clock.markNow()) }
                }

                is SentinelResult.Failure -> {
                    val staleAllowed =
                        fetched.failure.reason == SentinelFailureReason.UNAVAILABLE &&
                            fetched.failure.recoverable && current != null &&
                            current.created.elapsedNow() <= maximumStaleness
                    if (staleAllowed) SentinelResult.Success(current.credentials) else fetched
                }
            }
        }

    suspend fun invalidate() = clear()

    suspend fun clear() = mutex.withLock { entry = null }
}
