@file:Suppress("ForbiddenMethodCall")

package com.typewritermc.services.libs.telemetry

import com.typewritermc.services.libs.utils.findExceptionalThrowable
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.context.Context
import io.opentelemetry.context.ContextKey
import io.opentelemetry.extension.kotlin.asContextElement
import io.opentelemetry.semconv.ExceptionAttributes
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.withContext

private val mainScopeKey: ContextKey<MainSpanScope> = ContextKey.named("telemetry-main-scope")

/**
 * Returns the main operation scope installed in this telemetry context, or null outside an owned boundary.
 */
fun Context.mainSpanScope(): MainSpanScope? = get(mainScopeKey)

private fun ServiceTelemetry.start(
    name: String,
    kind: SpanKind,
    parent: Context,
    attributes: Attributes,
): Span =
    tracer
        .spanBuilder(name)
        .setSpanKind(kind)
        .setParent(parent)
        .setAllAttributes(attributes)
        .startSpan()

private fun installed(
    parent: Context,
    span: Span,
    main: MainSpanScope,
): Context = parent.with(span).with(mainScopeKey, main)

private fun cancelled(span: Span) {
    span.setAttribute("operation.cancelled", true)
}

private fun rethrowExceptional(
    span: Span,
    thrown: Throwable,
) {
    val exceptional = findExceptionalThrowable(thrown) ?: return
    if (exceptional is CancellationException) cancelled(span)
    throw exceptional
}

private fun recordFailure(
    span: Span,
    thrown: Throwable,
    fallback: ErrorSlug?,
): Throwable {
    val classified =
        when {
            thrown is SluggedException -> thrown
            fallback != null -> SluggedException.wrap(fallback, thrown)
            else -> null
        }
    val cause = classified?.cause ?: thrown
    span.setAttribute("error", true)
    span.setAttribute("error.type", cause.javaClass.name)
    classified?.let { span.setAttribute("exception.slug", it.slug.value) }
    span.recordException(cause)
    span.setStatus(StatusCode.ERROR, (classified?.slug?.value ?: cause.javaClass.name).take(255))
    (
        thrown.suppressed.asSequence() + (
            classified?.suppressed?.asSequence()
                ?: emptySequence()
        ) + cause.suppressed.asSequence()
    ).distinct().filterIsInstance<SluggedException>().forEach {
        val additional = it.cause ?: it
        span.addEvent(
            "exception.additional",
            Attributes
                .builder()
                .put("exception.slug", it.slug.value)
                .put(ExceptionAttributes.EXCEPTION_TYPE, additional.javaClass.name)
                .put(ExceptionAttributes.EXCEPTION_MESSAGE, additional.message ?: additional.javaClass.simpleName)
                .put(ExceptionAttributes.EXCEPTION_STACKTRACE, additional.stackTraceToString())
                .build(),
        )
    }
    return classified ?: thrown
}

/**
 * Runs synchronous work inside an owned main span and current thread telemetry context.
 *
 * The scope records lifecycle outcome and closes in finally. Ordinary failures receive the fallback slug when
 * needed; cancellation and fatal failures propagate. Use the suspending boundary when work can suspend.
 */
fun <T> ServiceTelemetry.mainSpanBlocking(
    name: String,
    unhandledFailureSlug: ErrorSlug,
    kind: SpanKind = SpanKind.INTERNAL,
    parent: Context = Context.current(),
    attributes: Attributes = Attributes.empty(),
    presentation: SpanPresentation? = null,
    block: context(MainSpanScope) (MainSpanScope) -> T,
): T {
    val span = start(name, kind, parent, attributes)
    val main = MainScope(this, span, name, presentation)
    val context = installed(parent, span, main)
    main.recordStarted()
    try {
        context.makeCurrent().use {
            val result = context(main) { block(main) }
            main.recordCompleted()
            return result
        }
    } catch (failure: Throwable) {
        if (findExceptionalThrowable(failure) is CancellationException) main.recordCancelled()
        rethrowExceptional(span, failure)
        val recorded = recordFailure(span, failure, unhandledFailureSlug)
        main.recordFailed(recorded)
        throw recorded
    } finally {
        main.close()
    }
}

/**
 * Runs suspending work inside a main span with context propagated across coroutine suspension.
 *
 * The span closes on success, failure, or cancellation. Ordinary failures are recorded and classified, while
 * cancellation remains cancellation. Receivers are valid only during the block; structured child work must finish
 * before it returns.
 */
suspend fun <T> ServiceTelemetry.mainSpan(
    name: String,
    unhandledFailureSlug: ErrorSlug,
    kind: SpanKind = SpanKind.INTERNAL,
    parent: Context = Context.current(),
    attributes: Attributes = Attributes.empty(),
    presentation: SpanPresentation? = null,
    block: suspend context(MainSpanScope) (MainSpanScope) -> T,
): T {
    val span = start(name, kind, parent, attributes)
    val main = MainScope(this, span, name, presentation)
    val otelContext = installed(parent, span, main)
    main.recordStarted()
    try {
        return withContext(otelContext.asContextElement()) {
            val result = context(main) { block(main) }
            main.recordCompleted()
            result
        }
    } catch (failure: Throwable) {
        if (findExceptionalThrowable(failure) is CancellationException) main.recordCancelled()
        rethrowExceptional(span, failure)
        val recorded = recordFailure(span, failure, unhandledFailureSlug)
        main.recordFailed(recorded)
        throw recorded
    } finally {
        main.close()
    }
}

fun <T> ServiceTelemetry.serverSpanBlocking(
    name: String,
    unhandledFailureSlug: ErrorSlug,
    parent: Context = Context.current(),
    attributes: Attributes = Attributes.empty(),
    block: context(MainSpanScope) (MainSpanScope) -> T,
) = mainSpanBlocking(
    name = name,
    unhandledFailureSlug = unhandledFailureSlug,
    kind = SpanKind.SERVER,
    parent = parent,
    attributes = attributes,
    block = block,
)

/**
 * Creates a main SERVER span for an inbound request.
 *
 * Supply extracted remote context as parent at transport boundaries; lifecycle and failure behavior follow
 * [mainSpan].
 */
suspend fun <T> ServiceTelemetry.serverSpan(
    name: String,
    unhandledFailureSlug: ErrorSlug,
    parent: Context = Context.current(),
    attributes: Attributes = Attributes.empty(),
    block: suspend context(MainSpanScope) (MainSpanScope) -> T,
) = mainSpan(
    name = name,
    unhandledFailureSlug = unhandledFailureSlug,
    kind = SpanKind.SERVER,
    parent = parent,
    attributes = attributes,
    block = block,
)

/**
 * Creates a main CONSUMER span for processing a received message using the supplied parent context.
 */
suspend fun <T> ServiceTelemetry.consumerSpan(
    name: String,
    unhandledFailureSlug: ErrorSlug,
    parent: Context = Context.current(),
    attributes: Attributes = Attributes.empty(),
    block: suspend context(MainSpanScope) (MainSpanScope) -> T,
) = mainSpan(
    name = name,
    unhandledFailureSlug = unhandledFailureSlug,
    kind = SpanKind.CONSUMER,
    parent = parent,
    attributes = attributes,
    block = block,
)

/**
 * Creates a main INTERNAL span for one job execution.
 *
 * A recurring job should create a boundary per execution so failures and durations remain independently
 * observable.
 */
suspend fun <T> ServiceTelemetry.jobSpan(
    name: String,
    unhandledFailureSlug: ErrorSlug,
    parent: Context = Context.current(),
    attributes: Attributes = Attributes.empty(),
    block: suspend context(MainSpanScope) (MainSpanScope) -> T,
) = mainSpan(
    name = name,
    unhandledFailureSlug = unhandledFailureSlug,
    kind = SpanKind.INTERNAL,
    parent = parent,
    attributes = attributes,
    block = block,
)

/**
 * Runs synchronous dependency work beneath an active main scope.
 *
 * The child span closes on every exit. The main scope must originate from this API and remain active for the
 * block.
 */
context(main: MainSpanScope)
fun <T> childSpanBlocking(
    name: String,
    kind: SpanKind = SpanKind.INTERNAL,
    attributes: Attributes = Attributes.empty(),
    block: context(MainSpanScope, ChildSpanScope) (ChildSpanScope) -> T,
): T {
    val parent = Context.current()
    val owner = main as? MainScope ?: error("Main span scope was not created by ServiceTelemetry")
    owner.ensureActive()
    val span = owner.telemetry.start(name, kind, parent, attributes)
    val child = ChildScope(owner.telemetry, span)
    try {
        parent
            .with(span)
            .with(mainScopeKey, main)
            .makeCurrent()
            .use { return context(main, child) { block(child) } }
    } catch (failure: Throwable) {
        rethrowExceptional(span, failure)
        throw recordFailure(span, failure, null)
    } finally {
        child.close()
    }
}

/**
 * Runs a suspending suboperation with coroutine propagated child context.
 *
 * The main scope remains available for operation annotations. Child failures are recorded and propagated without
 * inventing a new fallback error slug.
 */
context(main: MainSpanScope)
suspend fun <T> childSpan(
    name: String,
    kind: SpanKind = SpanKind.INTERNAL,
    attributes: Attributes = Attributes.empty(),
    block: suspend context(MainSpanScope, ChildSpanScope) (ChildSpanScope) -> T,
): T {
    val parent = Context.current()
    val owner = main as? MainScope ?: error("Main span scope was not created by ServiceTelemetry")
    owner.ensureActive()
    val span = owner.telemetry.start(name, kind, parent, attributes)
    val child = ChildScope(owner.telemetry, span)
    val otelContext = parent.with(span).with(mainScopeKey, main)
    try {
        return withContext(otelContext.asContextElement()) { context(main, child) { block(child) } }
    } catch (failure: Throwable) {
        rethrowExceptional(span, failure)
        throw recordFailure(span, failure, null)
    } finally {
        child.close()
    }
}
