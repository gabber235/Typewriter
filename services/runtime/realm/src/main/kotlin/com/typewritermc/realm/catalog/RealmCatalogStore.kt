package com.typewritermc.realm.catalog

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.InitializationDescriptor
import com.typewritermc.capability.RealmCapabilityProvider
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.discovery.CatalogAssembly
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.RetainedOwnedProviderRegistry
import com.typewritermc.presentation.CollectionProjectionSpec
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import java.util.concurrent.atomic.AtomicBoolean

data class RealmCatalogIncarnation(
    val assembly: CatalogAssembly,
    val deployment: GeneratedProviderDeployment,
) {
    init {
        require(assembly.snapshot.generation == assembly.checked.generation) {
            "The editor snapshot and checked catalog must use one generation."
        }
    }
}

interface RealmCatalogLease : AuthoringCatalogLease {
    val editorSnapshot: EditorCatalogSnapshot
    val capabilities: List<RealmCapabilityProvider>
    val collectionProjections: List<CollectionProjectionSpec>
}

class RealmCatalogStore : AutoCloseable {
    private val lock = Any()
    private var current: Retention? = null
    private var closed = false
    private val mutableChanges =
        MutableSharedFlow<CatalogGeneration>(
            extraBufferCapacity = 1,
            onBufferOverflow = BufferOverflow.DROP_OLDEST,
        )

    val changes: SharedFlow<CatalogGeneration> = mutableChanges

    fun captureCurrent(): RealmCatalogLease =
        synchronized(lock) {
            check(!closed) { "Realm catalog store is closed." }
            retain(requireNotNull(current) { "Realm catalog is not installed." })
        }

    fun replace(incarnation: RealmCatalogIncarnation) {
        val installed =
            synchronized(lock) {
                check(!closed) { "Realm catalog store is closed." }
                check(current == null) {
                    "Initial Realm catalog replacement cannot be used for an active store."
                }
                Retention(incarnation, current = true).also { current = it }
            }
        check(mutableChanges.tryEmit(installed.incarnation.assembly.snapshot.generation)) {
            "Realm catalog change could not be published."
        }
    }

    override fun close() {
        val retired =
            synchronized(lock) {
                if (closed) return
                closed = true
                val values = listOfNotNull(current)
                values.forEach { it.current = false }
                current = null
                values.filter { it.leases == 0 }
            }
        val failures = retired.mapNotNull { runCatching { it.close() }.exceptionOrNull() }
        if (failures.isNotEmpty()) {
            val failure = failures.first()
            failures.drop(1).forEach(failure::addSuppressed)
            throw failure
        }
    }

    private fun retain(retention: Retention): RealmCatalogLease {
        check(retention.current || retention.leases > 0) { "Realm catalog generation is no longer retained." }
        retention.leases += 1
        return Lease(retention)
    }

    private fun release(retention: Retention) {
        val retired =
            synchronized(lock) {
                check(retention.leases > 0) { "Realm catalog lease count is invalid." }
                retention.leases -= 1
                retention.takeIf { !it.current && it.leases == 0 }
            }
        retired?.close()
    }

    private inner class Lease(
        private val retention: Retention,
    ) : RealmCatalogLease {
        private val open = AtomicBoolean(true)
        private val incarnation get() = retention.incarnation
        private val assembly get() = incarnation.assembly

        override val generation: CatalogGeneration get() = assembly.snapshot.generation
        override val checked: CheckedCatalog get() = assembly.checked
        override val nativeBindings: NativeBindingRegistry get() = assembly.bindings
        override val providers: OwnedProviderRegistry get() = retention.providers
        override val checks: List<OwnedCheckRecipe> get() = assembly.checks
        override val relations: List<RelationContract> get() = assembly.snapshot.relations
        override val endpointBindings: List<EndpointBindingTemplate> get() = assembly.snapshot.endpointBindings
        override val resources: List<AuthoringResourceDefinition> get() = assembly.snapshot.resourceDefinitions
        override val initialization: List<InitializationDescriptor> get() = assembly.snapshot.initialization
        override val configuration: List<ConfigurationRecipe> get() = assembly.snapshot.configuration
        override val editorSnapshot: EditorCatalogSnapshot get() = assembly.snapshot
        override val capabilities: List<RealmCapabilityProvider>
            get() =
                incarnation.deployment.providers.capabilities
                    .map { it.provider }
        override val collectionProjections: List<CollectionProjectionSpec>
            get() =
                incarnation.deployment.providers.collectionProjections
                    .map { it.specification }

        override fun retain(): RealmCatalogLease =
            synchronized(lock) {
                check(open.get()) { "Realm catalog lease is closed." }
                this@RealmCatalogStore.retain(retention)
            }

        override fun close() {
            if (open.compareAndSet(true, false)) release(retention)
        }
    }

    private class Retention(
        val incarnation: RealmCatalogIncarnation,
        var current: Boolean,
    ) : AutoCloseable {
        val providers = RetainedOwnedProviderRegistry(incarnation.assembly.providers, incarnation.deployment)
        var leases = 0

        override fun close() {
            incarnation.deployment.close()
        }
    }
}
