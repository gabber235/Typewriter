package com.typewritermc.services.libs.registrar.koin

import com.typewritermc.services.libs.http.core.HttpTransport
import com.typewritermc.services.libs.http.core.ServiceHttpClient
import com.typewritermc.services.libs.http.jdk.JdkHttpTransport
import com.typewritermc.services.libs.http.jdk.JdkHttpTransportConfiguration
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.IdentityIssuer
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.RegistrarRuntimeFactory
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.runtime.TypewriterIdentityIssuer
import com.typewritermc.services.libs.registrar.runtime.TypewriterRegistrarRuntimeFactory
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import org.koin.core.module.Module
import org.koin.dsl.module

/** Wires registrar adapters while leaving storage, telemetry, scope, and lifecycle application-owned. */
fun registrarModule(
    configuration: RegistrarConfiguration,
    scope: CoroutineScope,
    httpConfiguration: JdkHttpTransportConfiguration = JdkHttpTransportConfiguration(),
): Module = module {
    single { configuration }
    single<HttpTransport> { JdkHttpTransport(httpConfiguration) }
    single { ServiceHttpClient(get(), get(), get<OpenTelemetry>().propagators) }
    single<IdentityIssuer> { TypewriterIdentityIssuer(get(), configuration.identityIssueUri) }
    single<RegistrarRuntimeFactory> {
        TypewriterRegistrarRuntimeFactory(
            configuration,
            get(),
            get<ServiceTelemetry>(),
            get<OpenTelemetry>().propagators,
        )
    }
    single {
        ServiceRegistrar(
            configuration,
            scope,
            get<CredentialStorage>(),
            get<IdentityIssuer>(),
            get<RegistrarRuntimeFactory>(),
            get<ServiceTelemetry>(),
        )
    }
}
