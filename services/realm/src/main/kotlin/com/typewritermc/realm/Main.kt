@file:JvmName("RealmMain")

package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.RealmQualifier.DATABASE
import com.typewritermc.realm.RealmQualifier.DB_DATABASE
import com.typewritermc.realm.RealmQualifier.DB_NAMESPACE
import com.typewritermc.realm.RealmQualifier.DB_PASSWORD
import com.typewritermc.realm.RealmQualifier.DB_URL
import com.typewritermc.realm.RealmQualifier.DB_USERNAME
import com.typewritermc.realm.registrar.RealmCredentialStorage
import com.typewritermc.realm.routes.REALM_ROUTES_MODULE
import com.typewritermc.realm.schema.DatabaseProvider
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.shell.RealmShell
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.registrar.console.BindingTokenOutput
import com.typewritermc.services.libs.registrar.console.MordantBindingTokenOutput
import com.typewritermc.services.libs.registrar.console.RegistrarConsoleObserver
import com.typewritermc.services.libs.registrar.koin.registrarModule
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.koin.serviceTelemetryModule
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.DeferredProvider
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
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
import java.net.URI
import java.nio.file.Paths
import java.util.concurrent.atomic.AtomicBoolean

@OptIn(ExperimentalSerializationApi::class)
fun main() {
    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val openTelemetry = realmOpenTelemetry()
    val registrarConfiguration = realmRegistrarConfiguration()
    val module =
        module {
            single<OpenTelemetry> { openTelemetry } onClose { it?.let(::closeRealmOpenTelemetry) }
            single { applicationScope } onClose { it?.cancel() }

            single(named(DB_URL)) { getProperty("REALM_DB_URL", "ws://localhost:8235") }
            single(named(DB_USERNAME)) { getProperty("REALM_DB_USERNAME", "root") }
            single(named(DB_PASSWORD)) { getProperty("REALM_DB_PASSWORD", "root") }
            single(named(DB_NAMESPACE)) { getProperty("REALM_DB_NAMESPACE", "typewriter") }
            single(named(DB_DATABASE)) { getProperty("REALM_DB_DATABASE", "realm") }
            single<RealmDatabaseProvider> {
                DatabaseProvider(
                    url = get(named(DB_URL)),
                    username = get(named(DB_USERNAME)),
                    password = get(named(DB_PASSWORD)),
                    namespace = get(named(DB_NAMESPACE)),
                    database = get(named(DB_DATABASE)),
                )
            }
            single { Realm(get(named(DATABASE)), get(), get(), get(), get()) }
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
                RealmCredentialStorage(
                    get(),
                    Paths.get(".credential").toFile(),
                    ServiceRole.Realm(REALM_VERSION),
                )
            } bind CredentialStorage::class

            single(named(DATABASE)) {
                DeferredProvider<Surreal>()
            } onClose { it?.getOrNull()?.close() }

            single<BindingTokenOutput> { MordantBindingTokenOutput() }
            single { RegistrarConsoleObserver(get()) }
            single { RealmShellContext(registrarStates = get<ServiceRegistrar>().states) }
            single { RealmShell(get(), get()) }
        }

    val application =
        startKoin {
            environmentProperties()
            modules(
                module,
                serviceTelemetryModule("com.typewritermc.realm", REALM_VERSION),
                registrarModule(registrarConfiguration, applicationScope),
                REALM_ROUTES_MODULE,
            )
        }
    val registrar = application.koin.get<ServiceRegistrar>()
    val realm = application.koin.get<Realm>()
    val telemetry = application.koin.get<ServiceTelemetry>()
    val consoleObserver = application.koin.get<RegistrarConsoleObserver>()
    val consoleObserverJob =
        applicationScope.launch(start = CoroutineStart.UNDISPATCHED) {
            consoleObserver.observe(registrar.states)
        }
    val closed = AtomicBoolean()

    fun shutdown() {
        if (!closed.compareAndSet(false, true)) return
        try {
            runBlocking {
                consoleObserverJob.cancelAndJoin()
                stopRealm(realm, registrar)
            }
        } finally {
            application.close()
        }
    }
    val shutdownHook = Thread { shutdown() }
    Runtime.getRuntime().addShutdownHook(shutdownHook)

    try {
        runBlocking { startRealm(telemetry, registrar, realm) }
        application.koin.get<RealmShell>().run()
    } finally {
        runCatching { Runtime.getRuntime().removeShutdownHook(shutdownHook) }
        shutdown()
    }
}

private suspend fun stopRealm(
    realm: Realm,
    registrar: ServiceRegistrar,
) {
    val routeFailure = runCatching { realm.shutdown() }.exceptionOrNull()
    val registrarFailure = runCatching { registrar.stop().requireSuccess("stop") }.exceptionOrNull()
    val primary = routeFailure ?: registrarFailure ?: return
    if (routeFailure != null && registrarFailure != null && registrarFailure !== routeFailure) {
        primary.addSuppressed(registrarFailure)
    }
    throw primary
}

private suspend fun startRealm(
    telemetry: ServiceTelemetry,
    registrar: ServiceRegistrar,
    realm: Realm,
) = telemetry.mainSpan(
    name = "realm.start",
    unhandledFailureSlug = ErrorSlug.of("realm-start-failed"),
) { main ->
    main.annotate {
        attribute("service.version", REALM_VERSION)
        stage("koin") { outcome("ready") }
    }
    registrar.start().requireSuccess("start")
    registrar.awaitReady().requireSuccess("await readiness")
    main.annotate { stage("registration") { outcome("ready") } }
    realm.start(registrar.states)
    main.annotate { stage("database") { outcome("ready") } }
}

private fun realmRegistrarConfiguration(): RegistrarConfiguration {
    val apiBase = URI(realmSetting("API_BASE_URL", "https://api.typewritermc.com")!!)
    val authBase = URI(realmSetting("AUTH_BASE_URL", "https://auth.typewritermc.com")!!)
    return RegistrarConfiguration(
        identityIssueUri = apiBase.resolve("/service/identity/issue"),
        sentinelCredentialsUri = apiBase.resolve("/auth/sentinel"),
        oauthTokenUri = authBase.resolve("/application/o/token/"),
        oauthClientId = realmSetting("JWT_CLIENT_ID", "typewriter-services")!!,
        oauthScopes =
            realmSetting("JWT_SCOPES", "openid profile entitlements")!!
                .split(' ')
                .filter(String::isNotBlank)
                .toSet(),
        natsServerUri = URI(realmSetting("NATS_URL", "nats://nats.seamlezz.com:4222")!!),
        roles = listOf(ServiceRole.Realm(REALM_VERSION)),
    )
}

private fun <T> RegistrarResult<T>.requireSuccess(operation: String): T =
    when (this) {
        is RegistrarResult.Success -> value
        is RegistrarResult.Failure -> error("Registrar $operation failed: $failure")
    }

private fun RegistrarStopResult.requireSuccess(operation: String) {
    if (this is RegistrarStopResult.Failure) error("Registrar $operation failed: $failures")
}
