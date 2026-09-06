package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.realm.compiler.CompiledArtifactStore
import com.typewritermc.realm.compiler.RealmCompileCoordinator
import com.typewritermc.realm.compiler.RealmCompiler
import com.typewritermc.realm.compiler.SurrealCompiledContentRepository
import com.typewritermc.realm.repository.PageDocumentCatalog
import com.typewritermc.realm.repository.SurrealAuthoringRepository
import com.typewritermc.realm.repository.SurrealPageDocumentRepository
import com.typewritermc.realm.routes.CompiledContentEvents
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.RealmCapabilityInvocationSource
import com.typewritermc.realm.routes.RealmEditorCatalogSource
import com.typewritermc.realm.routes.RealmPresentationSearchSource
import com.typewritermc.realm.routes.RealmRouteFactory
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.RouterState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SpanPresentation
import com.typewritermc.services.libs.telemetry.childSpan
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
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
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

/**
 * Owns database access, authoring compilation, and application routes for one hosted Realm.
 *
 * Startup initializes storage and waits for routes on a usable host messaging session. Session replacement
 * rebuilds the router without recreating authored state. Compiler and catalog invalidation workers belong to this
 * lifecycle; shutdown must finish before the host closes deployment resources.
 */
class Realm(
    private val databaseProvider: RealmDatabaseProvider,
    private val editorCatalog: RealmEditorCatalogSource,
    private val presentationSearch: RealmPresentationSearchSource,
    private val scope: CoroutineScope,
    private val telemetry: ServiceTelemetry,
    private val retryPolicy: RetryPolicy,
    private val delayScheduler: DelayScheduler,
    private val catalogInvalidations: RealmCatalogInvalidationProcess,
    private val discoverySnapshots: RealmDiscoverySnapshotStore,
    private val host: HostedRuntimeHost,
    private val capabilityInvocations: RealmCapabilityInvocationSource? = null,
) {
    private val lifecycle = Mutex()
    private var database: Surreal? = null
    private var routeFactory: RealmRouteFactory? = null
    private var router: CommunicatorRouter? = null
    private var routerSession: Long? = null
    private var serviceMonitor: Job? = null
    private var compileCoordinator: RealmCompileCoordinator? = null
    private var compileCatalogMonitor: Job? = null

    context(main: MainSpanScope)
    suspend fun start(realmId: String) {
        check(database == null) { "Realm is already started" }
        val connected = childSpan("realm.database.initialize") { databaseProvider.connect() }
        try {
            database = connected
            val pageDocuments =
                SurrealPageDocumentRepository(connected) {
                    discoverySnapshots.current()?.let {
                        PageDocumentCatalog(it.elements, it.discovery.types.definitions)
                    }
                }
            val elementTypeGraphs = {
                discoverySnapshots
                    .current()
                    ?.let { snapshot ->
                        snapshot.elements.entries.associate {
                            it.descriptor.id to TypeGraph(TypeExpression.Named(it.descriptor.type), snapshot.discovery.types.definitions)
                        }
                    }.orEmpty()
            }
            val compiledContentEvents = CompiledContentEvents()
            val compiledContent =
                SurrealCompiledContentRepository(
                    connected,
                    compiledContentEvents::publishActivated,
                    compiledContentEvents::publishBlocked,
                )
            val authoring = SurrealAuthoringRepository(connected, pageDocuments, elementTypeGraphs)
            val compiler =
                RealmCompileCoordinator(
                    documents = pageDocuments,
                    compiler =
                        RealmCompiler(
                            compiledContent,
                            CompiledArtifactStore(host.sharedArtifacts),
                        ),
                    catalogRevision = { discoverySnapshots.current().catalogRevision() },
                    scope = scope,
                )
            compileCoordinator = compiler
            routeFactory =
                RealmRouteFactory(
                    authoring = authoring,
                    compiledContent = compiledContent,
                    editorCatalog = editorCatalog,
                    presentationSearch = presentationSearch,
                    capabilityInvocations = capabilityInvocations,
                    compiledContentEvents = compiledContentEvents,
                    onCompilationInvalidated = compiler::invalidate,
                )
            compiler.start()
            compileCatalogMonitor =
                scope.launch {
                    discoverySnapshots.changes.collect { compiler.invalidate() }
                }
            val routesReady = CompletableDeferred<Unit>()
            serviceMonitor =
                scope.launch(start = CoroutineStart.UNDISPATCHED) {
                    try {
                        host.messaging.collectLatest { session ->
                            maintainRouter(realmId, session, routesReady)
                        }
                    } catch (failure: Throwable) {
                        routesReady.completeExceptionally(failure)
                        throw failure
                    }
                }
            routesReady.await()
        } catch (failure: Throwable) {
            runCatching { catalogInvalidations.stop() }.exceptionOrNull()?.let(failure::addSuppressed)
            runCatching { compileCatalogMonitor?.cancelAndJoin() }.exceptionOrNull()?.let(failure::addSuppressed)
            compileCatalogMonitor = null
            runCatching { compileCoordinator?.stop() }.exceptionOrNull()?.let(failure::addSuppressed)
            compileCoordinator = null
            runCatching {
                lifecycle.withLock {
                    val active = router
                    router = null
                    routerSession = null
                    active?.closeIfNeeded("startup rollback")
                }
            }.exceptionOrNull()?.let(failure::addSuppressed)
            routeFactory = null
            database = null
            runCatching { databaseProvider.close(connected) }.exceptionOrNull()?.let(failure::addSuppressed)
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
            runCatching { serviceMonitor?.cancelAndJoin() }.exceptionOrNull()?.let(failures::add)
            serviceMonitor = null
            runCatching { compileCatalogMonitor?.cancelAndJoin() }.exceptionOrNull()?.let(failures::add)
            compileCatalogMonitor = null
            runCatching { compileCoordinator?.stop() }.exceptionOrNull()?.let(failures::add)
            compileCoordinator = null
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
            val activeDatabase = database
            database = null
            runCatching { activeDatabase?.let { databaseProvider.close(it) } }.exceptionOrNull()?.let(failures::add)
            if (failures.isNotEmpty()) {
                val failure = failures.first()
                failures.drop(1).forEach(failure::addSuppressed)
                throw failure
            }
            it.annotate { operationOutcome("completed") }
        }
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
            if (session == null) {
                catalogInvalidations.stop()
                return@withLock null
            }
            val address =
                RealmAddress(
                    realmId = realmId,
                    organizationId = session.organizationId,
                )
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
                    runCatching { replacement.closeIfNeeded("failed replacement") }.exceptionOrNull()?.let(failure::addSuppressed)
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
                ) { span ->
                    span.annotate {
                        attribute("realm.id", realmId)
                        attribute("messaging.session.id", session.id)
                    }
                    val active = checkNotNull(replaceRouter(realmId, session))
                    routesReady.complete(Unit)
                    active.stateFlow.first { it == RouterState.STOPPED }
                    error("Realm router stopped while messaging session ${session.id} remained active")
                }
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                if (host.messaging.value?.id != session.id) return
                delayScheduler.delay(retryPolicy.delayFor(retry++, 0.5))
            }
        }
    }
}

private fun RealmDiscoverySnapshot?.catalogRevision(): String {
    if (this == null) return "catalog-unavailable"
    val elementFacts = elements.entries.map { it.descriptor }.sortedBy { it.id.value.toString() }
    val typeFacts = discovery.types.definitions.sortedBy { it.id.toString() }
    val facts = canonicalJson.encodeToString(elementFacts) + canonicalJson.encodeToString(typeFacts)
    return MessageDigest.getInstance("SHA-256").digest(facts.toByteArray()).joinToString("") {
        "%02x".format(it.toInt() and 0xff)
    }
}

private val canonicalJson = Json { encodeDefaults = true }

private fun RouterResult.requireSuccess(operation: String) {
    if (this is RouterResult.Failure) error("Realm router $operation failed: $error")
}

private suspend fun CommunicatorRouter.closeIfNeeded(operation: String) {
    if (state == RouterState.STOPPED) return
    stop().requireSuccess(operation)
}
