@file:JvmName("RealmMain")

package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.RealmQualifier.*
import com.typewritermc.realm.registrar.RealmCredentialStorage
import com.typewritermc.realm.routes.REALM_ROUTES_MODULE
import com.typewritermc.realm.routes.NatsDispatcherFactory
import com.typewritermc.realm.shell.RealmShell
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.communicator.SERVICE_COMMUNICATOR_MODULE
import com.typewritermc.services.libs.registrar.*
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
        single { Realm(get(named(DATABASE))) } onClose { it?.shutdown() }
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
        modules(module, REALM_ROUTES_MODULE, SERVICE_REGISTRAR_MODULE, SERVICE_COMMUNICATOR_MODULE)
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