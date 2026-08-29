package com.typewritermc.services.libs.telemetry.testing

import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.sdk.trace.data.EventData
import io.opentelemetry.sdk.trace.data.SpanData
import java.time.Duration

class SpanAssertions(
    private val spans: List<SpanData>,
) {
    fun count(expected: Int) = assertThat(spans.size == expected) { "Expected $expected spans, found ${spans.size}" }

    fun roots(expected: Int) {
        val roots = spans.count { candidate -> spans.none { it.traceId == candidate.traceId && it.spanId == candidate.parentSpanId } }
        assertThat(roots == expected) { "Expected $expected locally collected root spans, found $roots" }
    }

    fun main(
        name: String,
        block: SpanAssertion.() -> Unit = {},
    ) {
        val matches =
            spans.filter { candidate ->
                candidate.name == name &&
                    spans.none { it.traceId == candidate.traceId && it.spanId == candidate.parentSpanId }
            }
        assertThat(matches.size == 1) { "Expected exactly one locally collected main span '$name', found ${matches.size}" }
        SpanAssertion(matches.single(), spans).block()
    }

    fun span(
        name: String,
        block: SpanAssertion.() -> Unit = {},
    ) {
        val matches = spans.filter { it.name == name }
        assertThat(matches.size == 1) { "Expected exactly one span '$name', found ${matches.size}" }
        SpanAssertion(matches.single(), spans).block()
    }
}

class SpanAssertion(
    private val span: SpanData,
    private val all: List<SpanData>,
) {
    fun kind(expected: SpanKind) = assertThat(span.kind == expected) { "Expected kind $expected, found ${span.kind}" }

    fun status(expected: StatusCode) =
        assertThat(span.status.statusCode == expected) {
            "Expected status $expected, found ${span.status.statusCode}"
        }

    fun statusDescription(expected: String) =
        assertThat(span.status.description == expected) {
            "Expected status description '$expected', found '${span.status.description}'"
        }

    fun durationAtLeast(expected: Duration) =
        assertThat(span.endEpochNanos - span.startEpochNanos >= expected.toNanos()) {
            "Expected duration >= $expected"
        }

    fun traceId(expected: String) = assertThat(span.traceId == expected) { "Expected trace ID $expected, found ${span.traceId}" }

    fun parentSpanId(expected: String) =
        assertThat(span.parentSpanId == expected) {
            "Expected parent span ID $expected, found ${span.parentSpanId}"
        }

    fun isRoot() =
        assertThat(
            all.none {
                it.traceId == span.traceId && it.spanId == span.parentSpanId
            },
        ) { "Expected '${span.name}' to be a locally collected root span" }

    fun attribute(
        key: String,
        expected: String,
    ) = value(AttributeKey.stringKey(key), expected)

    fun attribute(
        key: String,
        expected: Long,
    ) = value(AttributeKey.longKey(key), expected)

    fun attribute(
        key: String,
        expected: Double,
    ) = value(AttributeKey.doubleKey(key), expected)

    fun attribute(
        key: String,
        expected: Boolean,
    ) = value(AttributeKey.booleanKey(key), expected)

    fun absent(key: String) =
        assertThat(
            span.attributes
                .asMap()
                .keys
                .none { it.key == key },
        ) { "Unexpected attribute '$key'" }

    fun event(
        name: String,
        block: EventAssertion.() -> Unit = {},
    ) {
        val matches = span.events.filter { it.name == name }
        assertThat(matches.size == 1) { "Expected exactly one event '$name', found ${matches.size}" }
        EventAssertion(matches.single()).block()
    }

    fun recordedException(block: EventAssertion.() -> Unit = {}) = event("exception", block)

    fun exceptionSlug(expected: String) = attribute("exception.slug", expected)

    fun child(
        name: String,
        block: SpanAssertion.() -> Unit = {},
    ) {
        val matches = children().filter { it.name == name }
        assertThat(matches.size == 1) { "Expected one child '$name', found ${matches.size}" }
        SpanAssertion(matches.single(), all).block()
    }

    fun childCount(expected: Int) {
        val actual = children().size
        assertThat(actual == expected) { "Expected $expected children, found $actual" }
    }

    fun noSensitiveAttributes(vararg fragments: String) {
        val entries = span.attributes.asMap().entries
        val hit =
            entries.firstOrNull { (key, value) ->
                fragments.any { fragment ->
                    key.key.contains(fragment, ignoreCase = true) || value.toString().contains(fragment, ignoreCase = true)
                }
            }
        assertThat(hit == null) { "Sensitive attribute found: $hit" }
    }

    private fun children() = all.filter { it.parentSpanId == span.spanId && it.traceId == span.traceId }

    private fun <T> value(
        key: AttributeKey<T>,
        expected: T,
    ) = assertThat(span.attributes[key] == expected) {
        "Expected $key=$expected, found ${span.attributes[key]}"
    }
}

class EventAssertion(
    private val event: EventData,
) {
    fun attribute(
        key: String,
        expected: String,
    ) = value(AttributeKey.stringKey(key), expected)

    fun attribute(
        key: String,
        expected: Long,
    ) = value(AttributeKey.longKey(key), expected)

    fun attribute(
        key: String,
        expected: Boolean,
    ) = value(AttributeKey.booleanKey(key), expected)

    fun absent(key: String) =
        assertThat(
            event.attributes
                .asMap()
                .keys
                .none { it.key == key },
        ) { "Unexpected event attribute '$key'" }

    private fun <T> value(
        key: AttributeKey<T>,
        expected: T,
    ) = assertThat(event.attributes[key] == expected) {
        "Expected event $key=$expected, found ${event.attributes[key]}"
    }
}

private inline fun assertThat(
    value: Boolean,
    message: () -> String,
) {
    if (!value) throw AssertionError(message())
}
