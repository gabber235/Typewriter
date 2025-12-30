package com.typewritermc.services.libs.communicator

import kotlinx.coroutines.runBlocking
import org.koin.core.module.dsl.singleOf
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

/**
 * Koin module for service-communicator.
 */
val SERVICE_COMMUNICATOR_MODULE = module {
    singleOf(::NatsCommunicator) onClose {
        runBlocking {
            it?.disconnect()
        }
    }

    singleOf(::SentinelCredentialsFetcher)

    single(named("nats-url")) {
        getProperty("NATS_URL", "nats://nats.seamlezz.com:4222")
    }

    single(named("sentinel-url")) {
        getProperty("SENTINEL_URL", "https://api.typewritermc.com/auth/sentinel")
    }
}
