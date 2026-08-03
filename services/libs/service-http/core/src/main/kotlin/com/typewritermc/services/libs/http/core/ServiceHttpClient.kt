package com.typewritermc.services.libs.http.core

import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.context.Context
import io.opentelemetry.context.propagation.ContextPropagators
import io.opentelemetry.context.propagation.TextMapSetter
import kotlinx.coroutines.CancellationException

/** Automatically instrumented, propagating HTTP client with no retry behavior. */
class ServiceHttpClient(
    private val transport: HttpTransport,
    private val telemetry: ServiceTelemetry,
    private val propagators: ContextPropagators,
) {
    suspend fun execute(request: HttpRequest): HttpResult {
        val body = request.body
        val bodySize = body.size.toLong()
        val attributes =
            Attributes
                .builder()
                .put("http.request.method", request.method.name)
                .put("url.scheme", request.uri.scheme.lowercase())
                .put("server.address", request.uri.host)
                .put("http.request.body.size", bodySize)
                .put("service.operation", request.operation.value)
                .apply { request.timeout?.let { put("http.request.timeout_ms", it.inWholeMilliseconds) } }
                .build()
        return telemetry.mainSpan(request.operation.value, request.failureSlug, SpanKind.CLIENT, attributes = attributes) { span ->
            try {
                val result =
                    request.maximumRequestBytes?.takeIf { bodySize > it }?.let {
                        HttpResult.Failure(HttpError.RequestTooLarge(it, bodySize))
                    } ?: transport.execute(propagatedRequest(request, body))
                span.annotate {
                    when (result) {
                        is HttpResult.Success -> {
                            operationOutcome("success")
                            attribute("http.response.status_code", result.response.statusCode)
                            attribute(
                                "http.response.body.size",
                                result.response.body.size
                                    .toLong(),
                            )
                        }

                        is HttpResult.Failure -> {
                            operationOutcome("failure")
                            attribute("error.type", result.error.category)
                        }
                    }
                }
                result
            } catch (cancelled: CancellationException) {
                span.annotate {
                    operationOutcome("cancelled")
                    attribute("operation.cancelled", true)
                }
                throw cancelled
            }
        }
    }

    private fun propagatedRequest(
        request: HttpRequest,
        body: ByteArray,
    ): HttpRequest {
        val setter =
            HeaderSetter(
                propagators.textMapPropagator.fields().fold(request.headers) { headers, field ->
                    headers.remove(field)
                },
            )
        propagators.textMapPropagator.inject(Context.current(), setter, HeaderSetter.Setter)
        return HttpRequest(
            request.operation,
            request.failureSlug,
            request.method,
            request.uri,
            setter.headers,
            body,
            request.timeout,
            request.maximumRequestBytes,
            request.maximumResponseBytes,
        )
    }
}

private val HttpError.category: String get() =
    when (this) {
        is HttpError.RequestTooLarge -> "request_too_large"
        is HttpError.ResponseTooLarge -> "response_too_large"
        HttpError.Timeout -> "timeout"
        HttpError.Unavailable -> "unavailable"
        is HttpError.Transport -> "transport"
        is HttpError.Invalid -> "invalid"
    }

private class HeaderSetter(
    var headers: HttpHeaders,
) {
    object Setter : TextMapSetter<HeaderSetter> {
        override fun set(
            carrier: HeaderSetter?,
            key: String,
            value: String,
        ) {
            requireNotNull(carrier).headers = carrier.headers.set(key, value)
        }
    }
}
