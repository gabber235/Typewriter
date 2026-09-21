package com.typewritermc.realm

import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.repository.AuthoringResourceKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeExpression
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first

/**
 * Owns the current deployment catalog snapshot and its invalidation notifications.
 *
 * Replace updates StateFlow before emitting a change. Change notifications have a small dropping buffer and are
 * hints to reread current state, not a durable history. Consumers requiring an initial snapshot must read
 * [current] or collect [snapshots].
 */
class RealmDiscoverySnapshotStore {
    val snapshots: StateFlow<RealmDiscoverySnapshot?>
        field: MutableStateFlow<RealmDiscoverySnapshot?> = MutableStateFlow(null)

    internal val changes: SharedFlow<RealmDiscoverySnapshot>
        field: MutableSharedFlow<RealmDiscoverySnapshot> =
        MutableSharedFlow(
            extraBufferCapacity = 1,
            onBufferOverflow = BufferOverflow.DROP_OLDEST,
        )

    /**
     * Makes a snapshot authoritative before notifying consumers that they should reread it.
     *
     * Notifications are best effort hints and may be dropped when the buffer is full. Consumers must use [current]
     * or [snapshots] for data, not reconstruct state from the change stream.
     */
    fun replace(value: RealmDiscoverySnapshot) {
        snapshots.value = value
        check(changes.tryEmit(value)) { "Realm discovery snapshot change could not be published." }
    }

    internal suspend fun awaitChangeSubscriber() {
        changes.subscriptionCount.first { it > 0 }
    }

    /** Returns the latest authoritative snapshot, or null before staged catalog assembly completes. */
    fun current(): RealmDiscoverySnapshot? = snapshots.value
}

/**
 * Combines structural discovery, elements, pages, presentations, and capabilities for one Realm deployment.
 *
 * Editor routes consume this assembled view; diagnostics remain visible alongside valid definitions.
 */
data class RealmDiscoverySnapshot(
    val discovery: DeploymentDiscoverySnapshot,
    val resourceKinds: List<RealmResourceKindDefinition> = emptyList(),
    val relations: List<com.typewritermc.types.RelationDefinition> = emptyList(),
    val collectionProjections: List<skirout.library.v1.authoring.CollectionProjectionDefinition> = emptyList(),
    val elements: ElementCatalog,
    val pages: PageCatalog = PageCatalog(emptyList(), emptyList()),
    val presentations: List<skirout.editor.v1.presentation.PresentationDefinition> = emptyList(),
    val capabilities: List<RealmCapabilityDescriptor> = emptyList(),
    val presentationDiagnostics: List<com.typewritermc.presentation.PresentationDiagnostic> = emptyList(),
)

/** Realm owned persistence and authoring policy for one resource family. */
data class RealmResourceKindDefinition(
    val kind: AuthoringResourceKind,
    val acceptedRoot: TypeExpression,
    val defaultRoot: ResolvedTypeRef? = null,
)
