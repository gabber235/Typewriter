@file:Suppress("ForbiddenImport")

package com.typewritermc.realm

import ch.qos.logback.classic.Level
import com.typewritermc.loader.DeploymentContext
import com.typewritermc.realm.deployment.CompatibleNoOperationCheckpoint
import com.typewritermc.realm.deployment.ManagedRealmRuntime
import com.typewritermc.realm.deployment.RealmRuntimeFactory
import com.typewritermc.realm.deployment.RealmUpgradeCheckpoint
import com.typewritermc.realm.routes.RealmEditorCatalogSource
import com.typewritermc.realm.routes.RealmElementCatalogSource
import com.typewritermc.realm.routes.RealmPresentationSearchSource
import com.typewritermc.realm.routes.SnapshotRealmEditorCatalogSource
import com.typewritermc.realm.routes.SnapshotRealmElementCatalogSource
import com.typewritermc.realm.routes.UnavailableRealmPresentationSearchSource
import com.typewritermc.realm.schema.DatabaseEndpoint
import com.typewritermc.realm.schema.DatabaseProvider
import com.typewritermc.realm.schema.RealmDatabaseConfiguration
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SpanPresentation
import com.typewritermc.services.libs.telemetry.console.installOpenTelemetryLogback
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.core.KoinApplication
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose
import java.nio.file.Path
import java.time.Clock
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration.Companion.seconds

/** Creates the complete Realm lifecycle exclusively for a loader managed deployment. */
class DefaultRealmRuntimeFactory : RealmRuntimeFactory {
    override suspend fun start(context: DeploymentContext): ManagedRealmRuntime {
        val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val configuration = RealmSettings.system().applicationConfiguration().resolveAgainst(context.workDirectory)
        val delayScheduler = CoroutineDelayScheduler
        val clock = Clock.systemUTC()
        val routeRetryPolicy = RetryPolicy.fixed(1.seconds)
        val logback =
            installOpenTelemetryLogback(
                context.service.openTelemetry,
                Level.toLevel(configuration.diagnosticLevel.name, Level.WARN),
            )
        val realmModule =
            module {
                single<OpenTelemetry> { context.service.openTelemetry }
                single { context.service.telemetry }
                single { applicationScope } onClose { it?.cancel() }
                single { configuration.database }
                single<RealmDatabaseProvider> { DatabaseProvider(get()) }
                single { RealmDiscoverySnapshotStore() }
                single<RealmEditorCatalogSource> { SnapshotRealmEditorCatalogSource { get<RealmDiscoverySnapshotStore>().discovery() } }
                single<RealmElementCatalogSource> { SnapshotRealmElementCatalogSource { get<RealmDiscoverySnapshotStore>().elements() } }
                single<RealmPresentationSearchSource> { UnavailableRealmPresentationSearchSource() }
                single { RealmCatalogInvalidationProcess(get(), get(), get()) }
                single { Realm(get(), get(), get(), get(), get(), get(), routeRetryPolicy, delayScheduler, clock, get()) }
            }

        val application =
            koinApplication {
                modules(
                    realmModule,
                )
            }
        val realm = application.koin.get<Realm>()
        val telemetry = application.koin.get<ServiceTelemetry>()
        val runtime =
            DefaultManagedRealmRuntime(
                application,
                telemetry,
                realm,
                logback,
            )

        try {
            startRealm(telemetry, realm, context)
            return runtime
        } catch (failure: Throwable) {
            runCatching { runtime.stop() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}

private class DefaultManagedRealmRuntime(
    private val application: KoinApplication,
    private val telemetry: ServiceTelemetry,
    private val realm: Realm,
    private val logback: AutoCloseable,
) : ManagedRealmRuntime {
    private val closed = AtomicBoolean()

    override suspend fun prepareUpgradeCheckpoint(): RealmUpgradeCheckpoint = CompatibleNoOperationCheckpoint

    override suspend fun stop() {
        if (!closed.compareAndSet(false, true)) return
        try {
            stopRealm(telemetry, realm)
        } finally {
            try {
                application.close()
            } finally {
                logback.close()
            }
        }
    }
}

private fun RealmApplicationConfiguration.resolveAgainst(workDirectory: Path): RealmApplicationConfiguration =
    copy(database = database.resolveAgainst(workDirectory))

private fun RealmDatabaseConfiguration.resolveAgainst(workDirectory: Path): RealmDatabaseConfiguration =
    copy(
        endpoint =
            when (val configured = endpoint) {
                is DatabaseEndpoint.Embedded.SurrealKv -> {
                    configured.copy(path = configured.path.resolveAgainst(workDirectory))
                }

                is DatabaseEndpoint.Embedded.RocksDb -> {
                    configured.copy(path = configured.path.resolveAgainst(workDirectory))
                }

                is DatabaseEndpoint.Embedded.Memory,
                is DatabaseEndpoint.Remote,
                -> {
                    configured
                }
            },
    )

private fun Path.resolveAgainst(workDirectory: Path): Path = if (isAbsolute) normalize() else workDirectory.resolve(this).normalize()

private suspend fun stopRealm(
    telemetry: ServiceTelemetry,
    realm: Realm,
) = telemetry.mainSpan(
    name = "realm.shutdown",
    unhandledFailureSlug = ErrorSlug.of("realm-shutdown-failed"),
    presentation = SpanPresentation("Realm shutdown"),
) {
    realm.shutdown()
}

private suspend fun startRealm(
    telemetry: ServiceTelemetry,
    realm: Realm,
    context: DeploymentContext,
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
        projection = EventProjection.log(LogSeverity.INFO, "Connecting to the Realm database"),
    ) {
        attribute("workflow.stage", "database")
    }
    realm.start(context.child.instanceId, context.service.states, context.service::communicatorFor)
    main.annotate { stage("database") { outcome("ready") } }
    main.event(
        name = "workflow.stage.completed",
        projection = EventProjection.log(LogSeverity.INFO, "Realm database is ready"),
    ) {
        attribute("workflow.stage", "database")
        attribute("operation.outcome", "completed")
    }
}
