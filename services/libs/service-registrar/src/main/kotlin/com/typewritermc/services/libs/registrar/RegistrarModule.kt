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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.runBlocking
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_REGISTRAR_MODULE = module {
    single(named("credential")) { DeferredProvider<Credential>() }
    single(named("messageBus")) { DeferredProvider<MessageBus>() }
    single(named("registrationClient")) { DeferredProvider<RegistrationClient>() }
    single(named("reconnector")) { DeferredProvider<Reconnector>() }
    single { StateProvider<RegistrationState>(RegistrationState.Initializing) }

    single {
        ServiceRegistrar(
            credentialStorage = get(),
            credentialIssuer = get(),
            jwtExchanger = get(),
            communicator = get(),
            credentialProvider = get(named("credential")),
            jwtProviderHolder = get(named("jwtProvider")),
            natsClientProvider = get(named("natsClient")),
            messageBusProvider = get(named("messageBus")),
            registrationClientProvider = get(named("registrationClient")),
            reconnectorProvider = get(named("reconnector")),
            registrationStateProvider = get<StateProvider<RegistrationState>>(),
            coroutineScope = get<CoroutineScope>()
        )
    } onClose { it?.let { registrar -> runBlocking { registrar.shutdown() } } }

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
