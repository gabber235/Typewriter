@file:Suppress("ForbiddenMethodCall")

package com.typewritermc.services.libs.telemetry

import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.Span
import io.opentelemetry.semconv.DbAttributes
import io.opentelemetry.semconv.HttpAttributes
import io.opentelemetry.semconv.ServerAttributes
import java.util.concurrent.ConcurrentHashMap

interface MainSpanScope {
    fun annotate(block: MainAttributes.() -> Unit)

    fun event(
        name: String,
        projection: EventProjection = EventProjection.TraceOnly,
        block: TelemetryEventAttributes.() -> Unit = {},
    )

    fun recordDegraded(
        slug: ErrorSlug,
        cause: Throwable,
    )
}

interface ChildSpanScope {
    fun annotate(block: ChildAttributes.() -> Unit)

    fun event(
        name: String,
        projection: EventProjection = EventProjection.TraceOnly,
        block: TelemetryEventAttributes.() -> Unit = {},
    )
}

/** Messaging keys not available in the pinned stable semantic-conventions artifact. */
object MessagingAttributeKeys {
    val System: AttributeKey<String> = AttributeKey.stringKey("messaging.system")
    val DestinationName: AttributeKey<String> = AttributeKey.stringKey("messaging.destination.name")
    val DestinationTemplate: AttributeKey<String> = AttributeKey.stringKey("messaging.destination.template")
    val OperationName: AttributeKey<String> = AttributeKey.stringKey("messaging.operation.name")
    val OperationType: AttributeKey<String> = AttributeKey.stringKey("messaging.operation.type")
    val MessageId: AttributeKey<String> = AttributeKey.stringKey("messaging.message.id")
}

internal fun interface SpanMutation {
    fun apply(action: (Span) -> Unit)
}

open class TypedAttributes internal constructor(
    private val mutation: SpanMutation,
) {
    fun attribute(
        key: AttributeKey<String>,
        value: String,
    ) = mutation.apply { it.setAttribute(key, value) }

    fun attribute(
        key: AttributeKey<Long>,
        value: Long,
    ) = mutation.apply { it.setAttribute(key, value) }

    fun attribute(
        key: AttributeKey<Double>,
        value: Double,
    ) = mutation.apply { it.setAttribute(key, value) }

    fun attribute(
        key: AttributeKey<Boolean>,
        value: Boolean,
    ) = mutation.apply { it.setAttribute(key, value) }

    fun attribute(
        key: String,
        value: String,
    ) = attribute(AttributeKey.stringKey(key), value)

    fun attribute(
        key: String,
        value: Int,
    ) = attribute(key, value.toLong())

    fun attribute(
        key: String,
        value: Long,
    ) = attribute(AttributeKey.longKey(key), value)

    fun attribute(
        key: String,
        value: Double,
    ) = attribute(AttributeKey.doubleKey(key), value)

    fun attribute(
        key: String,
        value: Boolean,
    ) = attribute(AttributeKey.booleanKey(key), value)
}

class CounterKey(
    val value: String,
) {
    init {
        requireStableSegment(value)
    }
}

class MainAttributes internal constructor(
    mutation: SpanMutation,
    private val incrementCounter: (CounterKey, Long) -> Long,
) : TypedAttributes(mutation) {
    fun operationOutcome(value: String) = attribute("operation.outcome", value)

    fun domainOutcome(value: String) = attribute("domain.outcome", value)

    fun featureFlag(
        name: String,
        enabled: Boolean,
    ) {
        requireStableSegment(name)
        attribute("feature_flag.$name", enabled)
    }

    fun featureFlag(
        name: String,
        value: String,
    ) {
        requireStableSegment(name)
        attribute("feature_flag.$name", value)
    }

    fun count(
        key: String,
        value: Long,
    ) = attribute(key, value)

    fun increment(
        key: CounterKey,
        delta: Long = 1,
    ): Long = incrementCounter(key, delta)

    fun stage(
        name: String,
        block: StageAttributes.() -> Unit,
    ) {
        requireStableSegment(name)
        StageAttributes(this, name).block()
    }

    fun httpRequestMethod(value: String) = attribute(HttpAttributes.HTTP_REQUEST_METHOD, value)

    fun httpRoute(value: String) = attribute(HttpAttributes.HTTP_ROUTE, value)

    fun httpResponseStatusCode(value: Int) = attribute(HttpAttributes.HTTP_RESPONSE_STATUS_CODE, value.toLong())

    fun messagingSystem(value: String) = attribute(MessagingAttributeKeys.System, value)

    fun messagingDestinationName(value: String) = attribute(MessagingAttributeKeys.DestinationName, value)

    fun messagingDestinationTemplate(value: String) = attribute(MessagingAttributeKeys.DestinationTemplate, value)

    fun messagingOperationName(value: String) = attribute(MessagingAttributeKeys.OperationName, value)

    fun messagingOperationType(value: String) = attribute(MessagingAttributeKeys.OperationType, value)

    fun messagingMessageId(value: String) = attribute(MessagingAttributeKeys.MessageId, value)
}

class ChildAttributes internal constructor(
    mutation: SpanMutation,
) : TypedAttributes(mutation) {
    fun dbOperationName(value: String) = attribute(DbAttributes.DB_OPERATION_NAME, value)

    fun dbResponseStatusCode(value: String) = attribute(DbAttributes.DB_RESPONSE_STATUS_CODE, value)

    fun httpResponseStatusCode(value: Int) = attribute(HttpAttributes.HTTP_RESPONSE_STATUS_CODE, value.toLong())

    fun messagingOperationType(value: String) = attribute(MessagingAttributeKeys.OperationType, value)

    fun serverAddress(value: String) = attribute(ServerAttributes.SERVER_ADDRESS, value)

    fun serverPort(value: Int) = attribute(ServerAttributes.SERVER_PORT, value.toLong())
}

class StageAttributes internal constructor(
    private val attributes: MainAttributes,
    private val name: String,
) {
    fun outcome(value: String) = attributes.attribute("workflow.stage.$name.outcome", value)

    fun attempts(value: Int) = attributes.attribute("workflow.stage.$name.attempts", value)

    fun durationMs(value: Long) = attributes.attribute("workflow.stage.$name.duration_ms", value)
}

private val stableSegmentPattern = Regex("[a-z0-9]+(?:[._-][a-z0-9]+)*")

internal fun requireStableSegment(value: String) {
    require(stableSegmentPattern.matches(value)) { "Invalid stable attribute segment: $value" }
}

internal class MainScope(
    internal val telemetry: ServiceTelemetry,
    private val span: Span,
    private val spanName: String,
    private val presentation: SpanPresentation?,
) : MainSpanScope {
    private val lock = Any()
    private var active = true
    private val counters = ConcurrentHashMap<String, Long>()
    private val mutation = SpanMutation { action -> mutate(action) }
    private val startedAt = System.nanoTime()

    init {
        val spanContext = span.spanContext
        if (spanContext.isValid) {
            span.setAttribute("trace_id", spanContext.traceId)
            span.setAttribute("span_id", spanContext.spanId)
        }
    }

    override fun annotate(block: MainAttributes.() -> Unit) {
        ensureActive()
        MainAttributes(mutation, ::increment).block()
    }

    override fun event(
        name: String,
        projection: EventProjection,
        block: TelemetryEventAttributes.() -> Unit,
    ) = mutate { activeSpan -> telemetry.recordEvent(activeSpan, name, projection, block) }

    fun recordStarted() {
        val visible = presentation ?: return
        event(
            name = "operation.started",
            projection = EventProjection.log(LogSeverity.INFO, "${visible.displayName} started"),
        ) {
            attribute("span.name", spanName)
            attribute("operation.outcome", "started")
        }
    }

    fun recordCompleted() {
        val visible = presentation ?: return
        event(
            name = "operation.completed",
            projection = EventProjection.log(LogSeverity.INFO, "${visible.displayName} completed"),
        ) {
            attribute("span.name", spanName)
            attribute("operation.outcome", "completed")
            attribute("operation.duration_ms", durationMillis())
        }
    }

    fun recordCancelled() {
        val visible = presentation ?: return
        event(
            name = "operation.cancelled",
            projection = EventProjection.log(LogSeverity.INFO, "${visible.displayName} cancelled"),
        ) {
            attribute("span.name", spanName)
            attribute("operation.outcome", "cancelled")
            attribute("operation.duration_ms", durationMillis())
        }
    }

    fun recordFailed(failure: Throwable) {
        val visible = presentation ?: return
        val slug = (failure as? SluggedException)?.slug?.value
        val cause = (failure as? SluggedException)?.cause ?: failure
        event(
            name = "operation.failed",
            projection =
                EventProjection.log(
                    LogSeverity.ERROR,
                    "${visible.displayName} failed",
                ),
        ) {
            attribute("span.name", spanName)
            attribute("operation.outcome", "failed")
            attribute("operation.duration_ms", durationMillis())
            attribute("error.type", cause.javaClass.name)
            slug?.let { attribute("exception.slug", it) }
            exception(cause)
        }
    }

    private fun durationMillis(): Long = (System.nanoTime() - startedAt).coerceAtLeast(0) / 1_000_000

    override fun recordDegraded(
        slug: ErrorSlug,
        cause: Throwable,
    ) = mutate { activeSpan ->
        activeSpan.setAttribute("operation.degraded", true)
        activeSpan.addEvent(
            "exception.degraded",
            Attributes
                .builder()
                .put("exception.slug", slug.value)
                .put("exception.type", cause.javaClass.name)
                .put("exception.message", cause.message ?: cause.javaClass.simpleName)
                .build(),
        )
    }

    fun close() {
        synchronized(lock) {
            if (!active) return
            active = false
            span.end()
        }
    }

    internal fun ensureActive() {
        synchronized(lock) { requireActive() }
    }

    private fun increment(
        key: CounterKey,
        delta: Long,
    ): Long =
        synchronized(lock) {
            requireActive()
            val value = counters.merge(key.value, delta, Long::plus)!!
            span.setAttribute(key.value, value)
            value
        }

    private fun mutate(action: (Span) -> Unit) {
        synchronized(lock) {
            requireActive()
            action(span)
        }
    }

    private fun requireActive() = check(active) { "Main span scope is closed" }
}

internal class ChildScope(
    private val telemetry: ServiceTelemetry,
    private val span: Span,
) : ChildSpanScope {
    private val lock = Any()
    private var active = true
    private val mutation = SpanMutation { action -> mutate(action) }

    override fun annotate(block: ChildAttributes.() -> Unit) {
        synchronized(lock) { requireActive() }
        ChildAttributes(mutation).block()
    }

    override fun event(
        name: String,
        projection: EventProjection,
        block: TelemetryEventAttributes.() -> Unit,
    ) = mutate { activeSpan -> telemetry.recordEvent(activeSpan, name, projection, block) }

    fun close() {
        synchronized(lock) {
            if (!active) return
            active = false
            span.end()
        }
    }

    private fun mutate(action: (Span) -> Unit) {
        synchronized(lock) {
            requireActive()
            action(span)
        }
    }

    private fun requireActive() = check(active) { "Child span scope is closed" }
}

context(main: MainSpanScope)
fun recordRecoveredFailure(
    slug: ErrorSlug,
    cause: Throwable,
) = main.recordDegraded(slug, cause)
