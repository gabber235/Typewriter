package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.RealmRouteFactory
import com.typewritermc.realm.schema.RealmDatabaseProvider
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SpanPresentation
import com.typewritermc.services.libs.telemetry.childSpan
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class Realm(
    val database: DeferredProvider<Surreal>,
    private val databaseProvider: RealmDatabaseProvider,
    private val routeFactory: RealmRouteFactory,
    private val scope: CoroutineScope,
    private val telemetry: ServiceTelemetry,
) {
    private val lifecycle = Mutex()
    private var router: CommunicatorRouter? = null
    private var routerSession: RouterSession? = null
    private var registrarMonitor: Job? = null

    context(main: MainSpanScope)
    suspend fun start(states: StateFlow<RegistrarSnapshot>) {
        childSpan("realm.database.initialize") {
            database.set(databaseProvider.connect())
        }
        val snapshot = states.value
        val ready =
            snapshot.state as? RegistrarState.Ready
                ?: error("Registrar must be ready before Realm starts")
        replaceRouter(snapshot.attempt, ready)
        registrarMonitor =
            scope.launch {
                states.collectLatest { snapshot ->
                    val state = snapshot.state
                    if (state is RegistrarState.Ready) {
                        replaceRouterWithRetry(snapshot.attempt, state)
                    }
                }
            }
    }

    suspend fun shutdown() =
        telemetry.mainSpan(
            name = "realm.routes.shutdown",
            unhandledFailureSlug = ErrorSlug.of("realm-routes-shutdown-failed"),
        ) {
            registrarMonitor?.cancelAndJoin()
            registrarMonitor = null
            lifecycle.withLock {
                val active = router
                router = null
                routerSession = null
                active?.stop()?.requireSuccess("stop")
            }
            it.annotate { operationOutcome("completed") }
        }

    context(main: MainSpanScope)
    private suspend fun replaceRouterWithRetry(
        attempt: Long,
        ready: RegistrarState.Ready,
    ) {
        while (true) {
            try {
                telemetry.mainSpan(
                    name = "realm.routes.replace",
                    unhandledFailureSlug = ErrorSlug.of("realm-routes-replace-failed"),
                ) {
                    replaceRouter(attempt, ready)
                }
                return
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                delay(1_000)
            }
        }
    }

    context(main: MainSpanScope)
    private suspend fun replaceRouter(
        attempt: Long,
        ready: RegistrarState.Ready,
    ) = lifecycle.withLock {
        val session = RouterSession(attempt, ready.connectionGeneration)
        if (routerSession == session) return@withLock
        val previous = router
        router = null
        routerSession = null
        previous?.stop()?.requireSuccess("replace")
        val address =
            RealmAddress(
                realmId = ready.session.identity.serviceId,
                organizationId = ready.session.binding.organizationId,
            )
        val replacement = ready.session.communicator.createRouter(routeFactory.create(address), scope)
        replacement.start().requireSuccess("start")
        router = replacement
        routerSession = session
    }
}

private data class RouterSession(
    val attempt: Long,
    val connectionGeneration: Long,
)

private fun RouterResult.requireSuccess(operation: String) {
    if (this is RouterResult.Failure) error("Realm router $operation failed: $error")
}
