package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.outbox.RealmOutboxPublisher
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.SurrealBookRepository
import com.typewritermc.realm.repository.SurrealPageRepository
import com.typewritermc.realm.repository.SurrealTagRepository
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.RealmCapabilityInvocationSource
import com.typewritermc.realm.routes.RealmEditorCatalogSource
import com.typewritermc.realm.routes.RealmPresentationSearchSource
import com.typewritermc.realm.routes.RealmRouteFactory
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
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
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.Clock

/** Owns Realm storage, application routes, and outbox publication for one hosted deployment. */
class Realm(
    private val databaseProvider: RealmDatabaseProvider,
    private val editorCatalog: RealmEditorCatalogSource,
    private val pageDefinitions: PageCatalog,
    private val presentationSearch: RealmPresentationSearchSource,
    private val scope: CoroutineScope,
    private val telemetry: ServiceTelemetry,
    private val retryPolicy: RetryPolicy,
    private val delayScheduler: DelayScheduler,
    private val clock: Clock,
    private val catalogInvalidations: RealmCatalogInvalidationProcess,
    private val host: HostedRuntimeHost,
    private val capabilityInvocations: RealmCapabilityInvocationSource? = null,
) {
    private val lifecycle = Mutex()
    private var database: Surreal? = null
    private var routeFactory: RealmRouteFactory? = null
    private var router: CommunicatorRouter? = null
    private var outboxPublisher: RealmOutboxPublisher? = null
    private var routerSession: Long? = null
    private var serviceMonitor: Job? = null

    context(main: MainSpanScope)
    suspend fun start(realmId: String) {
        check(database == null) { "Realm is already started" }
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
                    pageDefinitions,
                    presentationSearch,
                    capabilityInvocations,
                )
            serviceMonitor =
                scope.launch {
                    host.messaging.collectLatest { session ->
                        replaceRouterWithRetry(realmId, session)
                    }
                }
        } catch (failure: Throwable) {
            runCatching { catalogInvalidations.stop() }.exceptionOrNull()?.let(failure::addSuppressed)
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

    suspend fun shutdown() {
        if (database == null && router == null && serviceMonitor == null) return
        telemetry.mainSpan(
            name = "realm.routes.shutdown",
            unhandledFailureSlug = ErrorSlug.of("realm-routes-shutdown-failed"),
        ) {
            val failures = mutableListOf<Throwable>()
            runCatching { serviceMonitor?.cancelAndJoin() }.exceptionOrNull()?.let(failures::add)
            serviceMonitor = null
            runCatching { catalogInvalidations.stop() }.exceptionOrNull()?.let(failures::add)
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
    }

    private suspend fun replaceRouter(
        realmId: String,
        session: HostedMessagingSession?,
    ) = lifecycle.withLock {
        if (routerSession == session?.id) return@withLock
        if (session == null) {
            val previous = router
            router = null
            routerSession = null
            catalogInvalidations.stop()
            outboxPublisher?.stop()
            previous?.stop()?.requireSuccess("disconnect")
            return@withLock
        }
        val address =
            RealmAddress(
                realmId = realmId,
                organizationId = session.organizationId,
            )
        val routes = checkNotNull(routeFactory) { "Realm routes are not initialized" }
        val replacement = session.communicator.createRouter(routes.create(address), scope)
        replacement.start().requireSuccess("start")
        val previous = router
        router = replacement
        routerSession = session.id
        catalogInvalidations.replaceCommunicator(session.communicator, address)
        checkNotNull(outboxPublisher) { "Realm outbox publisher is not initialized" }
            .replaceCommunicator(session.communicator)
        previous?.stop()?.requireSuccess("replace")
    }

    private suspend fun replaceRouterWithRetry(
        realmId: String,
        session: HostedMessagingSession?,
    ) {
        var retry = 0L
        while (host.messaging.value?.id == session?.id) {
            try {
                replaceRouter(realmId, session)
                return
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                delayScheduler.delay(retryPolicy.delayFor(retry++, 0.5))
            }
        }
    }
}

private fun RouterResult.requireSuccess(operation: String) {
    if (this is RouterResult.Failure) error("Realm router $operation failed: $error")
}
