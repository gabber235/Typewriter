package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.interfaces.HttpClient
import com.typewritermc.services.libs.communicator.interfaces.SimpleHttpClient
import kotlinx.coroutines.runBlocking
import org.koin.core.module.dsl.singleOf
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_COMMUNICATOR_MODULE = module {
    singleOf(::NatsCommunicator) onClose {
        runBlocking {
            it?.disconnect()
        }
    }

    single<HttpClient> { SimpleHttpClient() }

    single { SentinelCredentialsFetcher(get(), get(named("sentinel-url"))) }

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
