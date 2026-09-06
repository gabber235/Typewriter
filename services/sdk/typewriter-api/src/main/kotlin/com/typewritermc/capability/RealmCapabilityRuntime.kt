package com.typewritermc.capability

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypePrototypeRegistry

/**
 * Advertises an operation shape and resolved payload types to catalog consumers.
 *
 * Descriptors contain no executable handler. Invocation requires a provider with the same id in
 * [RealmCapabilityRegistry].
 */
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

/**
 * Bridge implemented by generated adapters between authored handlers and generic Realm invocation.
 *
 * [descriptor] resolves handler types through the deployment prototype registry and may fail when required codecs
 * are unavailable.
 */
sealed interface RealmCapabilityProvider {
    val id: CapabilityId

    fun descriptor(prototypes: TypePrototypeRegistry): RealmCapabilityDescriptor
}

/**
 * Adapts a typed search handler into a stream of structural values.
 *
 * The invocation context and registry belong to the calling deployment. Collection owns the lifetime of the
 * resulting search work.
 */
interface RealmSearchCapabilityProvider : RealmCapabilityProvider {
    fun invoke(
        context: RealmSearchContext,
        prototypes: TypePrototypeRegistry,
        payload: DataValue,
        query: RealmSearchQuery,
    ): RealmSearch<DataValue>
}

/**
 * Adapts one suspending computation to structural request and result values.
 *
 * Handler and codec failures propagate to the Realm invocation boundary for classification.
 */
interface RealmComputationCapabilityProvider : RealmCapabilityProvider {
    suspend fun invoke(
        context: RealmComputationContext,
        prototypes: TypePrototypeRegistry,
        payload: DataValue,
    ): DataValue
}

/**
 * Adapts a command handler to a structural request and panel instruction outcome.
 *
 * The adapter does not provide a transaction or retry guarantee for handler side effects.
 */
interface RealmCommandCapabilityProvider : RealmCapabilityProvider {
    suspend fun invoke(
        context: RealmCommandContext,
        prototypes: TypePrototypeRegistry,
        payload: DataValue,
    ): RealmCommandOutcome
}

/**
 * Indexes the capability providers of one deployment and resolves their catalog descriptors.
 *
 * Ids must be globally unique across operation kinds. Typed lookups reject both missing ids and the wrong
 * operation kind. Descriptors are sorted by id for stable publication.
 */
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
