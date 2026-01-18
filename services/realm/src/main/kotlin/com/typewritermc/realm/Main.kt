@file:JvmName("RealmMain")

package com.typewritermc.realm

import com.typewritermc.realm.REALM_VERSION
import com.typewritermc.realm.registrar.RealmCredentialStorage
import com.typewritermc.realm.shell.RealmShell
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.communicator.SERVICE_COMMUNICATOR_MODULE
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.registrar.SERVICE_REGISTRAR_MODULE
import com.typewritermc.services.libs.registrar.ServiceInformation
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.ServicesInfo
import com.typewritermc.services.libs.utils.StateProvider
import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.BinaryFormat
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialFormat
import kotlinx.serialization.StringFormat
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.json.Json
import org.koin.core.context.startKoin
import org.koin.core.module.dsl.singleOf
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
        singleOf(::Realm) onClose { it?.shutdown() }
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
    }

    val application = startKoin {
        environmentProperties()
        modules(module, SERVICE_REGISTRAR_MODULE, SERVICE_COMMUNICATOR_MODULE)
    }
    logger.trace { "Koin started" }

    runBlocking {
        application.koin.get<ServiceRegistrar>().initialize()
    }
    Runtime.getRuntime().addShutdownHook(Thread { application.close() })

    val shell = application.koin.get<RealmShell>()
    shell.run()
}