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

class RealmDiscoverySnapshotStore {
    val snapshots: StateFlow<RealmDiscoverySnapshot?>
        field: MutableStateFlow<RealmDiscoverySnapshot?> = MutableStateFlow(null)

    internal val changes: SharedFlow<RealmDiscoverySnapshot>
        field: MutableSharedFlow<RealmDiscoverySnapshot> =
        MutableSharedFlow(
            extraBufferCapacity = 1,
            onBufferOverflow = BufferOverflow.DROP_OLDEST,
        )

    fun replace(value: RealmDiscoverySnapshot) {
        snapshots.value = value
        check(changes.tryEmit(value)) { "Realm discovery snapshot change could not be published." }
    }

    internal suspend fun awaitChangeSubscriber() {
        changes.subscriptionCount.first { it > 0 }
    }

    fun current(): RealmDiscoverySnapshot? = snapshots.value
}

data class RealmDiscoverySnapshot(
    val discovery: DeploymentDiscoverySnapshot,
    val elements: ElementCatalog,
    val pages: PageCatalog = PageCatalog(emptyList(), emptyList()),
    val presentations: List<skirout.editor.v1.presentation.PresentationDefinition> = emptyList(),
    val capabilities: List<RealmCapabilityDescriptor> = emptyList(),
    val presentationDiagnostics: List<com.typewritermc.presentation.PresentationDiagnostic> = emptyList(),
)
