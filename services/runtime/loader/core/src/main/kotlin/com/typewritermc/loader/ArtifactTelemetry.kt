package com.typewritermc.loader

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import io.opentelemetry.api.common.Attributes

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
