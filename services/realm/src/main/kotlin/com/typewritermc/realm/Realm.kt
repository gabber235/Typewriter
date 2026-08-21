package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.deployment.CompatibleNoOperationCheckpoint
import com.typewritermc.realm.deployment.ManagedRealmRuntime
import com.typewritermc.realm.deployment.RealmUpgradeCheckpoint
import com.typewritermc.realm.outbox.RealmOutboxPublisher
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.SurrealBookRepository
import com.typewritermc.realm.repository.SurrealPageRepository
import com.typewritermc.realm.repository.SurrealTagRepository
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.RealmEditorCatalogSource
import com.typewritermc.realm.routes.RealmPresentationSearchSource
import com.typewritermc.realm.routes.RealmRouteFactory
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SpanPresentation
import com.typewritermc.services.libs.telemetry.childSpan
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.Clock

/**
 * Owns Realm storage, communication routes, registrar monitoring, and outbox publication for one child deployment.
 *
 * [start] and [stop] define one lifecycle and are serialized internally. The current scaffold exposes a compatible no
 * operation upgrade checkpoint, so replacement restarts the Realm without migrating in memory state.
 */
class Realm(
    private val databaseProvider: RealmDatabaseProvider,
    private val editorCatalog: RealmEditorCatalogSource,
    private val presentationSearch: RealmPresentationSearchSource,
    private val scope: CoroutineScope,
    private val telemetry: ServiceTelemetry,
    private val retryPolicy: RetryPolicy,
    private val delayScheduler: DelayScheduler,
    private val clock: Clock,
) : ManagedRealmRuntime {
    private val lifecycle = Mutex()
    private var database: Surreal? = null
    private var routeFactory: RealmRouteFactory? = null
    private var router: CommunicatorRouter? = null
    private var outboxPublisher: RealmOutboxPublisher? = null
    private var routerSession: RouterSession? = null
    private var registrarMonitor: Job? = null

    context(main: MainSpanScope)
    suspend fun start(
        states: StateFlow<RegistrarSnapshot>,
        communicatorFor: suspend (Long) -> RegistrarResult<Communicator>,
    ) {
        check(database == null) { "Realm is already started" }
        val snapshot = states.value
        val ready =
            snapshot.state as? RegistrarState.Ready
                ?: error("Registrar must be ready before Realm starts")
        val connected = childSpan("realm.database.initialize") { databaseProvider.connect() }
        try {
            database = connected
            val outbox = SurrealRealmOutbox(connected)
            outboxPublisher = RealmOutboxPublisher(outbox, scope, clock, retryPolicy, delayScheduler)
            routeFactory =
                RealmRouteFactory(
                    SurrealBookRepository(connected, outbox),
                    SurrealPageRepository(connected, outbox),
                    SurrealTagRepository(connected, outbox),
                    editorCatalog,
                    presentationSearch,
                )
            replaceRouter(snapshot.attempt, ready, communicatorFor)
            registrarMonitor =
                scope.launch {
                    states.collectLatest { snapshot ->
                        val state = snapshot.state
                        if (state is RegistrarState.Ready) {
                            replaceRouterWithRetry(snapshot.attempt, state, communicatorFor)
                        }
                    }
                }
        } catch (failure: Throwable) {
            runCatching { outboxPublisher?.stop() }.exceptionOrNull()?.let(failure::addSuppressed)
            outboxPublisher = null
            runCatching {
                lifecycle.withLock {
                    val active = router
                    router = null
                    routerSession = null
                    active?.stop()?.requireSuccess("startup rollback")
                }
            }.exceptionOrNull()?.let(failure::addSuppressed)
            routeFactory = null
            database = null
            runCatching { databaseProvider.close(connected) }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }

    suspend fun shutdown() =
        telemetry.mainSpan(
            name = "realm.routes.shutdown",
            unhandledFailureSlug = ErrorSlug.of("realm-routes-shutdown-failed"),
        ) {
            val failures = mutableListOf<Throwable>()
            runCatching { registrarMonitor?.cancelAndJoin() }.exceptionOrNull()?.let(failures::add)
            registrarMonitor = null
            runCatching { outboxPublisher?.stop() }.exceptionOrNull()?.let(failures::add)
            outboxPublisher = null
            runCatching {
                lifecycle.withLock {
                    val active = router
                    router = null
                    routerSession = null
                    active?.stop()?.requireSuccess("stop")
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

    override suspend fun prepareUpgradeCheckpoint(): RealmUpgradeCheckpoint = CompatibleNoOperationCheckpoint

    override suspend fun stop() {
        shutdown()
    }

    context(main: MainSpanScope)
    private suspend fun replaceRouterWithRetry(
        attempt: Long,
        ready: RegistrarState.Ready,
        communicatorFor: suspend (Long) -> RegistrarResult<Communicator>,
    ) {
        var retryAttempt = 0L
        while (true) {
            try {
                telemetry.mainSpan(
                    name = "realm.routes.replace",
                    unhandledFailureSlug = ErrorSlug.of("realm-routes-replace-failed"),
                ) {
                    replaceRouter(attempt, ready, communicatorFor)
                }
                return
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                delayScheduler.delay(retryPolicy.delayFor(retryAttempt))
                retryAttempt = if (retryAttempt == Long.MAX_VALUE) Long.MAX_VALUE else retryAttempt + 1
            }
        }
    }

    context(main: MainSpanScope)
    private suspend fun replaceRouter(
        attempt: Long,
        ready: RegistrarState.Ready,
        communicatorFor: suspend (Long) -> RegistrarResult<Communicator>,
    ) = lifecycle.withLock {
        val session = RouterSession(attempt, ready.connectionGeneration)
        if (routerSession == session) return@withLock
        val previous = router
        router = null
        routerSession = null
        outboxPublisher?.stop()
        previous?.stop()?.requireSuccess("replace")
        val address =
            RealmAddress(
                realmId = ready.session.identity.serviceId,
                organizationId = ready.session.binding.organizationId,
            )
        val communicator =
            when (val result = communicatorFor(ready.connectionGeneration)) {
                is RegistrarResult.Success -> result.value
                is RegistrarResult.Failure -> error("Registrar communicator unavailable: ${result.failure}")
            }
        val routes = checkNotNull(routeFactory) { "Realm routes are not initialized" }
        val replacement = communicator.createRouter(routes.create(address), scope)
        replacement.start().requireSuccess("start")
        router = replacement
        routerSession = session
        checkNotNull(outboxPublisher) { "Realm outbox publisher is not initialized" }.replaceCommunicator(communicator)
    }
}

private data class RouterSession(
    val attempt: Long,
    val connectionGeneration: Long,
)

private fun RouterResult.requireSuccess(operation: String) {
    if (this is RouterResult.Failure) error("Realm router $operation failed: $error")
}
