package com.typewritermc.services.libs.http.core

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import io.opentelemetry.context.propagation.ContextPropagators
import java.net.URI
import kotlin.time.Duration

/**
 * One HTTP request for a test. The method is GET without a body and POST with one, unless [method] is given.
 * Operation and error slug are fixed test names, so a case that reads them tests its own labels only.
 */
fun httpRequest(
    uri: URI = URI("https://example.test/path"),
    method: HttpMethod? = null,
    headers: HttpHeaders = HttpHeaders.Empty,
    body: ByteArray = byteArrayOf(),
    timeout: Duration? = null,
    maximumRequestBytes: Long? = null,
    maximumResponseBytes: Long? = null,
) = HttpRequest(
    HttpOperation("http.test"),
    ErrorSlug.of("http-failed"),
    method ?: if (body.isEmpty()) HttpMethod.GET else HttpMethod.POST,
    uri,
    headers,
    body,
    timeout,
    maximumRequestBytes,
    maximumResponseBytes,
)

/** A client over a transport that answers each request with [execute], recording spans on [harness]. */
fun httpClient(
    harness: TelemetryTestHarness,
    execute: suspend (HttpRequest) -> HttpResult,
) = ServiceHttpClient(HttpTransport(execute), harness.telemetry, ContextPropagators.noop())
