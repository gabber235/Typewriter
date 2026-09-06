package com.typewritermc.loader

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import io.opentelemetry.api.common.Attributes

/**
 * Optional telemetry boundary for artifact operations used both inside a running loader and by isolated callers.
 * Without telemetry, executes the block with a null span. Otherwise delegates failure recording and context
 * ownership to mainSpan using the supplied stable failure slug.
 */
internal suspend fun <Value> ServiceTelemetry?.artifactSpan(
    name: String,
    failureSlug: String,
    attributes: Attributes = Attributes.empty(),
    block: suspend (MainSpanScope?) -> Value,
): Value =
    if (this == null) {
        block(null)
    } else {
        mainSpan(
            name,
            ErrorSlug.of(failureSlug),
            attributes = attributes,
        ) { main -> block(main) }
    }
