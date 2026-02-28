@file:JvmName("RealmMain")

package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.RealmQualifier.*
import com.typewritermc.realm.registrar.RealmCredentialStorage
import com.typewritermc.realm.routes.REALM_ROUTES_MODULE
import com.typewritermc.realm.routes.NatsDispatcherFactory
import com.typewritermc.realm.schema.DatabaseProvider
import com.typewritermc.realm.shell.RealmShell
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.communicator.SERVICE_COMMUNICATOR_MODULE
import com.typewritermc.services.libs.registrar.*
import com.typewritermc.services.libs.telemetry.SERVICE_TELEMETRY_MODULE
import com.typewritermc.services.libs.telemetry.TelemetryQualifier
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.*
import kotlinx.serialization.BinaryFormat
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialFormat
import kotlinx.serialization.StringFormat
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.json.Json
import org.koin.core.context.startKoin
import org.koin.core.qualifier.named
import org.koin.dsl.bind
import org.koin.dsl.binds
import org.koin.dsl.module
import org.koin.dsl.onClose
import org.koin.environmentProperties
import java.nio.file.Paths

private val logger = KotlinLogging.logger {}

@OptIn(ExperimentalSerializationApi::class)
fun main() {
    logger.info { "Starting Realm" }

    logger.trace { "Starting Koin" }

    val module = module {
        single(named(TelemetryQualifier.SERVICE_NAME)) { "realm" }
        single(named(TelemetryQualifier.SERVICE_VERSION)) { REALM_VERSION }

        single(named(DB_URL)) { getProperty("REALM_DB_URL", "") }
        single(named(DB_USERNAME)) { getProperty("REALM_DB_USERNAME", "") }
        single(named(DB_PASSWORD)) { getProperty("REALM_DB_PASSWORD", "") }
        single(named(DB_NAMESPACE)) { getProperty("REALM_DB_NAMESPACE", "typewriter") }
        single(named(DB_DATABASE)) { getProperty("REALM_DB_DATABASE", "realm") }
        single {
            DatabaseProvider(
                url = get(named(DB_URL)),
                username = get(named(DB_USERNAME)),
                password = get(named(DB_PASSWORD)),
                namespace = get(named(DB_NAMESPACE)),
                database = get(named(DB_DATABASE)),
                tracer = get(),
            )
        }
        single { Realm(get(named(DATABASE)), get(), get()) } onClose { it?.shutdown() }
        single {
            Cbor {
                ignoreUnknownKeys = true
            }
        } binds arrayOf(Cbor::class, BinaryFormat::class, SerialFormat::class)

        single {
            Json {
                ignoreUnknownKeys = true
            }
        } binds arrayOf(Json::class, StringFormat::class, SerialFormat::class)

        single {
            RealmCredentialStorage(get(), Paths.get(".credential").toFile())
        } bind CredentialStorage::class

        single(named(DATABASE)) {
            DeferredProvider<Surreal>()
        } onClose { it?.getOrNull()?.close() }

        single {
            ServicesInfo(
                realm = ServiceInformation.RealmInformation(version = REALM_VERSION)
            )
        }

        single {
            RealmShellContext(
                registrationStateProvider = get<StateProvider<RegistrationState>>()
            )
        }
        single { RealmShell(get()) }

        single {
            CoroutineScope(SupervisorJob() + Dispatchers.Default)
        } onClose {
            it?.cancel()
        }
    }

    val application = startKoin {
        environmentProperties()
        modules(module, SERVICE_TELEMETRY_MODULE, REALM_ROUTES_MODULE, SERVICE_REGISTRAR_MODULE, SERVICE_COMMUNICATOR_MODULE)
    }
    logger.trace { "Koin started" }

    Runtime.getRuntime().addShutdownHook(Thread { application.close() })
    runBlocking {
        application.koin.get<ServiceRegistrar>().initialize()
    }
    application.koin.get<Realm>().initialize()

    val dispatcher = application.koin.get<NatsDispatcherFactory>().create()
    dispatcher.start()

    val shell = application.koin.get<RealmShell>()
    shell.run()
}