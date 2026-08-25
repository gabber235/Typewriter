package com.typewritermc.realm.routes

import com.typewritermc.library.PageId
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.repository.PageInvalidation
import com.typewritermc.realm.repository.utils.toSkirRecordId
import skirout.library.v2.authoring.PageInvalidationReason
import skirout.library.v2.authoring.WatchPageDocumentsResponse

class PageDocumentInvalidationEvents {
    @Volatile
    private var encoder: ((String, Long, Set<PageId>, Boolean) -> List<OutboxEvent>)? = null

    internal fun configure(
        contracts: LibraryContracts,
        address: RealmAddress,
    ) {
        encoder = { batchId, revision, pageIds, affectsCompilation ->
            listOf(
                contracts.watchPageDocuments.encodeUpdate(
                    address,
                    WatchPageDocumentsResponse.createInvalidated(
                        batchId = batchId,
                        revision = revision,
                        pageIds = pageIds.map { it.toSkirRecordId() },
                        reason =
                            if (affectsCompilation) {
                                PageInvalidationReason.EXECUTION
                            } else {
                                PageInvalidationReason.LAYOUT
                            },
                    ),
                ),
            )
        }
    }

    fun encode(invalidation: PageInvalidation): List<OutboxEvent> =
        encoder
            ?.invoke(
                invalidation.batchId.value,
                invalidation.revision,
                invalidation.pageIds,
                invalidation.affectsCompilation,
            ).orEmpty()
}
