@file:Suppress("ForbiddenImport")

package com.typewritermc.realm

import ch.qos.logback.classic.Level
import com.typewritermc.authoring.Placement
import com.typewritermc.capability.RealmCapabilityProvider
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.discovery.CatalogGeneration
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.SourcePartCatalogEntry
import com.typewritermc.discovery.runtime.DiscoveryArtifactPackage
import com.typewritermc.discovery.runtime.DiscoveryDeployment
import com.typewritermc.discovery.runtime.DiscoveryModuleLoader
import com.typewritermc.elements.Element
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.library.Tag
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.pages.PageCatalogAssembler
import com.typewritermc.pages.PageProvider
import com.typewritermc.presentation.PresentationCatalogAssembler
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.realm.deployment.ManagedRealmRuntime
import com.typewritermc.realm.deployment.RealmRuntimeFactory
import com.typewritermc.realm.routes.CapabilityRealmPresentationSearchSource
import com.typewritermc.realm.routes.RealmCapabilityInvocationSource
import com.typewritermc.realm.routes.RealmEditorCatalogSource
import com.typewritermc.realm.routes.RealmPresentationSearchSource
import com.typewritermc.realm.routes.SnapshotRealmEditorCatalogSource
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
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.core.KoinApplication
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose
import skirout.editor.v1.catalog.AuthoringCompilationProjectionDefinition
import skirout.editor.v1.compiled_content.CompilationProjectionId
import java.nio.file.Path
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration.Companion.seconds

/**
 * Stages the Realm composition from loader supplied artifacts, directories, facts, and host services.
 *
 * It assembles discovery, page and presentation catalogs, capabilities, and isolated application resources.
 * Activation starts Realm storage and routes; quiescing retains the staged deployment for resume. Construction
 * failure releases resources already acquired.
 */
class DefaultRealmRuntimeFactory : RealmRuntimeFactory {
    /**
     * Reads the deployment package once, builds all Realm catalogs, and returns an inactive runtime.
     *
     * Discovery and catalog assembly happen before storage or messaging activation. Koin owns the assembled
     * resources after success; construction failure closes the application, discovery deployment, logging bridge,
     * and application scope acquired during staging.
     */
    override suspend fun stage(context: HostedDeploymentContext): ManagedRealmRuntime {
        val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        var logback: AutoCloseable? = null
        var discovery: DiscoveryDeployment? = null
        var application: KoinApplication? = null
        try {
            val configuration = RealmSettings.system().applicationConfiguration().resolveAgainst(context.directories.state)
            val delayScheduler = CoroutineDelayScheduler
            val routeRetryPolicy = RetryPolicy.fixed(1.seconds)
            logback =
                installOpenTelemetryLogback(
                    context.host.openTelemetry,
                    Level.toLevel(configuration.diagnosticLevel.name, Level.WARN),
                )
            val catalogArtifacts =
                (
                    listOf(context.artifacts.runtimeArtifact) +
                        context.artifacts.catalogArtifacts +
                        context.artifacts.extensions.map { HostedArtifact(it.path, it.manifest) }
                ).distinctBy { it.path }
            val catalogPaths = catalogArtifacts.map { it.path }
            val manifests = catalogArtifacts.map { it.manifest }
            val sourceParts =
                context.artifacts.extensions.flatMap { extension ->
                    extension.sourceParts.map { sourcePart ->
                        SourcePartCatalogEntry(
                            extension.id,
                            sourcePart.name,
                            when (val disposition = sourcePart.disposition) {
                                is SourcePartDisposition.Eligible -> Eligibility.Eligible
                                is SourcePartDisposition.Ineligible -> Eligibility.Ineligible(disposition.reasons)
                            },
                        )
                    }
                }
            val assembled =
                DeploymentCatalogAssembler.assemble(
                    generation =
                        CatalogGeneration(
                            context.directories.deployment.fileName
                                .toString(),
                        ),
                    engines = manifests.filterIsInstance<EngineManifest>(),
                    extensions = manifests.filterIsInstance<ExtensionManifest>(),
                    sourceParts = sourceParts,
                    facts = DeploymentFacts(context.facts),
                    otherManifests = manifests.filterNot { it is EngineManifest || it is ExtensionManifest },
                )
            val loadedDiscovery =
                DiscoveryModuleLoader().load(
                    DiscoveryArtifactPackage(
                        artifacts = catalogPaths.map { it.toUri().toURL() },
                        selectedEngine = null,
                        selectedExtensions = context.artifacts.extensions.mapTo(mutableSetOf()) { it.id },
                        facts = DeploymentFacts(context.facts),
                    ),
                    DiscoveryDomains.Realm,
                    assembled.runtimeDiscovery,
                    requireNotNull(javaClass.classLoader),
                )
            discovery = loadedDiscovery
            val capabilityRegistry =
                RealmCapabilityRegistry(
                    providers = loadedDiscovery.application.koin.getAll<RealmCapabilityProvider>(),
                    prototypes = loadedDiscovery.prototypes,
                )
            val presentationCatalog =
                PresentationCatalogAssembler.assemble(
                    providers =
                        coreLibraryPresentationProviders() +
                            loadedDiscovery.application.koin.getAll<PresentationProvider>(),
                    prototypes = loadedDiscovery.prototypes,
                    types = assembled.discovery.types,
                    capabilities = capabilityRegistry.descriptors,
                )
            val pageCatalog =
                PageCatalogAssembler.assemble(
                    providers = loadedDiscovery.application.koin.getAll<PageProvider>(),
                    prototypes = loadedDiscovery.prototypes,
                )
            val authoringPolicies =
                RealmAuthoringPolicyAssembler.assemble(
                    providers =
                        listOf(
                            CoreAuthoringPolicyProvider(
                                prototypes = loadedDiscovery.prototypes,
                                pageCatalog = pageCatalog,
                                elements = assembled.elements,
                                types = assembled.discovery.types,
                                catalogRevision = { assembled.discovery.generation.value },
                            ),
                        ) + loadedDiscovery.application.koin.getAll<com.typewritermc.authoring.AuthoringPolicyProvider>(),
                    catalog = assembled.discovery.types,
                )
            val realmModule =
                module {
                    single<OpenTelemetry> { context.host.openTelemetry }
                    single { context.host }
                    single<ServiceTelemetry> { context.host.openTelemetry.serviceTelemetry("realm", REALM_VERSION) }
                    single { applicationScope } onClose { it?.cancel() }
                    single { configuration.database }
                    single<RealmDatabaseProvider> { DatabaseProvider(get()) }
                    single { RealmDiscoverySnapshotStore() }
                    single { loadedDiscovery.prototypes }
                    single { capabilityRegistry }
                    single { pageCatalog }
                    single { authoringPolicies }
                    single<RealmEditorCatalogSource> {
                        SnapshotRealmEditorCatalogSource(get()) { get<RealmDiscoverySnapshotStore>().current() }
                    }
                    single<RealmPresentationSearchSource> {
                        CapabilityRealmPresentationSearchSource(get(), get(), get(), get())
                    }
                    single { RealmCapabilityInvocationSource(get(), get(), get()) }
                    single { RealmCatalogInvalidationProcess(get(), get(), get()) }
                    single {
                        Realm(
                            get(),
                            get(),
                            get(),
                            get(),
                            get(),
                            routeRetryPolicy,
                            delayScheduler,
                            get(),
                            get(),
                            get(),
                            get(),
                            capabilityInvocations = get(),
                            authoringPolicies = get(),
                        )
                    }
                }

            val startedApplication =
                koinApplication {
                    modules(
                        realmModule,
                    )
                }
            application = startedApplication
            val realm = startedApplication.koin.get<Realm>()
            startedApplication.koin.get<RealmDiscoverySnapshotStore>().replace(
                RealmDiscoverySnapshot(
                    discovery = assembled.discovery.copy(types = presentationCatalog.types),
                    resourceDefinitions = authoringPolicies.definitions,
                    relations = assembled.runtimeDiscovery.relations,
                    collectionProjections = coreLibraryCollectionProjections(loadedDiscovery.prototypes),
                    creationSlots = authoringPolicies.creationSlots,
                    authoringSearch = authoringPolicies.searchDefinition(),
                    compilationProjections =
                        authoringPolicies.compilation.projections.map { projection ->
                            AuthoringCompilationProjectionDefinition(
                                projection = CompilationProjectionId(value = projection.id.value),
                                root = SkirTypeCodec.encode(projection.root).getOrThrow(),
                            )
                        },
                    elements = assembled.elements,
                    pages = pageCatalog,
                    presentations = presentationCatalog.definitions,
                    capabilities = capabilityRegistry.descriptors,
                    presentationDiagnostics = presentationCatalog.diagnostics,
                ),
            )
            val telemetry = startedApplication.koin.get<ServiceTelemetry>()
            return DefaultManagedRealmRuntime(
                startedApplication,
                telemetry,
                realm,
                requireNotNull(logback),
                context,
                loadedDiscovery,
            )
        } catch (failure: Throwable) {
            applicationScope.cancel()
            runCatching { application?.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            runCatching { discovery?.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            runCatching { logback?.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}

/**
 * Owns the staged Realm composition and maps loader lifecycle calls to the live Realm owner.
 *
 * Quiescing stops active database and messaging work but retains the staged graph. Stop is terminal and releases the
 * graph, discovery deployment, and logging bridge exactly once.
 */
private class DefaultManagedRealmRuntime(
    private val application: KoinApplication,
    private val telemetry: ServiceTelemetry,
    private val realm: Realm,
    private val logback: AutoCloseable,
    private val context: HostedDeploymentContext,
    private val discovery: DiscoveryDeployment,
) : ManagedRealmRuntime {
    private val closed = AtomicBoolean()
    private var active = false

    /** Starts Realm resources and rejects activation after terminal cleanup. */
    override suspend fun activate() {
        check(!closed.get()) { "Realm runtime is closed." }
        if (active) return
        startRealm(telemetry, realm, context)
        active = true
    }

    /** Stops live Realm work while retaining the staged composition for resume. */
    override suspend fun quiesce() {
        if (active) {
            stopRealm(telemetry, realm)
            active = false
        }
    }

    /** Reenters the active state using the retained staged composition. */
    override suspend fun resume() = activate()

    /** Permanently releases active work and all resources acquired during staging. */
    override suspend fun stop() {
        if (!closed.compareAndSet(false, true)) return
        try {
            if (active) stopRealm(telemetry, realm)
        } finally {
            try {
                application.close()
            } finally {
                try {
                    discovery.close()
                } finally {
                    logback.close()
                }
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
    context: HostedDeploymentContext,
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
    realm.start(context.identity.realmId)
    main.annotate { stage("database") { outcome("ready") } }
    main.event(
        name = "workflow.stage.completed",
        projection = EventProjection.log(LogSeverity.INFO, "Realm database is ready"),
    ) {
        attribute("workflow.stage", "database")
        attribute("operation.outcome", "completed")
    }
}
