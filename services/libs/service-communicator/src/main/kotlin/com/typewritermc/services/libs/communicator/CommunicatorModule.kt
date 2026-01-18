package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.communicator.interfaces.SimpleHttpClient
import com.typewritermc.services.libs.utils.DeferredProvider
import io.natskt.api.NatsClient
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_COMMUNICATOR_MODULE = module {
    single { DeferredProvider<NatsClient>() }
    single { DeferredProvider<JwtProvider>() }

    single {
        NatsCommunicator(
            natsUrl = get(named("nats-url")),
            jwtProvider = get(),
            sentinelCredentialsFetcher = get(),
            json = get(),
            natsClientProvider = get()
        )
    } onClose {
        runBlocking {
            it?.disconnect()
        }
    }

    single<HttpClient> { SimpleHttpClient() }

    single { SentinelCredentialsFetcher(get(), get(named("sentinel-url"))) }

    single { Json { ignoreUnknownKeys = true } }

    single(named("nats-url")) {
        getProperty("NATS_URL", "nats://nats.seamlezz.com:4222")
    }

    single(named("api-base-url")) {
        getProperty("API_BASE_URL", "https://api.typewritermc.com")
    }

    single(named("auth-base-url")) {
        getProperty("AUTH_BASE_URL", "https://auth.typewritermc.com")
    }

    single(named("sentinel-url")) {
        val apiBase: String = get(named("api-base-url"))
        "$apiBase/auth/sentinel"
    }
}
