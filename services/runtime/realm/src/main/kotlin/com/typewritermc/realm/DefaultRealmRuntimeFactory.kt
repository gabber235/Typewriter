@file:Suppress("ForbiddenImport")

package com.typewritermc.realm

import ch.qos.logback.classic.Level
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputToken
import com.typewritermc.discovery.CapabilityOwnerResolver
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.GeneratedProviderInstantiator
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.realm.authoring.CreationEvaluator
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.compiler.EngineImplementationInputs
import com.typewritermc.realm.compiler.StagedEngineImplementationSource
import com.typewritermc.realm.deployment.ManagedRealmRuntime
import com.typewritermc.realm.deployment.RealmRuntimeFactory
import com.typewritermc.realm.schema.DatabaseEndpoint
import com.typewritermc.realm.schema.DatabaseProvider
import com.typewritermc.realm.schema.RealmDatabaseConfiguration
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import java.lang.reflect.Modifier
import java.nio.file.Path
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration.Companion.seconds

class DefaultRealmRuntimeFactory : RealmRuntimeFactory {
    override suspend fun stage(context: HostedDeploymentContext): ManagedRealmRuntime {
        val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        var logback: AutoCloseable? = null
        var deployment: GeneratedProviderDeployment? = null
        var catalogs: RealmCatalogStore? = null
        try {
            val configuration = RealmSettings.system().applicationConfiguration().resolveAgainst(context.directories.state)
            logback =
                installOpenTelemetryLogback(
                    context.host.openTelemetry,
                    Level.toLevel(configuration.diagnosticLevel.name, Level.WARN),
                )
            val resolver = ReflectiveRuntimeResolver()
            val loaded =
                GeneratedProviderLoader().load(
                    artifacts = context.generatedProviderArtifacts(),
                    facts = DeploymentFacts(context.facts),
                    instantiator = GeneratedProviderInstantiator.resolving(resolver::resolve),
                    capabilityOwners = CapabilityOwnerResolver { owner -> resolver.resolve(owner.java) },
                )
            deployment = loaded
            val generation =
                CatalogGeneration(
                    context.directories.deployment.fileName
                        .toString(),
                )
            val assembly =
                loaded.providers.contributions.assemble(
                    CatalogAssemblyContext(
                        generation = generation,
                        capabilities = loaded.providers.capabilities.map { it.provider.descriptor },
                    ),
                )
            val catalogStore = RealmCatalogStore()
            catalogs = catalogStore
            catalogStore.replace(RealmCatalogIncarnation(assembly, loaded))
            deployment = null
            val telemetry = context.host.openTelemetry.serviceTelemetry("realm", REALM_VERSION)
            val realm =
                Realm(
                    databaseProvider = DatabaseProvider(configuration.database),
                    catalogs = catalogStore,
                    scope = applicationScope,
                    telemetry = telemetry,
                    retryPolicy = RetryPolicy.fixed(1.seconds),
                    delayScheduler = CoroutineDelayScheduler,
                    host = context.host,
                    registrars = loaded.providers.registrars.map { it.registrar },
                    facts = loaded.facts,
                    creationEvaluator =
                        CreationEvaluator { request, catalog ->
                            DefaultInitializationRuntime(
                                catalog.checked,
                                catalog.nativeBindings,
                                catalog.initialization,
                            ).prepare(request)
                        },
                    engine =
                        StagedEngineImplementationSource(
                            EngineImplementationInputs(
                                signatures = emptySet(),
                                token = InputToken(context.publicationTarget.fingerprint()),
                            ),
                        ),
                )
            return DefaultManagedRealmRuntime(
                telemetry = telemetry,
                realm = realm,
                logback = requireNotNull(logback),
                catalogs = catalogStore,
                scope = applicationScope,
                context = context,
            )
        } catch (failure: Throwable) {
            applicationScope.cancel()
            runCatching { catalogs?.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            runCatching { deployment?.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            runCatching { logback?.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}

private class ReflectiveRuntimeResolver {
    private val instances = ConcurrentHashMap<Class<*>, Any>()

    fun resolve(type: Class<*>): Any =
        instances.computeIfAbsent(type) { requested ->
            when (requested) {
                PresentationRuntime::class.java -> DefaultPresentationRuntime()
                else -> instantiate(requested)
            }
        }

    private fun instantiate(type: Class<*>): Any {
        type.fields
            .singleOrNull { field ->
                field.name == "INSTANCE" && Modifier.isStatic(field.modifiers) && field.type == type
            }?.let { return it.get(null) }
        val constructors = type.constructors.filter { Modifier.isPublic(it.modifiers) }
        require(constructors.size == 1) {
            "Runtime owner ${type.name} requires one public constructor."
        }
        val constructor = constructors.single()
        return constructor.newInstance(*constructor.parameterTypes.map(::resolve).toTypedArray())
    }
}

private fun HostedDeploymentContext.generatedProviderArtifacts(): List<GeneratedProviderArtifact> {
    val extensionParts =
        artifacts.extensions.associate { extension ->
            extension.id to
                extension.sourceParts.mapNotNullTo(linkedSetOf()) { part ->
                    val eligible = part.disposition as? SourcePartDisposition.Eligible
                    part.name.takeIf { eligible != null && identity.placement in eligible.placements }
                }
        }
    val physical =
        buildList {
            add(artifacts.runtimeArtifact)
            addAll(artifacts.catalogArtifacts)
            artifacts.extensions.forEach { extension -> add(HostedArtifact(extension.path, extension.manifest)) }
        }.distinctBy { it.path }
    val duplicateIdentities = physical.groupBy { it.manifest.id }.filterValues { entries -> entries.map { it.path }.distinct().size > 1 }
    require(duplicateIdentities.isEmpty()) {
        "Generated provider artifact identities must resolve to one physical path: ${duplicateIdentities.keys.joinToString()}."
    }
    return physical.distinctBy { it.manifest.id }.map { artifact ->
        GeneratedProviderArtifact(
            artifact = artifact.manifest.id,
            path = artifact.path,
            acceptedSourceParts = extensionParts[artifact.manifest.id],
        )
    }
}

private class DefaultManagedRealmRuntime(
    private val telemetry: ServiceTelemetry,
    private val realm: Realm,
    private val logback: AutoCloseable,
    private val catalogs: RealmCatalogStore,
    private val scope: CoroutineScope,
    private val context: HostedDeploymentContext,
) : ManagedRealmRuntime {
    private val closed = AtomicBoolean()
    private var active = false

    override suspend fun activate() {
        check(!closed.get()) { "Realm runtime is closed." }
        if (active) return
        startRealm(telemetry, realm, context)
        active = true
    }

    override suspend fun quiesce() {
        if (!active) return
        stopRealm(telemetry, realm)
        active = false
    }

    override suspend fun resume() = activate()

    override suspend fun stop() {
        if (!closed.compareAndSet(false, true)) return
        try {
            if (active) stopRealm(telemetry, realm)
        } finally {
            scope.cancel()
            try {
                catalogs.close()
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
                is DatabaseEndpoint.Embedded.SurrealKv -> configured.copy(path = configured.path.resolveAgainst(workDirectory))

                is DatabaseEndpoint.Embedded.RocksDb -> configured.copy(path = configured.path.resolveAgainst(workDirectory))

                is DatabaseEndpoint.Embedded.Memory,
                is DatabaseEndpoint.Remote,
                -> configured
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
        stage("composition") { outcome("ready") }
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
