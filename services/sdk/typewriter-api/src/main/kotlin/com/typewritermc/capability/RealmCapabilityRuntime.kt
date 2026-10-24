package com.typewritermc.capability

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.complete
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.FlowCollector
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.capability.CommandCapabilityDefinition
import skirout.editor.v1.capability.ComputationCapabilityDefinition
import skirout.editor.v1.capability.PanelInstruction
import skirout.editor.v1.capability.SearchCapabilityDefinition
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse
import kotlin.reflect.KClass

sealed interface RealmCapabilityRef<Request : Any> {
    val id: CapabilityId
    val requestType: KClass<Request>
}

data class RealmSearchCapabilityRef<Request : Any, Result : Any>(
    override val id: CapabilityId,
    override val requestType: KClass<Request>,
    val resultType: KClass<Result>,
) : RealmCapabilityRef<Request>

data class RealmComputationCapabilityRef<Request : Any, Result : Any>(
    override val id: CapabilityId,
    override val requestType: KClass<Request>,
    val resultType: KClass<Result>,
) : RealmCapabilityRef<Request>

data class RealmCommandCapabilityRef<Request : Any>(
    override val id: CapabilityId,
    override val requestType: KClass<Request>,
) : RealmCapabilityRef<Request>

/**
 * One search invocation: the decoded [payload] and the editor [query] as it arrived on the wire.
 *
 * The Realm validates the query before invoking a provider, so selector identities and keys are non blank and the
 * selector expression contains only known variants.
 */
data class RealmSearchRequest<Request : Any>(
    val payload: Request,
    val query: RealmSearchQuery,
)

sealed interface RealmSearchUpdate<out Result : Any> {
    data class Partial<Result : Any>(
        val values: List<Result>,
        val guidance: List<String> = emptyList(),
    ) : RealmSearchUpdate<Result>

    data object Complete : RealmSearchUpdate<Nothing>
}

class RealmSearch<Result : Any> internal constructor(
    val updates: Flow<RealmSearchUpdate<Result>>,
)

class RealmSearchEmitter<Result : Any> internal constructor(
    private val collector: FlowCollector<RealmSearchUpdate<Result>>,
) {
    suspend fun partial(
        values: Iterable<Result>,
        guidance: List<String> = emptyList(),
    ) {
        collector.emit(RealmSearchUpdate.Partial(values.toList(), guidance))
    }

    suspend fun complete() {
        collector.emit(RealmSearchUpdate.Complete)
    }
}

fun <Result : Any> realmSearch(block: suspend RealmSearchEmitter<Result>.() -> Unit): RealmSearch<Result> =
    RealmSearch(flow { RealmSearchEmitter(this).block() })

interface RealmInvocationContext {
    val invocationId: String
}

data class ResourceOperationSearchContext(
    val invocation: com.typewritermc.operations.OperationInvocation,
    val reads: com.typewritermc.authoring.AuthoredReads,
)

interface RealmSearchContext : RealmInvocationContext {
    val operationContext: ResourceOperationSearchContext? get() = null
}

interface RealmComputationContext : RealmInvocationContext

interface RealmCommandContext : RealmInvocationContext

class RealmCapabilityPermissionDeniedException(
    message: String,
) : RuntimeException(message)

data class RealmCommandOutcome(
    val instructions: List<PanelInstruction> = emptyList(),
)

@GeneratedSdkApi
fun <Source : Any, Target : Any> RealmSearch<Source>.mapValues(transform: (Source) -> Target): RealmSearch<Target> =
    RealmSearch(
        updates.map { update ->
            when (update) {
                is RealmSearchUpdate.Partial -> RealmSearchUpdate.Partial(update.values.map(transform), update.guidance)
                RealmSearchUpdate.Complete -> RealmSearchUpdate.Complete
            }
        },
    )

/**
 * Bridges a discovered capability's portable request and result types to native Kotlin bindings.
 * Decoding requires complete schema admission and reports unfinished, invalid, or unresolved content through
 * [NativeBindingException]. This bridge does not select a provider or authorize an invocation.
 */
class RealmCapabilityRuntime(
    private val catalog: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
) {
    fun <T : Any> decode(
        type: TypeUse,
        payload: DataValue,
    ): T {
        val checked = resolve(type)
        val complete =
            when (val result = checked.complete(payload)) {
                is CompletenessResult.Complete -> result.value

                is CompletenessResult.Unfinished -> throw NativeBindingException(
                    "unfinished_capability_value",
                    result.locations.joinToString(),
                )

                is CompletenessResult.Invalid -> throw NativeBindingException("invalid_capability_value", result.problems.joinToString())
            }
        @Suppress("UNCHECKED_CAST")
        return bindings.bind(checked).decode(complete) as T
    }

    fun encode(
        type: TypeUse,
        value: Any,
    ): DataValue {
        val checked = resolve(type)
        @Suppress("UNCHECKED_CAST")
        return (bindings.bind(checked) as NativeBinding<Any>).encode(value)
    }

    private fun resolve(type: TypeUse) =
        when (val resolution = catalog.resolve(type)) {
            is Resolution.Ready -> resolution.value
            is Resolution.Invalid -> throw NativeBindingException("unresolved_capability_type", resolution.diagnostics.joinToString())
        }
}

/** A Realm capability implementation; [definition] is the catalog form of its kind specific descriptor. */
sealed interface RealmCapabilityProvider {
    val definition: CapabilityDefinition
}

interface RealmSearchCapabilityProvider : RealmCapabilityProvider {
    val descriptor: SearchCapabilityDefinition

    override val definition: CapabilityDefinition get() = CapabilityDefinition.SearchWrapper(descriptor)

    fun invoke(
        context: RealmSearchContext,
        runtime: RealmCapabilityRuntime,
        payload: DataValue,
        query: RealmSearchQuery,
    ): RealmSearch<DataValue>
}

interface RealmComputationCapabilityProvider : RealmCapabilityProvider {
    val descriptor: ComputationCapabilityDefinition

    override val definition: CapabilityDefinition get() = CapabilityDefinition.ComputationWrapper(descriptor)

    suspend fun invoke(
        context: RealmComputationContext,
        runtime: RealmCapabilityRuntime,
        payload: DataValue,
    ): DataValue
}

interface RealmCommandCapabilityProvider : RealmCapabilityProvider {
    val descriptor: CommandCapabilityDefinition

    override val definition: CapabilityDefinition get() = CapabilityDefinition.CommandWrapper(descriptor)

    suspend fun invoke(
        context: RealmCommandContext,
        runtime: RealmCapabilityRuntime,
        payload: DataValue,
    ): RealmCommandOutcome
}

class RealmCapabilityRegistry(
    providers: Collection<RealmCapabilityProvider>,
) {
    private val providersById = providers.associateBy { it.definition.id }

    val definitions: List<CapabilityDefinition> = providers.map(RealmCapabilityProvider::definition).sortedBy { it.id.value }

    init {
        require(providersById.size == providers.size) { "Realm capability ids must be unique." }
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
