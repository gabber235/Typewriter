package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.search.CancelRealmPresentationSearchResult
import skirout.editor.v1.search.RealmPresentationSearchUpdate

/**
 * Registers search startup, update publication, and explicit cancellation.
 *
 * It validates request shape and verifies subscription identity on both initial and later responses. Publication
 * failure is surfaced to the producer rather than silently reported as successful delivery.
 */
internal class RealmPresentationSearchRoutes(
    private val source: RealmPresentationSearchSource,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.cancelRealmPresentationSearch) { call ->
                if (source.cancel(call.request.subscriptionId)) {
                    CancelRealmPresentationSearchResult.CANCELED
                } else {
                    CancelRealmPresentationSearchResult.NOT_FOUND
                }
            }
            watch(contracts.watchRealmPresentationSearch) { call ->
                invalidRealmPresentationSearchRequest(call.request)?.let { return@watch it }

                val response =
                    source.watch(call.request) { update ->
                        call.communicator
                            .publishUpdate(
                                contracts.watchRealmPresentationSearch,
                                realmAddress,
                                update.forSubscription(call.request.subscriptionId),
                            ).requirePublished()
                    }
                response.forSubscription(call.request.subscriptionId)
            }
        }
}

private fun RealmPresentationSearchUpdate.forSubscription(subscriptionId: String): RealmPresentationSearchUpdate {
    val actualSubscriptionId =
        when (this) {
            is RealmPresentationSearchUpdate.SnapshotWrapper -> value.subscriptionId
            is RealmPresentationSearchUpdate.UnavailableWrapper -> value.subscriptionId
            else -> null
        }
    if (actualSubscriptionId == subscriptionId) return this

    return invalidRealmPresentationSearchResponse(subscriptionId)
}
