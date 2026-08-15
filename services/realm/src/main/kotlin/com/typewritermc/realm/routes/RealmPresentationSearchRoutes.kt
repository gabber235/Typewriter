package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.search.RealmPresentationSearchUpdate

internal class RealmPresentationSearchRoutes(
    private val source: RealmPresentationSearchSource,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
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
