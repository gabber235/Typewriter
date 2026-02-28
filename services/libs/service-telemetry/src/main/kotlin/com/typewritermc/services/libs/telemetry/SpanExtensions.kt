package com.typewritermc.services.libs.telemetry

import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.Tracer
import io.opentelemetry.context.Context
import io.opentelemetry.extension.kotlin.asContextElement
import kotlinx.coroutines.withContext

inline fun <T> Span.timed(operationName: String, block: () -> T): T {
    val start = System.nanoTime()
    return try {
        block()
    } finally {
        val durationMs = (System.nanoTime() - start) / 1_000_000
        addEvent(
            operationName,
            Attributes.of(AttributeKey.longKey("duration_ms"), durationMs)
        )
    }
}

fun Span.hideLog(): Span = setAttribute("log.hide", true)

inline fun <T> Tracer.withSpan(
    name: String,
    kind: SpanKind = SpanKind.INTERNAL,
    crossinline block: (Span) -> T
): T {
    val parentContext = Context.current()
    val span = spanBuilder(name)
        .setSpanKind(kind)
        .setParent(parentContext)
        .setAttribute("log.name", name())
        .startSpan()

    return try {
        block(span).also { span.setStatus(StatusCode.OK) }
    } catch (e: Exception) {
        span.recordException(e)
        span.setStatus(StatusCode.ERROR, e.message ?: "Unknown error")
        throw e
    } finally {
        span.end()
    }
}

suspend inline fun <T> Tracer.withSuspendSpan(
    name: String,
    kind: SpanKind = SpanKind.INTERNAL,
    crossinline block: suspend (Span) -> T
): T {
    val parentContext = Context.current()
    val span = spanBuilder(name)
        .setSpanKind(kind)
        .setParent(parentContext)
        .setAttribute("log.name", name())
        .startSpan()

    return withContext(span.asContextElement()) {
        try {
            block(span).also { span.setStatus(StatusCode.OK) }
        } catch (e: Exception) {
            span.recordException(e)
            span.setStatus(StatusCode.ERROR, e.message ?: "Unknown error")
            throw e
        } finally {
            span.end()
        }
    }
}

inline fun name(): String {
    val name = {}.javaClass.name
    val slicedName =
        when {
            name.contains("Kt$") -> name.substringBefore("Kt$")
            name.contains("$") -> name.substringBefore("$")
            else -> name
        }
    return slicedName
}
