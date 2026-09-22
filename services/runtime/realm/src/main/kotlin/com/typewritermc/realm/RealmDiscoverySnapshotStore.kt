package com.typewritermc.realm

import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.pages.PageCatalog
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import skirout.editor.v1.presentation.SearchSelectorDefinition

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
    val resourceDefinitions: List<AuthoringResourceDefinition> = emptyList(),
    val relations: List<com.typewritermc.types.RelationDefinition> = emptyList(),
    val collectionProjections: List<skirout.editor.v1.authoring.CollectionProjectionDefinition> = emptyList(),
    val creationSlots: List<AuthoringCreationSlotDefinition> = emptyList(),
    val authoringSearch: AuthoringSearchDefinition? = null,
    val compilationProjections: List<skirout.editor.v1.catalog.AuthoringCompilationProjectionDefinition> = emptyList(),
    val elements: ElementCatalog,
    val pages: PageCatalog = PageCatalog(emptyList(), emptyList()),
    val presentations: List<skirout.editor.v1.presentation.PresentationDefinition> = emptyList(),
    val capabilities: List<RealmCapabilityDescriptor> = emptyList(),
    val presentationDiagnostics: List<com.typewritermc.presentation.PresentationDiagnostic> = emptyList(),
)

/** Realm supplied search controls and indexed facets for authored resources. */
data class AuthoringSearchDefinition(
    val definitions: List<ResourceDefinitionId>,
    val selectors: List<SearchSelectorDefinition>,
    val facets: List<AuthoringSearchFacetDefinition>,
)

data class AuthoringSearchFacetDefinition(
    val id: String,
    val label: String,
    val selectorId: String,
)

/** Stable identity for one Realm supplied creation context. */
typealias AuthoringCreationHostCardinality = com.typewritermc.authoring.AuthoringCreationHostCardinality
typealias AuthoringCreationHostFilter = com.typewritermc.authoring.AuthoringCreationHostFilter
typealias AuthoringCreationRelationDirection = com.typewritermc.authoring.AuthoringCreationRelationDirection
typealias AuthoringCreationSlotDefinition = com.typewritermc.authoring.AuthoringCreationSlotDefinition
typealias AuthoringCreationSlotId = com.typewritermc.authoring.AuthoringCreationSlotId
typealias AuthoringResourceDefinition = com.typewritermc.authoring.AuthoringResourceDefinition
typealias ResourceDefinitionId = com.typewritermc.authoring.ResourceDefinitionId

/** Contributes resource definitions without requiring a central resource family switch. */
fun interface AuthoringResourceDefinitionProvider {
    fun definitions(): Collection<AuthoringResourceDefinition>
}

/** Validated definition catalog shared by Realm persistence and authoring routes. */
class AuthoringResourceDefinitionCatalog private constructor(
    definitions: Collection<AuthoringResourceDefinition>,
) {
    val definitions: List<AuthoringResourceDefinition> = definitions.toList()
    private val byId = this.definitions.associateBy(AuthoringResourceDefinition::id)

    init {
        require(this.definitions.size == byId.size) {
            "Resource definition ids must be unique."
        }
    }

    operator fun get(id: ResourceDefinitionId): AuthoringResourceDefinition? = byId[id]

    companion object {
        fun assemble(providers: Collection<AuthoringResourceDefinitionProvider>): AuthoringResourceDefinitionCatalog =
            AuthoringResourceDefinitionCatalog(providers.flatMap(AuthoringResourceDefinitionProvider::definitions))
    }
}

/** Stable ids for the definitions supplied by the core Realm runtime. */
object CoreResourceDefinitionIds {
    val BOOK = ResourceDefinitionId("typewriter.book")
    val TAG = ResourceDefinitionId("typewriter.tag")
    val PAGE = ResourceDefinitionId("typewriter.page")
    val ELEMENT = ResourceDefinitionId("typewriter.element")
}
