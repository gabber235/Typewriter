package com.typewritermc.services.libs.telemetry.koin

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.InMemoryTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import org.koin.dsl.koinApplication
import org.koin.dsl.module

val TelemetryKoinModuleTest by testSuite {
    test("instrumentation metadata reaches spans") {
        InMemoryTelemetry().use { sdk ->
            val app =
                koinApplication {
                    modules(
                        module { single<OpenTelemetry> { sdk.openTelemetry } },
                        serviceTelemetryModule("realm.instrumentation", "2.1.0", "https://schema.example/v1"),
                    )
                }
            try {
                app.koin.get<ServiceTelemetry>().mainSpanBlocking("main", ErrorSlug.of("main-failed")) { _ -> }
                val scope = sdk.spans().single().instrumentationScopeInfo
                scope.name shouldBe "realm.instrumentation"
                scope.version shouldBe "2.1.0"
                scope.schemaUrl shouldBe "https://schema.example/v1"
            } finally {
                app.close()
            }
        }
    }

    test("closing Koin does not shut down application SDK") {
        InMemoryTelemetry().use { sdk ->
            val app =
                koinApplication {
                    modules(module { single<OpenTelemetry> { sdk.openTelemetry } }, serviceTelemetryModule("realm"))
                }
            app.koin.get<ServiceTelemetry>()
            app.close()

            sdk.openTelemetry
                .getTracer("after-koin")
                .spanBuilder("still-works")
                .startSpan()
                .end()
            sdk.spans().single().name shouldBe "still-works"
        }
    }
}
