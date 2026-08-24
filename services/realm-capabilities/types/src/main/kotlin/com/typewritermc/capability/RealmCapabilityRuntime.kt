package com.typewritermc.capability

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypePrototypeRegistry

sealed interface RealmCapabilityDescriptor {
    val id: CapabilityId
    val requestType: ResolvedTypeRef

    data class Search(
        override val id: CapabilityId,
        override val requestType: ResolvedTypeRef,
        val resultType: ResolvedTypeRef,
    ) : RealmCapabilityDescriptor

    data class Computation(
        override val id: CapabilityId,
        override val requestType: ResolvedTypeRef,
        val resultType: ResolvedTypeRef,
    ) : RealmCapabilityDescriptor

    data class Command(
        override val id: CapabilityId,
        override val requestType: ResolvedTypeRef,
    ) : RealmCapabilityDescriptor
}

sealed interface RealmCapabilityProvider {
    val id: CapabilityId

    fun descriptor(prototypes: TypePrototypeRegistry): RealmCapabilityDescriptor
}

interface RealmSearchCapabilityProvider : RealmCapabilityProvider {
    fun invoke(
        context: RealmSearchContext,
        prototypes: TypePrototypeRegistry,
        payload: DataValue,
        query: RealmSearchQuery,
    ): RealmSearch<DataValue>
}

interface RealmComputationCapabilityProvider : RealmCapabilityProvider {
    suspend fun invoke(
        context: RealmComputationContext,
        prototypes: TypePrototypeRegistry,
        payload: DataValue,
    ): DataValue
}

interface RealmCommandCapabilityProvider : RealmCapabilityProvider {
    suspend fun invoke(
        context: RealmCommandContext,
        prototypes: TypePrototypeRegistry,
        payload: DataValue,
    ): RealmCommandOutcome
}

class RealmCapabilityRegistry(
    providers: Collection<RealmCapabilityProvider>,
    prototypes: TypePrototypeRegistry,
) {
    private val providersById = providers.associateBy(RealmCapabilityProvider::id)

    val descriptors: List<RealmCapabilityDescriptor> =
        providers
            .map { it.descriptor(prototypes) }
            .sortedBy { it.id.value }

    init {
        require(providersById.size == providers.size) { "Realm capability IDs must be unique." }
    }

    fun requireSearch(id: CapabilityId): RealmSearchCapabilityProvider =
        requireNotNull(providersById[id] as? RealmSearchCapabilityProvider) {
            "Realm search capability is unavailable: ${id.value}"
        }

    fun requireComputation(id: CapabilityId): RealmComputationCapabilityProvider =
        requireNotNull(providersById[id] as? RealmComputationCapabilityProvider) {
            "Realm computation capability is unavailable: ${id.value}"
        }

    fun requireCommand(id: CapabilityId): RealmCommandCapabilityProvider =
        requireNotNull(providersById[id] as? RealmCommandCapabilityProvider) {
            "Realm command capability is unavailable: ${id.value}"
        }
}
