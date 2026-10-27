package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.realm.search.IndexedAuthoringSearchCandidate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import skirout.editor.v1.catalog.PreparationOperation
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

/**
 * A search index that has not caught up: it still holds an older version of [book] and a resource [removed] since
 * deleted. Each hit carries the content it was indexed with, not the saved record.
 */
internal class StaleIndex(
    private val book: ResourceId,
    private val removed: ResourceId,
) : AuthoringSearchRepository {
    override fun search(
        view: AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: NamedTypeUse?,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate> =
        listOf(
            IndexedAuthoringSearchCandidate(book, record(name = "Draft Book"), "book Draft Book"),
            IndexedAuthoringSearchCandidate(removed, record(name = "Removed"), "removed Removed"),
        )
}

/** A presentation search source whose subscriptions stay open until they are cancelled; [active] lists the open ones. */
internal class PendingSearchSource(
    private val scope: CoroutineScope,
) : RealmPresentationSearchSource {
    val active = mutableSetOf<String>()
    private val jobs = mutableMapOf<String, Job>()

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        jobs[request.subscriptionId] =
            scope.launch {
                active += request.subscriptionId
                try {
                    awaitCancellation()
                } finally {
                    active -= request.subscriptionId
                }
            }
        // Still loading: the search never delivers values.
        return RealmPresentationSearchUpdate.createSnapshot(
            status = RealmPresentationSearchStatus.LOADING,
            subscriptionId = request.subscriptionId,
            values = emptyList(),
            guidance = emptyList(),
            diagnostics = emptyList(),
        )
    }

    override fun cancel(subscriptionId: String): Boolean = jobs.remove(subscriptionId)?.cancel() != null
}

/** An initialization runtime for a Realm whose catalog routes never prepare a value; any call fails the test. */
internal data object UnusedInitialization : InitializationRuntime {
    override suspend fun step(operation: PreparationOperation): PrepareValueResult = error("Not used")
}
