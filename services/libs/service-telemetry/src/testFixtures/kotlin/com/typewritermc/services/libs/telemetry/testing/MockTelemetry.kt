package com.typewritermc.services.libs.telemetry.testing

import io.mockk.every
import io.mockk.mockk
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.SpanBuilder
import io.opentelemetry.api.trace.Tracer

object MockTelemetry {

    fun createMockTracer(): Tracer {
        val mockTracer = mockk<Tracer>(relaxed = true)
        every { mockTracer.spanBuilder(any()) } answers {
            createMockSpanBuilder()
        }
        return mockTracer
    }

    fun createMockSpanBuilder(): SpanBuilder {
        val mockSpan = createMockSpan()
        val mockSpanBuilder = mockk<SpanBuilder>(relaxed = true)
        every { mockSpanBuilder.setSpanKind(any()) } returns mockSpanBuilder
        every { mockSpanBuilder.setParent(any()) } returns mockSpanBuilder
        every { mockSpanBuilder.setAttribute(any<String>(), any<String>()) } returns mockSpanBuilder
        every { mockSpanBuilder.setAttribute(any<String>(), any<Long>()) } returns mockSpanBuilder
        every { mockSpanBuilder.setAttribute(any<String>(), any<Double>()) } returns mockSpanBuilder
        every { mockSpanBuilder.setAttribute(any<String>(), any<Boolean>()) } returns mockSpanBuilder
        every { mockSpanBuilder.startSpan() } returns mockSpan
        return mockSpanBuilder
    }

    fun createMockSpan(): Span {
        return mockk<Span>(relaxed = true)
    }
}
