package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.http.core.HttpHeaders
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.http.core.HttpResponse
import com.typewritermc.services.libs.http.core.HttpResult
import com.typewritermc.services.libs.http.core.ServiceHttpClient
import com.typewritermc.services.libs.http.testing.FakeHttpTransport
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness

val mediaHeaders =
    HttpHeaders.of(
        "Content-Type" to "application/octet-stream",
        "X-Typewriter-Format" to "skir-binary",
    )

/** A successful HTTP result with [status], [body] and [headers] of the binary Skir media type. */
fun httpResponse(
    status: Int,
    body: ByteArray,
    headers: HttpHeaders = mediaHeaders,
) = HttpResult.Success(HttpResponse(status, headers, body))

/** A fake transport answering with [outcomes] in order, and the client that calls it. */
data class HttpFixture(
    val transport: FakeHttpTransport,
    val harness: TelemetryTestHarness,
    val client: ServiceHttpClient,
) : AutoCloseable {
    override fun close() = harness.close()
}

fun httpFixture(vararg outcomes: HttpResult): HttpFixture {
    val transport =
        FakeHttpTransport(
            outcomes.map { result ->
                suspend { _: HttpRequest -> result }
            },
        )
    val harness = TelemetryTestHarness.create()
    return HttpFixture(transport, harness, ServiceHttpClient(transport, harness.telemetry, harness.openTelemetry.propagators))
}
