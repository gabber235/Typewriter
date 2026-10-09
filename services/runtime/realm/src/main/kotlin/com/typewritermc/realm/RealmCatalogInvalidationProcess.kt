package com.typewritermc.realm

import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.routes.EditorContracts
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.requirePublished
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.rethrowExceptional
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch
import skirout.editor.v1.catalog.CatalogInvalidated
import skirout.editor.v1.type_catalog.CatalogGeneration

/**
 * Publishes discovery generation invalidations independently of client request lifetimes. Replacing the
 * communicator cancels and joins the old publisher before subscribing on the new connection. Failed publications
 * retry until successful. Each communicator receives the installed generation before routes are exposed. A newer
 * generation cancels the older retry loop.
 */
class RealmCatalogInvalidationProcess internal constructor(
    private val catalogs: RealmCatalogStore,
    private val scope: CoroutineScope,
    private val telemetry: ServiceTelemetry,
) {
    private var publisher: Job? = null

    /**
     * Binds catalog invalidation delivery to a new Realm communicator and waits for its subscriber to be installed.
     *
     * The installed generation is announced for every communicator. Failed publication retries until the generation
     * is delivered or a newer generation supersedes it.
     */
    internal suspend fun replaceCommunicator(
        communicator: Communicator,
        address: RealmAddress,
    ) {
        stop()
        val contract = EditorContracts(address).watchEditorCatalog
        val announced = CompletableDeferred<Unit>()
        val replacement =
            scope.launch(start = CoroutineStart.UNDISPATCHED) {
                catalogs.changes
                    .onStart { emit(catalogs.captureCurrent().use { it.generation }) }
                    .map { it.value }
                    .distinctUntilChanged()
                    .collectLatest { generation ->
                        while (true) {
                            val published =
                                runCatching {
                                    telemetry.mainSpan(
                                        name = "realm.editor.catalog.invalidate",
                                        unhandledFailureSlug = ErrorSlug.of("realm-editor-catalog-invalidation-failed"),
                                    ) {
                                        communicator
                                            .publishUpdate(
                                                contract = contract,
                                                address = address,
                                                update =
                                                    CatalogInvalidated(generation = CatalogGeneration(value = generation)),
                                            ).requirePublished()
                                    }
                                }.fold(
                                    onSuccess = { true },
                                    onFailure = {
                                        it.rethrowExceptional()
                                        false
                                    },
                                )
                            if (published) {
                                announced.complete(Unit)
                                break
                            }
                            delay(INVALIDATION_RETRY_DELAY)
                        }
                    }
            }
        replacement.invokeOnCompletion { failure ->
            if (failure != null) announced.completeExceptionally(failure)
        }
        publisher = replacement
        announced.await()
    }

    /** Cancels and joins the current invalidation publisher before its communicator is discarded. */
    internal suspend fun stop() {
        publisher?.cancelAndJoin()
        publisher = null
    }
}

private val INVALIDATION_RETRY_DELAY = kotlin.time.Duration.parse("250ms")
