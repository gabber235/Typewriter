package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.WatchRealmPresentationSearch

internal fun realmPresentationSearchContract(
    address: RealmAddress,
): WatchContract<
    RealmAddress,
    RealmPresentationSearchRequest,
    RealmPresentationSearchUpdate,
    RealmPresentationSearchUpdate,
> =
    skirWatchContract(
        method = WatchRealmPresentationSearch,
        updateSerializer = RealmPresentationSearchUpdate.serializer,
        name = OperationName.of(SEARCH_OPERATION),
        requestAddress = requestAddress(SEARCH_OPERATION).subscribedAt(address),
        updateAddress = updateAddress(SEARCH_OPERATION),
        initialPolicy =
            ResponsePolicy(
                unavailableRealmPresentationSearchUpdate(
                    subscriptionId = "",
                    message = "Realm presentation search failed",
                ),
                realmPresentationSearchResponseClassifier(),
            ),
        updateClassifier = realmPresentationSearchResponseClassifier(),
        failureSlug = ErrorSlug.of("editor-presentation-search-failed"),
        updateFilter = ::matchesRealmPresentationSearch,
    )

private fun realmPresentationSearchResponseClassifier(): ResponseClassifier<RealmPresentationSearchUpdate> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is RealmPresentationSearchUpdate.SnapshotWrapper -> {
                    when (response.value.status) {
                        RealmPresentationSearchStatus.LOADING,
                        RealmPresentationSearchStatus.READY,
                        -> ResponseOutcome.SUCCESS

                        else -> ResponseOutcome.DOMAIN_ERROR
                    }
                }

                is RealmPresentationSearchUpdate.UnavailableWrapper -> {
                    ResponseOutcome.INTERNAL_ERROR
                }

                else -> {
                    ResponseOutcome.DOMAIN_ERROR
                }
            }
        val variant =
            when (response) {
                is RealmPresentationSearchUpdate.SnapshotWrapper -> {
                    when (response.value.status) {
                        RealmPresentationSearchStatus.LOADING -> "loading"
                        RealmPresentationSearchStatus.READY -> "ready"
                        RealmPresentationSearchStatus.ERROR -> "error"
                        else -> "unknown"
                    }
                }

                is RealmPresentationSearchUpdate.UnavailableWrapper -> {
                    "unavailable"
                }

                else -> {
                    "unknown"
                }
            }
        ResponseClassification(outcome, ResponseVariant.of(variant))
    }

private fun matchesRealmPresentationSearch(
    request: RealmPresentationSearchRequest,
    response: RealmPresentationSearchUpdate,
): Boolean =
    when (response) {
        is RealmPresentationSearchUpdate.SnapshotWrapper -> response.value.subscriptionId == request.subscriptionId
        is RealmPresentationSearchUpdate.UnavailableWrapper -> response.value.subscriptionId == request.subscriptionId
        else -> false
    }

private const val SEARCH_OPERATION = "editor.presentation.search"
