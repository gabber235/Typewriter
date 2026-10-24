package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.RuntimeCleanupOwner
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.PreparationCoordinator
import com.typewritermc.realm.authoring.PreparationEvaluator
import com.typewritermc.realm.authoring.RealmStructureProvisioning
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.compiler.AuthoringAcceptance
import com.typewritermc.realm.compiler.CompiledArtifactProducerRegistry
import com.typewritermc.realm.compiler.CompiledRootStatuses
import com.typewritermc.realm.compiler.EngineImplementationSource
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.realm.compiler.RegisteredCompiledArtifactStore
import com.typewritermc.realm.compiler.ResourceGraphArtifactProducer
import com.typewritermc.realm.compiler.SurrealPublicationAttemptStore
import com.typewritermc.realm.compiler.SurrealRegisteredCompiledContentRepository
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.RealmAuthoringOwner
import com.typewritermc.realm.repository.SurrealAuthoringStorage
import com.typewritermc.realm.routes.CapabilityRealmPresentationSearchSource
import com.typewritermc.realm.routes.EditorUpdatePublisher
import com.typewritermc.realm.routes.RealmCapabilityInvocationSource
import com.typewritermc.realm.routes.RealmRouteFactory
import com.typewritermc.realm.routes.RetainedRealmEditorCatalogSource
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.search.SurrealAuthoringSearchRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.RouterState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.childSpan
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.services.libs.utils.closeAll
import com.typewritermc.services.libs.utils.rethrowExceptional
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * Owns the active Realm authoring services between activation and quiescence.
 *
 * Persistent resources are loaded into a retained [AuthoringViewStore]. The authoring repository admits edits,
 * checks evaluate captured inputs, and the publication coordinator compiles accepted saved views into shared
 * artifacts. Editor routes expose these services through the current host messaging session.
 *
 * Session replacement rebuilds routing while database, checks, and publication remain active. Shutdown retires
 * publishers and routes before closing their views and database. The managed runtime serializes activation
 * and shutdown; the local lifecycle mutex protects router replacement within an activation.
 */
internal class Realm(
    private val databaseProvider: RealmDatabaseProvider,
    private val catalogs: RealmCatalogStore,
    private val scope: CoroutineScope,
    private val telemetry: ServiceTelemetry,
    private val retryPolicy: RetryPolicy,
    private val delayScheduler: DelayScheduler,
    private val host: HostedRuntimeHost,
    private val registrars: List<RuntimeRegistrar>,
    private val facts: DeploymentFacts,
    private val preparationEvaluator: PreparationEvaluator,
    private val engine: EngineImplementationSource,
    private val catalogActivator: RealmCatalogActivator = DefaultRealmCatalogActivator,
) {
    private val lifecycle = Mutex()
    private val catalogInvalidations = RealmCatalogInvalidationProcess(catalogs, scope, telemetry, retryPolicy, delayScheduler)
    private var database: Surreal? = null
    private var views: AuthoringViewStore? = null
    private var checks: RealmCheckRuntime? = null
    private var publication: RealmPublicationCoordinator? = null
    private var editorUpdates: EditorUpdatePublisher? = null
    private var registrarScope: RealmRuntimeScope? = null
    private var routeFactory: RealmRouteFactory? = null
    private var router: CommunicatorRouter? = null
    private var routerSession: Long? = null
    private var serviceMonitor: Job? = null

    context(main: MainSpanScope)
    suspend fun start(realmId: String) {
        check(database == null) { "Realm is already started" }
        val connected = childSpan("realm.database.initialize") { databaseProvider.connect() }
        try {
            database = connected
            val catalog = catalogs.captureCurrent()
            val storage = SurrealAuthoringStorage(connected)
            val seed = storage.readCoherent()
            val viewStore = InMemoryAuthoringViewStore(catalog, seed)
            views = viewStore
            val authoring = RealmAuthoringOwner(storage, viewStore)
            catalogs.captureCurrent().use { next ->
                catalogActivator.activate(authoring, next)
            }
            val checkRuntime = RealmCheckRuntime(viewStore)
            checks = checkRuntime
            val compiledContent = SurrealRegisteredCompiledContentRepository(connected)
            val compilation = CompiledArtifactProducerRegistry(listOf(ResourceGraphArtifactProducer))
            val publisher =
                RealmPublicationCoordinator(
                    acceptance = AuthoringAcceptance(viewStore, checkRuntime),
                    attempts = SurrealPublicationAttemptStore(connected),
                    artifacts =
                        RegisteredCompiledArtifactStore(
                            host.sharedArtifacts,
                            requireNotNull(host.publicationRetention) { "Realm needs publication retention" },
                        ),
                    engine = engine,
                    compilation = compilation,
                    results = compiledContent,
                    findings = checkRuntime::findings,
                )
            this.publication = publisher
            val editorUpdates = EditorUpdatePublisher(viewStore, publisher, checkRuntime.findingChanges, telemetry, scope)
            this.editorUpdates = editorUpdates
            checkRuntime.reloadCatalog()
            val routedAuthoring = CheckingAuthoringRepository(authoring, checkRuntime, editorUpdates)
            RealmStructureProvisioning(routedAuthoring).ensure(viewStore)
            publisher.recoverInterrupted()
            publisher.start(scope, viewStore.changes)
            val preparation =
                PreparationCoordinator(
                    catalog = catalogs::captureCurrent,
                    evaluator = preparationEvaluator,
                )
            val activeRegistrarScope = RealmRuntimeScope(scope, facts)
            registrarScope = activeRegistrarScope
            with(activeRegistrarScope) {
                registrars.forEach { registrar -> registrar.register() }
            }
            routeFactory =
                RealmRouteFactory(
                    authoring = routedAuthoring,
                    authoringSearch = SurrealAuthoringSearchRepository(connected),
                    views = viewStore,
                    checks = checkRuntime,
                    compiledContent = compiledContent,
                    compiledRootStatuses = CompiledRootStatuses(compilation, compiledContent),
                    publisher = publisher,
                    editorCatalog = RetainedRealmEditorCatalogSource(catalogs),
                    preparation = preparation,
                    presentationSearch = CapabilityRealmPresentationSearchSource(scope, catalogs, viewStore),
                    capabilityInvocations = RealmCapabilityInvocationSource(catalogs),
                    editorUpdates = editorUpdates,
                )
            val routesReady = CompletableDeferred<Unit>()
            serviceMonitor =
                scope.launch(start = CoroutineStart.UNDISPATCHED) {
                    try {
                        host.messaging.collectLatest { session -> maintainRouter(realmId, session, routesReady) }
                    } catch (failure: Throwable) {
                        routesReady.completeExceptionally(failure)
                        throw failure
                    }
                }
            routesReady.await()
        } catch (failure: Throwable) {
            withContext(NonCancellable) { closeStartedResources(failure) }
            throw failure
        }
    }

    suspend fun shutdown() {
        if (database == null && router == null && serviceMonitor == null) return
        telemetry.mainSpan(
            name = "realm.routes.shutdown",
            unhandledFailureSlug = ErrorSlug.of("realm-routes-shutdown-failed"),
        ) {
            closeStartedResources()
            it.annotate { operationOutcome("completed") }
        }
    }

    /** Closes started resources in reverse dependency order, suppressing failures into [primary] when given. */
    private suspend fun closeStartedResources(primary: Throwable? = null) =
        closeAll(primary) {
            attempt { serviceMonitor?.cancelAndJoin() }
            serviceMonitor = null
            attempt { catalogInvalidations.stop() }
            attempt {
                lifecycle.withLock {
                    val active = router
                    router = null
                    routerSession = null
                    active?.closeIfNeeded("stop")
                }
            }
            routeFactory = null
            attempt { publication?.close() }
            publication = null
            attempt { checks?.close() }
            checks = null
            attempt { editorUpdates?.close() }
            editorUpdates = null
            attempt { registrarScope?.shutdown() }
            registrarScope = null
            attempt { views?.close() }
            views = null
            val activeDatabase = database
            database = null
            attempt { activeDatabase?.let { databaseProvider.close(it) } }
        }

    private suspend fun replaceRouter(
        realmId: String,
        session: HostedMessagingSession?,
    ): CommunicatorRouter? =
        lifecycle.withLock {
            val previous = router
            if (routerSession == session?.id && previous?.state == RouterState.RUNNING) return@withLock previous
            router = null
            routerSession = null
            previous?.closeIfNeeded("replace")
            editorUpdates?.unconfigure()
            if (session == null) {
                catalogInvalidations.stop()
                return@withLock null
            }
            val address = RealmRouteScope(realmId = realmId, organizationId = session.organizationId)
            val routes = checkNotNull(routeFactory) { "Realm routes are not initialized" }
            val replacement = session.communicator.createRouter(routes.create(address, session.communicator), scope)
            try {
                replacement.start().requireSuccess("start")
                catalogInvalidations.replaceCommunicator(session.communicator, address)
                router = replacement
                routerSession = session.id
                replacement
            } catch (failure: Throwable) {
                withContext(NonCancellable) {
                    runCatching { replacement.closeIfNeeded("failed replacement") }
                        .exceptionOrNull()
                        ?.let(failure::addSuppressed)
                }
                throw failure
            }
        }

    private suspend fun maintainRouter(
        realmId: String,
        session: HostedMessagingSession?,
        routesReady: CompletableDeferred<Unit>,
    ) {
        if (session == null) {
            replaceRouter(realmId, null)
            return
        }
        var retry = 0L
        while (host.messaging.value?.id == session.id) {
            try {
                telemetry.mainSpan(
                    name = "realm.routes.session",
                    unhandledFailureSlug = ErrorSlug.of("realm-routes-session-failed"),
                ) {
                    val active = checkNotNull(replaceRouter(realmId, session))
                    routesReady.complete(Unit)
                    active.stateFlow.first { state -> state == RouterState.STOPPED }
                    error("Realm router stopped while its messaging session remained active")
                }
            } catch (failure: Throwable) {
                failure.rethrowExceptional()
                if (host.messaging.value?.id != session.id) return
                delayScheduler.delay(retryPolicy.delayFor(retry++, 0.5))
            }
        }
    }
}

internal fun interface RealmCatalogActivator {
    suspend fun activate(
        repository: RealmAuthoringOwner,
        catalog: AuthoringCatalogLease,
    )
}

private object DefaultRealmCatalogActivator : RealmCatalogActivator {
    override suspend fun activate(
        repository: RealmAuthoringOwner,
        catalog: AuthoringCatalogLease,
    ) {
        repository.activateCatalog(catalog, install = {}, publish = {})
    }
}

private class CheckingAuthoringRepository(
    private val delegate: AuthoringRepository,
    private val checks: RealmCheckRuntime,
    private val events: EditorUpdatePublisher,
) : AuthoringRepository {
    override suspend fun commit(edit: PreparedEdit): CommitResult =
        delegate.commit(edit).also { result ->
            if (result is CommitResult.Committed) {
                checks.invalidateCurrent()
                events.committed()
            }
        }
}

private class RealmRuntimeScope(
    override val coroutineScope: CoroutineScope,
    override val facts: DeploymentFacts,
) : RuntimeScope {
    private val ownership = RuntimeCleanupOwner()

    override fun own(cleanup: suspend () -> Unit) = ownership.own(cleanup)

    override fun <R : AutoCloseable> own(resource: R): R = ownership.own(resource)

    suspend fun shutdown() = ownership.close()
}

private fun RouterResult.requireSuccess(operation: String) {
    if (this is RouterResult.Failure) error("Realm router $operation failed: $error")
}

private suspend fun CommunicatorRouter.closeIfNeeded(operation: String) {
    if (state == RouterState.STOPPED) return
    stop().requireSuccess(operation)
}
