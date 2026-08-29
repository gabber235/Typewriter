package com.typewritermc.services.libs.telemetry.koin

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.testing.exporter.InMemorySpanExporter
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor
import org.koin.dsl.koinApplication
import org.koin.dsl.module

val TelemetryKoinModuleTest by testSuite {
    test("module resolves one singleton from application-owned OpenTelemetry") {
        sdkFixture { sdk, _ ->
            val app =
                koinApplication {
                    modules(module { single<OpenTelemetry> { sdk } }, serviceTelemetryModule("realm", "2.0.0"))
                }
            try {
                app.koin.get<ServiceTelemetry>() shouldBeSameInstanceAs app.koin.get<ServiceTelemetry>()
            } finally {
                app.close()
            }
        }
    }

    test("missing OpenTelemetry binding fails at resolution") {
        val app = koinApplication { modules(serviceTelemetryModule("realm")) }
        try {
            shouldThrowAny { app.koin.get<ServiceTelemetry>() }
        } finally {
            app.close()
        }
    }

    test("instrumentation metadata reaches spans") {
        sdkFixture { sdk, exporter ->
            val app =
                koinApplication {
                    modules(
                        module { single<OpenTelemetry> { sdk } },
                        serviceTelemetryModule("realm.instrumentation", "2.1.0", "https://schema.example/v1"),
                    )
                }
            try {
                app.koin.get<ServiceTelemetry>().mainSpanBlocking("main", ErrorSlug.of("main-failed")) { _ -> }
                val scope = exporter.finishedSpanItems.single().instrumentationScopeInfo
                scope.name shouldBe "realm.instrumentation"
                scope.version shouldBe "2.1.0"
                scope.schemaUrl shouldBe "https://schema.example/v1"
            } finally {
                app.close()
            }
        }
    }

    test("closing Koin does not shut down application SDK") {
        sdkFixture { sdk, exporter ->
            val app =
                koinApplication {
                    modules(module { single<OpenTelemetry> { sdk } }, serviceTelemetryModule("realm"))
                }
            app.koin.get<ServiceTelemetry>()
            app.close()

            sdk
                .getTracer("after-koin")
                .spanBuilder("still-works")
                .startSpan()
                .end()
            exporter.finishedSpanItems.single().name shouldBe "still-works"
        }
    }
}

private fun sdkFixture(block: (OpenTelemetrySdk, InMemorySpanExporter) -> Unit) {
    val exporter = InMemorySpanExporter.create()
    val provider =
        SdkTracerProvider
            .builder()
            .addSpanProcessor(SimpleSpanProcessor.create(exporter))
            .build()
    val sdk = OpenTelemetrySdk.builder().setTracerProvider(provider).build()
    try {
        block(sdk, exporter)
    } finally {
        provider.shutdown().join(10, java.util.concurrent.TimeUnit.SECONDS)
    }
}
