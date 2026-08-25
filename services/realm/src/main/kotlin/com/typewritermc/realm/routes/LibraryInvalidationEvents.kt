package com.typewritermc.realm.routes

import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.repository.LibraryInvalidation
import com.typewritermc.realm.repository.LibraryResourceKind
import skirout.library.v2.authoring.WatchLibraryInvalidationsResponse
import skirout.library.v2.authoring.LibraryResourceKind as WireResourceKind

class LibraryInvalidationEvents {
    @Volatile
    private var encoder: ((LibraryInvalidation) -> List<OutboxEvent>)? = null

    internal fun configure(
        contracts: LibraryContracts,
        address: RealmAddress,
    ) {
        encoder = { invalidation ->
            listOf(
                contracts.watchLibraryInvalidations.encodeUpdate(
                    address,
                    WatchLibraryInvalidationsResponse.createInvalidated(
                        batchId = invalidation.batchId.value,
                        revision = invalidation.revision,
                        resources = invalidation.resources.map(LibraryResourceKind::toWire),
                    ),
                ),
            )
        }
    }

    fun encode(invalidation: LibraryInvalidation): List<OutboxEvent> = encoder?.invoke(invalidation).orEmpty()
}

private fun LibraryResourceKind.toWire(): WireResourceKind =
    when (this) {
        LibraryResourceKind.BOOK -> WireResourceKind.BOOK
        LibraryResourceKind.PAGE -> WireResourceKind.PAGE
        LibraryResourceKind.TAG -> WireResourceKind.TAG
    }
