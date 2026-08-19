@file:JvmName("RealmMain")
@file:Suppress("ForbiddenImport")

package com.typewritermc.realm

import ch.qos.logback.classic.Level
import com.typewritermc.realm.registrar.RealmCredentialStorage
import com.typewritermc.realm.routes.RealmEditorCatalogSource
import com.typewritermc.realm.routes.RealmPresentationSearchSource
import com.typewritermc.realm.routes.UnavailableRealmEditorCatalogSource
import com.typewritermc.realm.routes.UnavailableRealmPresentationSearchSource
import com.typewritermc.realm.schema.DatabaseProvider
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.shell.RealmConsoleLogOutput
import com.typewritermc.realm.shell.RealmShell
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.registrar.console.BindingTokenOutput
import com.typewritermc.services.libs.registrar.console.MordantBindingTokenOutput
import com.typewritermc.services.libs.registrar.console.RegistrarConsoleObserver
import com.typewritermc.services.libs.registrar.koin.registrarModule
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SpanPresentation
import com.typewritermc.services.libs.telemetry.console.installOpenTelemetryLogback
import com.typewritermc.services.libs.telemetry.console.installOpenTelemetrySdkDiagnostics
import com.typewritermc.services.libs.telemetry.koin.serviceTelemetryModule
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
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
import org.koin.dsl.bind
import org.koin.dsl.binds
import org.koin.dsl.module
import org.koin.dsl.onClose
import java.nio.file.Paths
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.system.exitProcess
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

@OptIn(ExperimentalSerializationApi::class)
fun main() {
    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val configuration = RealmSettings.system().applicationConfiguration()
    val delayScheduler = CoroutineDelayScheduler
    val timeSource = TimeSource.Monotonic
    val registrarRetryPolicy = RetryPolicy.exponential(1.seconds, 30.seconds, jitterRatio = .2)
    val routeRetryPolicy = RetryPolicy.fixed(1.seconds)
    val consoleOutput = RealmConsoleLogOutput()
    val sdkDiagnostics = installOpenTelemetrySdkDiagnostics(consoleOutput)
    val openTelemetry = realmOpenTelemetry(consoleOutput, configuration.telemetry)
    val logback = installOpenTelemetryLogback(openTelemetry, Level.toLevel(configuration.diagnosticLevel.name, Level.WARN))
    val module =
        module {
            single<OpenTelemetry> { openTelemetry } onClose { it?.let(::closeRealmOpenTelemetry) }
            single { applicationScope } onClose { it?.cancel() }
            single { consoleOutput }

            single { configuration.database }
            single<RealmDatabaseProvider> { DatabaseProvider(get()) }
            single<RealmEditorCatalogSource> { UnavailableRealmEditorCatalogSource() }
            single<RealmPresentationSearchSource> { UnavailableRealmPresentationSearchSource() }
            single { Realm(get(), get(), get(), get(), get(), routeRetryPolicy, delayScheduler) }
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

            single<BindingTokenOutput> { MordantBindingTokenOutput() }
            single { RegistrarConsoleObserver(get()) }
            single { RealmShellContext(get<ServiceRegistrar>().states, timeSource) }
            single { RealmShell(get(), get(), get()) }
        }

    val application =
        startKoin {
            modules(
                module,
                serviceTelemetryModule("com.typewritermc.realm", REALM_VERSION),
                registrarModule(
                    configuration.registrar,
                    applicationScope,
                    retryPolicy = registrarRetryPolicy,
                    delayScheduler = delayScheduler,
                    timeSource = timeSource,
                ),
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
                stopRealm(telemetry, realm, registrar)
            }
        } finally {
            application.close()
        }
    }
    val shutdownHook = Thread { shutdown() }
    Runtime.getRuntime().addShutdownHook(shutdownHook)

    var processFailure: Exception? = null
    try {
        try {
            runBlocking { startRealm(telemetry, registrar, realm) }
            application.koin.get<RealmShell>().run()
        } catch (failure: Exception) {
            processFailure = failure
        }
    } finally {
        runCatching { Runtime.getRuntime().removeShutdownHook(shutdownHook) }
        try {
            shutdown()
        } catch (failure: Exception) {
            processFailure?.addSuppressed(failure) ?: run { processFailure = failure }
        } finally {
            try {
                logback.close()
            } finally {
                sdkDiagnostics.close()
            }
        }
    }
    if (processFailure != null) exitProcess(1)
}

private suspend fun stopRealm(
    telemetry: ServiceTelemetry,
    realm: Realm,
    registrar: ServiceRegistrar,
) = telemetry.mainSpan(
    name = "realm.shutdown",
    unhandledFailureSlug = ErrorSlug.of("realm-shutdown-failed"),
    presentation = SpanPresentation("Realm shutdown"),
) {
    val realmFailure = runCatching { realm.shutdown() }.exceptionOrNull()
    val registrarFailure = runCatching { registrar.stop().requireSuccess("stop") }.exceptionOrNull()
    val primary = realmFailure ?: registrarFailure ?: return@mainSpan
    if (realmFailure != null && registrarFailure != null && registrarFailure !== realmFailure) {
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
    presentation = SpanPresentation("Realm startup"),
) { main ->
    main.annotate {
        attribute("service.version", REALM_VERSION)
        stage("koin") { outcome("ready") }
    }
    main.event(
        name = "workflow.stage.started",
        projection = EventProjection.log(LogSeverity.INFO, "Registering the Realm service"),
    ) {
        attribute("workflow.stage", "registration")
    }
    registrar.start().requireSuccess("start")
    registrar.awaitReady().requireSuccess("await readiness")
    main.annotate { stage("registration") { outcome("ready") } }
    main.event(
        name = "workflow.stage.completed",
        projection = EventProjection.log(LogSeverity.INFO, "Realm registration completed"),
    ) {
        attribute("workflow.stage", "registration")
        attribute("operation.outcome", "completed")
    }
    main.event(
        name = "workflow.stage.started",
        projection = EventProjection.log(LogSeverity.INFO, "Connecting to the Realm database"),
    ) {
        attribute("workflow.stage", "database")
    }
    realm.start(registrar.states, registrar::communicatorFor)
    main.annotate { stage("database") { outcome("ready") } }
    main.event(
        name = "workflow.stage.completed",
        projection = EventProjection.log(LogSeverity.INFO, "Realm database is ready"),
    ) {
        attribute("workflow.stage", "database")
        attribute("operation.outcome", "completed")
    }
}

private fun <T> RegistrarResult<T>.requireSuccess(operation: String): T =
    when (this) {
        is RegistrarResult.Success -> value
        is RegistrarResult.Failure -> error("Registrar $operation failed: $failure")
    }

private fun RegistrarStopResult.requireSuccess(operation: String) {
    if (this is RegistrarStopResult.Failure) error("Registrar $operation failed: $failures")
}
