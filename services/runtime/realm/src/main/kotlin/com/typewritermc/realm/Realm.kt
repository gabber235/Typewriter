package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.authoring.CommitResult
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.CreationCoordinator
import com.typewritermc.realm.authoring.CreationEvaluator
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.SnapshotCatalogLease
import com.typewritermc.realm.authoring.SurrealCreationReceiptStore
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.compiler.AuthoringAcceptance
import com.typewritermc.realm.compiler.EngineImplementationSource
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.realm.compiler.RegisteredCompiledArtifactStore
import com.typewritermc.realm.compiler.SurrealPublicationAttemptStore
import com.typewritermc.realm.compiler.SurrealRegisteredCompiledContentRepository
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.SurrealAuthoringRepository
import com.typewritermc.realm.repository.SurrealAuthoringSeedLoader
import com.typewritermc.realm.routes.CapabilityRealmPresentationSearchSource
import com.typewritermc.realm.routes.EditorCheckEvents
import com.typewritermc.realm.routes.EditorCompiledContentEvents
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.RealmCapabilityInvocationSource
import com.typewritermc.realm.routes.RealmRouteFactory
import com.typewritermc.realm.routes.SnapshotRealmEditorCatalogSource
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.realm.search.AuthoringSearchIndexer
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
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
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
import java.util.concurrent.atomic.AtomicBoolean

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
    private val creationEvaluator: CreationEvaluator,
    private val engine: EngineImplementationSource,
    private val catalogActivator: RealmCatalogActivator = DurableRealmCatalogActivator,
) {
    private val lifecycle = Mutex()
    private val catalogInvalidations = RealmCatalogInvalidationProcess(catalogs, scope, telemetry)
    private var database: Surreal? = null
    private var snapshots: AuthoringSnapshotStore? = null
    private var checks: RealmCheckRuntime? = null
    private var checkEvents: EditorCheckEvents? = null
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
            val seed = requireNotNull(SurrealAuthoringSeedLoader(connected).loadFor(catalog))
            val snapshotStore = InMemoryAuthoringSnapshotStore(catalog, seed)
            snapshots = snapshotStore
            val searchIndexer = AuthoringSearchIndexer()
            val authoring =
                SurrealAuthoringRepository(
                    database = connected,
                    snapshots = snapshotStore,
                    catalog = catalogs::captureCurrent,
                    searchIndexer = searchIndexer,
                )
            catalogs.captureCurrent().use { next ->
                catalogActivator.activate(authoring, next)
            }
            val checkEvents = EditorCheckEvents(snapshotStore, authoring, scope)
            this.checkEvents = checkEvents
            val checkRuntime = RealmCheckRuntime(snapshotStore, onFindingsChanged = checkEvents::publishChanged)
            checks = checkRuntime
            checkRuntime.reloadCatalog()
            val routedAuthoring = CheckingAuthoringRepository(authoring, checkRuntime, checkEvents)
            val compiledContentEvents = EditorCompiledContentEvents()
            val compiledContent =
                SurrealRegisteredCompiledContentRepository(
                    connected,
                    compiledContentEvents::publishActivated,
                    compiledContentEvents::publishBlocked,
                )
            val publisher =
                RealmPublicationCoordinator(
                    acceptance = AuthoringAcceptance(snapshotStore, checkRuntime),
                    attempts = SurrealPublicationAttemptStore(connected),
                    content = compiledContent,
                    artifacts = RegisteredCompiledArtifactStore(host.sharedArtifacts),
                    engine = engine,
                )
            publisher.recoverInterrupted()
            val creation =
                CreationCoordinator(
                    catalog = catalogs::captureCurrent,
                    receipts = SurrealCreationReceiptStore(connected),
                    evaluator = creationEvaluator,
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
                    snapshots = snapshotStore,
                    checks = checkRuntime,
                    compiledContent = compiledContent,
                    publisher = publisher,
                    editorCatalog = SnapshotRealmEditorCatalogSource(catalogs),
                    creation = creation,
                    presentationSearch = CapabilityRealmPresentationSearchSource(scope, catalogs),
                    capabilityInvocations = RealmCapabilityInvocationSource(catalogs),
                    compiledContentEvents = compiledContentEvents,
                    checkEvents = checkEvents,
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
            val failures = mutableListOf<Throwable>()
            closeStartedResources(failures)
            if (failures.isNotEmpty()) {
                val failure = failures.first()
                failures.drop(1).forEach(failure::addSuppressed)
                throw failure
            }
            it.annotate { operationOutcome("completed") }
        }
    }

    private suspend fun closeStartedResources(failure: Throwable) {
        val failures = mutableListOf<Throwable>()
        closeStartedResources(failures)
        failures.forEach(failure::addSuppressed)
    }

    private suspend fun closeStartedResources(failures: MutableList<Throwable>) {
        runCatching { serviceMonitor?.cancelAndJoin() }.exceptionOrNull()?.let(failures::add)
        serviceMonitor = null
        runCatching { catalogInvalidations.stop() }.exceptionOrNull()?.let(failures::add)
        runCatching {
            lifecycle.withLock {
                val active = router
                router = null
                routerSession = null
                active?.closeIfNeeded("stop")
            }
        }.exceptionOrNull()?.let(failures::add)
        routeFactory = null
        runCatching { checks?.close() }.exceptionOrNull()?.let(failures::add)
        checks = null
        runCatching { checkEvents?.close() }.exceptionOrNull()?.let(failures::add)
        checkEvents = null
        runCatching { registrarScope?.shutdown() }.exceptionOrNull()?.let(failures::add)
        registrarScope = null
        runCatching { snapshots?.close() }.exceptionOrNull()?.let(failures::add)
        snapshots = null
        val activeDatabase = database
        database = null
        runCatching { activeDatabase?.let { databaseProvider.close(it) } }.exceptionOrNull()?.let(failures::add)
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
            checkEvents?.unconfigure()
            if (session == null) {
                catalogInvalidations.stop()
                return@withLock null
            }
            val address = RealmAddress(realmId = realmId, organizationId = session.organizationId)
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
                rethrowExceptionalThrowable(failure)
                if (host.messaging.value?.id != session.id) return
                delayScheduler.delay(retryPolicy.delayFor(retry++, 0.5))
            }
        }
    }
}

internal fun interface RealmCatalogActivator {
    suspend fun activate(
        repository: SurrealAuthoringRepository,
        catalog: SnapshotCatalogLease,
    )
}

private object DurableRealmCatalogActivator : RealmCatalogActivator {
    override suspend fun activate(
        repository: SurrealAuthoringRepository,
        catalog: SnapshotCatalogLease,
    ) {
        repository.activateCatalog(catalog, install = {}, publish = {})
    }
}

private class CheckingAuthoringRepository(
    private val delegate: AuthoringRepository,
    private val checks: RealmCheckRuntime,
    private val events: EditorCheckEvents,
) : AuthoringRepository {
    override suspend fun replay(edit: com.typewritermc.authoring.PreparedEdit): CommitResult? = delegate.replay(edit)

    override suspend fun commit(edit: com.typewritermc.authoring.PreparedEdit): CommitResult =
        delegate.commit(edit).also { result ->
            if (result is CommitResult.Committed) {
                checks.invalidate(result.changed)
                events.committed()
            }
        }
}

private class RealmRuntimeScope(
    override val coroutineScope: CoroutineScope,
    override val facts: DeploymentFacts,
) : RuntimeScope {
    private val lock = Any()
    private val cleanup = mutableListOf<suspend () -> Unit>()
    private val closed = AtomicBoolean()

    override fun own(cleanup: suspend () -> Unit) {
        synchronized(lock) {
            check(!closed.get()) { "Realm runtime scope is closed." }
            this.cleanup += cleanup
        }
    }

    override fun <R : AutoCloseable> own(resource: R): R = resource.also { own(it::close) }

    suspend fun shutdown() {
        if (!closed.compareAndSet(false, true)) return
        val actions = synchronized(lock) { cleanup.asReversed().toList().also { cleanup.clear() } }
        val failures = actions.mapNotNull { action -> runCatching { action() }.exceptionOrNull() }
        if (failures.isNotEmpty()) {
            val failure = failures.first()
            failures.drop(1).forEach(failure::addSuppressed)
            throw failure
        }
    }
}

private fun RouterResult.requireSuccess(operation: String) {
    if (this is RouterResult.Failure) error("Realm router $operation failed: $error")
}

private suspend fun CommunicatorRouter.closeIfNeeded(operation: String) {
    if (state == RouterState.STOPPED) return
    stop().requireSuccess(operation)
}
