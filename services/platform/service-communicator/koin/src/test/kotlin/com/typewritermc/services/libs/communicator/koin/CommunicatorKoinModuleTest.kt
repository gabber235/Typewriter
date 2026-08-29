package com.typewritermc.services.libs.communicator.koin

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsAuthenticationProvider
import com.typewritermc.services.libs.communicator.nats.NatsConfigurationProvider
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.router.RouterOptions
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.opentelemetry.api.OpenTelemetry
import org.koin.dsl.koinApplication
import org.koin.dsl.module

val CommunicatorKoinModuleTest by testSuite {
    test("resolves exact singleton wiring from mandatory application bindings") {
        val options = RouterOptions(maxInFlight = 7)
        val app = application(options)
        try {
            app.koin.get<NatsConnection>() shouldBeSameInstanceAs app.koin.get<NatsConnection>()
            app.koin.get<MessageTransport>().shouldBeInstanceOf<NatsMessageTransport>()
            app.koin.get<Communicator>() shouldBeSameInstanceAs app.koin.get<Communicator>()
            app.koin.get<RouterOptions>() shouldBeSameInstanceAs options
        } finally {
            app.close()
        }
    }

    listOf(
        "OpenTelemetry",
        "ServiceTelemetry",
        "configuration provider",
        "authentication provider",
    ).forEach { missing ->
        test("missing $missing fails resolution") {
            val telemetry = OpenTelemetry.noop()
            val dependencies =
                module {
                    if (missing != "OpenTelemetry") single<OpenTelemetry> { telemetry }
                    if (missing != "ServiceTelemetry") single { telemetry.serviceTelemetry("test") }
                    if (missing != "configuration provider") {
                        single<NatsConfigurationProvider> {
                            NatsConfigurationProvider { NatsConnectionConfiguration("nats://localhost:4222") }
                        }
                    }
                    if (missing != "authentication provider") {
                        single<NatsAuthenticationProvider> {
                            NatsAuthenticationProvider { NatsAuthentication() }
                        }
                    }
                }
            val app = koinApplication { modules(dependencies, communicatorModule()) }
            try {
                shouldThrowAny { app.koin.get<Communicator>() }
            } finally {
                app.close()
            }
        }
    }

    test("closing Koin does not invoke application providers") {
        var configurationInvocations = 0
        var authenticationInvocations = 0
        val configurationProvider =
            NatsConfigurationProvider {
                configurationInvocations++
                NatsConnectionConfiguration("nats://localhost:4222")
            }
        val authenticationProvider =
            NatsAuthenticationProvider {
                authenticationInvocations++
                NatsAuthentication()
            }
        val telemetry = OpenTelemetry.noop()
        val app =
            koinApplication {
                modules(
                    module {
                        single<OpenTelemetry> { telemetry }
                        single<ServiceTelemetry> { telemetry.serviceTelemetry("test") }
                        single { configurationProvider }
                        single { authenticationProvider }
                    },
                    communicatorModule(),
                )
            }

        app.koin.get<Communicator>()
        app.close()

        configurationInvocations shouldBe 0
        authenticationInvocations shouldBe 0
    }
}

private fun application(options: RouterOptions = RouterOptions()) =
    koinApplication {
        val telemetry = OpenTelemetry.noop()
        modules(
            module {
                single<OpenTelemetry> { telemetry }
                single<ServiceTelemetry> { telemetry.serviceTelemetry("test") }
                single<NatsConfigurationProvider> {
                    NatsConfigurationProvider { NatsConnectionConfiguration("nats://localhost:4222") }
                }
                single<NatsAuthenticationProvider> { NatsAuthenticationProvider { NatsAuthentication() } }
            },
            communicatorModule(options),
        )
    }
