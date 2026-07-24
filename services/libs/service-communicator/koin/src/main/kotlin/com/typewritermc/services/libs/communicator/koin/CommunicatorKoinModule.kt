package com.typewritermc.services.libs.communicator.koin

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.nats.NatsAuthenticationProvider
import com.typewritermc.services.libs.communicator.nats.NatsConfigurationProvider
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.router.RouterOptions
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.api.OpenTelemetry
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * Wires the typed communicator to core NATS using application-owned telemetry and provider bindings.
 *
 * The application must bind [OpenTelemetry], [ServiceTelemetry], [NatsConfigurationProvider], and
 * [NatsAuthenticationProvider]. Connection and router lifecycle remain application-owned.
 */
fun communicatorModule(routerOptions: RouterOptions = RouterOptions()): Module = module {
    single { routerOptions }
    single { NatsConnection(get(), get()) }
    single<MessageTransport> { NatsMessageTransport(get()) }
    single { Communicator(get(), get(), get<OpenTelemetry>().propagators) }
}
