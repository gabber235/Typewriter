package com.typewritermc.services.libs.telemetry.testing

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.childSpan
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.withErrorSlug
import com.typewritermc.services.libs.telemetry.withErrorSlugSuspending

/** Span boundary pairs, blocking and suspending, that follow one failure policy: the failure leaves the main or child span. */
enum class SpanBoundary(
    val label: String,
) {
    BLOCKING("blocking") {
        override suspend fun failMain(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpanBlocking<Unit>("main", fallback) { _ -> throw failure }
        }

        override suspend fun failChild(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            source: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpanBlocking<Unit>("main", fallback) { _ ->
                childSpanBlocking("child") { _ -> withErrorSlug(source) { throw failure } }
            }
        }
    },
    SUSPENDING("suspending") {
        override suspend fun failMain(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpan<Unit>("main", fallback) { _ -> throw failure }
        }

        override suspend fun failChild(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            source: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpan<Unit>("main", fallback) { _ ->
                childSpan("child") { _ -> withErrorSlugSuspending(source) { throw failure } }
            }
        }
    },
    ;

    /** Runs a main span named `main` whose work throws [failure]. */
    abstract suspend fun failMain(
        telemetry: ServiceTelemetry,
        fallback: ErrorSlug,
        failure: Throwable,
    )

    /** Runs a main span `main` with a child span `child` whose work throws [failure] under [source]. */
    abstract suspend fun failChild(
        telemetry: ServiceTelemetry,
        fallback: ErrorSlug,
        source: ErrorSlug,
        failure: Throwable,
    )
}
