package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.CommunicatorQualifier.*
import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.communicator.interfaces.SimpleHttpClient
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.natskt.api.NatsClient
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_COMMUNICATOR_MODULE = module {
    single(named(NATS_CLIENT)) { StateProvider<NatsClient?>(null) }
    single(named(JWT_PROVIDER)) { DeferredProvider<JwtProvider>() }

    single {
        NatsCommunicator(
            natsUrl = get(named(NATS_URL)),
            jwtProvider = get(named(JWT_PROVIDER)),
            sentinelCredentialsFetcher = get(),
            json = get(),
            natsClientProvider = get(named(NATS_CLIENT)),
            tracer = get()
        )
    } onClose {
        runBlocking {
            it?.disconnect()
        }
    }

    single<HttpClient> { SimpleHttpClient() }

    single { SentinelCredentialsFetcher(get(), get(named(SENTINEL_URL)), get()) }

    single { Json { ignoreUnknownKeys = true } }

    single(named(NATS_URL)) {
        getProperty("NATS_URL", "nats://nats.seamlezz.com:4222")
    }

    single(named(API_BASE_URL)) {
        getProperty("API_BASE_URL", "https://api.typewritermc.com")
    }

    single(named(AUTH_BASE_URL)) {
        getProperty("AUTH_BASE_URL", "https://auth.typewritermc.com")
    }

    single(named(SENTINEL_URL)) {
        val apiBase: String = get(named(API_BASE_URL))
        "$apiBase/auth/sentinel"
    }
}
