package com.typewritermc.realm

import com.typewritermc.realm.routes.LibraryContracts
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.requirePublished
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.type_catalog.CatalogGeneration

/** Publishes catalog generation changes independently from client request lifetimes. */
class RealmCatalogInvalidationProcess internal constructor(
    private val snapshots: RealmDiscoverySnapshotStore,
    private val scope: CoroutineScope,
    private val telemetry: ServiceTelemetry,
) {
    private var publisher: Job? = null

    internal suspend fun replaceCommunicator(
        communicator: Communicator,
        address: RealmAddress,
    ) {
        stop()
        val contract = LibraryContracts(address).watchEditorCatalog
        publisher =
            scope.launch(start = CoroutineStart.UNDISPATCHED) {
                snapshots.changes
                    .map { it.discovery.generation.value }
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
                                                    CatalogWatchUpdate.createInvalidated(
                                                        generation = CatalogGeneration(value = generation),
                                                        reason = "Realm discovery snapshot changed",
                                                    ),
                                            ).requirePublished()
                                    }
                                }.fold(
                                    onSuccess = { true },
                                    onFailure = {
                                        rethrowExceptionalThrowable(it)
                                        false
                                    },
                                )
                            if (published) break
                            delay(INVALIDATION_RETRY_DELAY)
                        }
                    }
            }
        snapshots.awaitChangeSubscriber()
    }

    internal suspend fun stop() {
        publisher?.cancelAndJoin()
        publisher = null
    }
}

private val INVALIDATION_RETRY_DELAY = kotlin.time.Duration.parse("250ms")
