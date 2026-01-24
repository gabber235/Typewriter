package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.CommunicatorQualifier.*
import com.typewritermc.services.libs.communicator.JwtProvider
import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.interfaces.Reconnector
import com.typewritermc.services.libs.communicator.interfaces.RegistrationClient
import com.typewritermc.services.libs.communicator.interfaces.SimpleHttpClient
import com.typewritermc.services.libs.registrar.RegistrarQualifier.*
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.natskt.api.NatsClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.runBlocking
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_REGISTRAR_MODULE = module {
    single(named(CREDENTIAL)) { DeferredProvider<Credential>() }
    single(named(MESSAGE_BUS)) { DeferredProvider<MessageBus>() }
    single(named(REGISTRATION_CLIENT)) { DeferredProvider<RegistrationClient>() }
    single(named(RECONNECTOR)) { DeferredProvider<Reconnector>() }
    single { StateProvider<RegistrationState>(RegistrationState.Initializing) }

    single {
        ServiceRegistrar(
            credentialStorage = get(),
            credentialIssuer = get(),
            jwtExchanger = get(),
            communicator = get(),
            credentialProvider = get(named(CREDENTIAL)),
            jwtProviderHolder = get(named(JWT_PROVIDER)),
            natsClientProvider = get<StateProvider<NatsClient?>>(named(NATS_CLIENT)),
            messageBusProvider = get(named(MESSAGE_BUS)),
            registrationClientProvider = get(named(REGISTRATION_CLIENT)),
            reconnectorProvider = get(named(RECONNECTOR)),
            registrationStateProvider = get<StateProvider<RegistrationState>>(),
            coroutineScope = get<CoroutineScope>()
        )
    } onClose { it?.let { registrar -> runBlocking { registrar.shutdown() } } }

    single<HttpClient> { SimpleHttpClient() }

    single<CredentialIssuer> {
        BackendCredentialIssuer(
            httpClient = get(),
            serviceIssueUrl = get(named(SERVICE_ISSUE_URL)),
            servicesInfo = get()
        )
    }

    single<JwtExchanger> {
        AuthentikJwtExchanger(
            httpClient = get(),
            tokenEndpoint = get(named(JWT_TOKEN_ENDPOINT)),
            clientId = get(named(JWT_CLIENT_ID)),
            scopes = get(named(JWT_SCOPES))
        )
    }

    single(named(SERVICE_ISSUE_URL)) {
        val apiBase: String = get(named(API_BASE_URL))
        "$apiBase/service/identity/issue"
    }

    single(named(JWT_TOKEN_ENDPOINT)) {
        val authBase: String = get(named(AUTH_BASE_URL))
        "$authBase/application/o/token/"
    }
    single(named(JWT_CLIENT_ID)) {
        getProperty("JWT_CLIENT_ID", "typewriter-services")
    }
    single(named(JWT_SCOPES)) {
        getProperty("JWT_SCOPES", "openid profile entitlements")
    }
}
