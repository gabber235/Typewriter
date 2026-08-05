package com.typewritermc.services.libs.http.jdk

import com.typewritermc.services.libs.http.core.HttpError
import com.typewritermc.services.libs.http.core.HttpHeaders
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.http.core.HttpResponse
import com.typewritermc.services.libs.http.core.HttpResult
import com.typewritermc.services.libs.http.core.HttpTransport
import com.typewritermc.services.libs.utils.await
import kotlinx.coroutines.CancellationException
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.ConnectException
import java.net.http.HttpClient
import java.net.http.HttpConnectTimeoutException
import java.net.http.HttpRequest.BodyPublishers
import java.net.http.HttpResponse.BodyHandler
import java.net.http.HttpResponse.BodySubscriber
import java.net.http.HttpTimeoutException
import java.nio.ByteBuffer
import java.time.Duration
import java.util.concurrent.CompletionStage
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Flow
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration.Companion.seconds
import kotlin.time.toJavaDuration

/** Configuration for a Java HTTP transport. */
data class JdkHttpTransportConfiguration(
    val connectTimeout: kotlin.time.Duration = 10.seconds,
    val defaultRequestTimeout: kotlin.time.Duration = 30.seconds,
    val defaultMaximumRequestBytes: Long = 1024 * 1024,
    val defaultMaximumResponseBytes: Long = 1024 * 1024,
) {
    init {
        require(connectTimeout.isFinite() && connectTimeout.isPositive())
        require(defaultRequestTimeout.isFinite() && defaultRequestTimeout.isPositive())
        require(defaultMaximumRequestBytes > 0 && defaultMaximumResponseBytes > 0)
    }
}

/** Java 21 asynchronous HTTP transport. Closing is idempotent and subsequent execution fails immediately. */
class JdkHttpTransport(
    private val configuration: JdkHttpTransportConfiguration = JdkHttpTransportConfiguration(),
) : HttpTransport,
    AutoCloseable {
    private val closed = AtomicBoolean()
    private val executor: ExecutorService = Executors.newCachedThreadPool()
    private val client =
        HttpClient
            .newBuilder()
            .executor(executor)
            .connectTimeout(configuration.connectTimeout.toJavaDuration())
            .followRedirects(HttpClient.Redirect.NEVER)
            .build()

    override suspend fun execute(request: HttpRequest): HttpResult {
        check(!closed.get()) { "JdkHttpTransport is closed" }
        val body = request.body
        val requestLimit = request.maximumRequestBytes ?: configuration.defaultMaximumRequestBytes
        if (body.size.toLong() > requestLimit) return HttpResult.Failure(HttpError.RequestTooLarge(requestLimit, body.size.toLong()))
        val builder =
            java.net.http.HttpRequest
                .newBuilder(request.uri)
                .timeout((request.timeout ?: configuration.defaultRequestTimeout).toJavaDuration())
        request.headers.forEach { (name, value) -> builder.header(name, value) }
        builder.method(request.method.name, if (body.isEmpty()) BodyPublishers.noBody() else BodyPublishers.ofByteArray(body))
        val limit = request.maximumResponseBytes ?: configuration.defaultMaximumResponseBytes
        return try {
            val response = client.sendAsync(builder.build(), BodyHandler { LimitedBodySubscriber(limit) }).await()
            HttpResult.Success(
                HttpResponse(
                    response.statusCode(),
                    response.headers().toCoreHeaders(),
                    response.body(),
                ),
            )
        } catch (failure: Throwable) {
            rethrowExceptional(failure)
            when (val cause = unwrap(failure)) {
                is ResponseLimitException -> HttpResult.Failure(HttpError.ResponseTooLarge(limit))
                is HttpTimeoutException, is HttpConnectTimeoutException -> HttpResult.Failure(HttpError.Timeout)
                is ConnectException -> HttpResult.Failure(HttpError.Unavailable)
                is IOException -> HttpResult.Failure(HttpError.Transport(cause.javaClass.name))
                else -> throw cause
            }
        }
    }

    override fun close() {
        if (closed.compareAndSet(false, true)) executor.shutdownNow()
    }
}

internal fun java.net.http.HttpHeaders.toCoreHeaders(): HttpHeaders =
    HttpHeaders.of(
        map().flatMap { (name, values) ->
            if (name.startsWith(":")) emptyList() else values.map { value -> name to value }
        },
    )

private tailrec fun unwrap(failure: Throwable): Throwable =
    if (failure.cause != null &&
        failure is java.util.concurrent.CompletionException
    ) {
        unwrap(failure.cause!!)
    } else {
        failure
    }

private fun rethrowExceptional(failure: Throwable) {
    var current: Throwable? = failure
    while (current != null) {
        if (current is CancellationException || current is VirtualMachineError || current is ThreadDeath ||
            current is LinkageError
        ) {
            throw current
        }
        current = current.cause
    }
}

private class ResponseLimitException : RuntimeException()

private class LimitedBodySubscriber(
    private val maximum: Long,
) : BodySubscriber<ByteArray> {
    private val future = java.util.concurrent.CompletableFuture<ByteArray>()
    private val output = ByteArrayOutputStream()
    private var subscription: Flow.Subscription? = null
    private var count = 0L

    override fun getBody(): CompletionStage<ByteArray> = future

    override fun onSubscribe(subscription: Flow.Subscription) {
        this.subscription = subscription
        subscription.request(1)
    }

    override fun onNext(items: List<ByteBuffer>) {
        for (item in items) {
            count += item.remaining()
            if (count > maximum) {
                subscription?.cancel()
                future.completeExceptionally(ResponseLimitException())
                return
            }
            val bytes = ByteArray(item.remaining())
            item.get(bytes)
            output.write(bytes)
        }
        subscription?.request(1)
    }

    override fun onError(throwable: Throwable) {
        future.completeExceptionally(throwable)
    }

    override fun onComplete() {
        future.complete(output.toByteArray())
    }
}
