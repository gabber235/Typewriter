package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.JwtProvider
import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.communicator.interfaces.SimpleHttpClient
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.natskt.api.NatsClient
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_REGISTRAR_MODULE = module {
    single { DeferredProvider<Credential>() }
    single { DeferredProvider<MessageBus>() }
    single { DeferredProvider<RegistrationClient>() }
    single { DeferredProvider<Reconnector>() }
    single { StateProvider<RegistrationState>(RegistrationState.Initializing) }

    single {
        ServiceRegistrar(
            credentialStorage = get(),
            credentialIssuer = get(),
            jwtExchanger = get(),
            communicator = get(),
            credentialProvider = get<DeferredProvider<Credential>>(),
            jwtProviderHolder = get<DeferredProvider<JwtProvider>>(),
            natsClientProvider = get<DeferredProvider<NatsClient>>(),
            messageBusProvider = get<DeferredProvider<MessageBus>>(),
            registrationClientProvider = get<DeferredProvider<RegistrationClient>>(),
            reconnectorProvider = get<DeferredProvider<Reconnector>>(),
            registrationStateProvider = get<StateProvider<RegistrationState>>()
        )
    } onClose { it?.shutdown() }

    single<HttpClient> { SimpleHttpClient() }

    single<CredentialIssuer> {
        BackendCredentialIssuer(
            httpClient = get(),
            serviceIssueUrl = get(named("service-issue-url")),
            servicesInfo = get()
        )
    }

    single<JwtExchanger> {
        AuthentikJwtExchanger(
            httpClient = get(),
            tokenEndpoint = get(named("jwt-token-endpoint")),
            clientId = get(named("jwt-client-id")),
            scopes = get(named("jwt-scopes"))
        )
    }

    single(named("service-issue-url")) {
        val apiBase: String = get(named("api-base-url"))
        "$apiBase/service/identity/issue"
    }

    single(named("jwt-token-endpoint")) {
        val authBase: String = get(named("auth-base-url"))
        "$authBase/application/o/token/"
    }
    single(named("jwt-client-id")) {
        getProperty("JWT_CLIENT_ID", "typewriter-services")
    }
    single(named("jwt-scopes")) {
        getProperty("JWT_SCOPES", "openid profile entitlements")
    }
}
