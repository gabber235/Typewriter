package com.typewritermc.capability

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.FlowCollector
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlin.reflect.KClass

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class RealmCapabilities

object RealmCapability {
    @Target(AnnotationTarget.FUNCTION)
    @Retention(AnnotationRetention.BINARY)
    annotation class Search

    @Target(AnnotationTarget.FUNCTION)
    @Retention(AnnotationRetention.BINARY)
    annotation class Computation

    @Target(AnnotationTarget.FUNCTION)
    @Retention(AnnotationRetention.BINARY)
    annotation class Command
}

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

data class RealmSearchQuery(
    val normalizedQuery: String,
    val terms: List<String> = emptyList(),
    val selectors: List<RealmSearchSelector> = emptyList(),
    val selectorExpression: RealmSearchSelectorExpression? = null,
)

data class RealmSearchSelector(
    val id: String,
    val key: String,
    val value: String?,
)

sealed interface RealmSearchSelectorExpression {
    data class Selector(
        val id: String,
    ) : RealmSearchSelectorExpression

    data class And(
        val left: RealmSearchSelectorExpression,
        val right: RealmSearchSelectorExpression,
    ) : RealmSearchSelectorExpression

    data class Or(
        val left: RealmSearchSelectorExpression,
        val right: RealmSearchSelectorExpression,
    ) : RealmSearchSelectorExpression

    data class Not(
        val expression: RealmSearchSelectorExpression,
    ) : RealmSearchSelectorExpression
}

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

interface RealmSearchContext : RealmInvocationContext

interface RealmComputationContext : RealmInvocationContext

interface RealmCommandContext : RealmInvocationContext

class RealmCapabilityPermissionDeniedException(
    message: String,
) : RuntimeException(message)

data class ResourceAddress(
    val type: TypeUse,
    val identity: DataValue,
)

enum class NotificationSeverity {
    INFO,
    SUCCESS,
    WARNING,
    ERROR,
}

sealed interface PanelInstruction {
    data class InvalidateResource(
        val resource: ResourceAddress,
    ) : PanelInstruction

    data class OpenResource(
        val resource: ResourceAddress,
    ) : PanelInstruction

    data class Notify(
        val severity: NotificationSeverity,
        val message: String,
    ) : PanelInstruction
}

data class RealmCommandOutcome(
    val instructions: List<PanelInstruction> = emptyList(),
)

fun <Source : Any, Target : Any> RealmSearch<Source>.mapValues(transform: (Source) -> Target): RealmSearch<Target> =
    RealmSearch(
        updates.map { update ->
            when (update) {
                is RealmSearchUpdate.Partial -> RealmSearchUpdate.Partial(update.values.map(transform), update.guidance)
                RealmSearchUpdate.Complete -> RealmSearchUpdate.Complete
            }
        },
    )

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

sealed interface RealmCapabilityProvider {
    val descriptor: RealmCapabilityDescriptor
}

interface RealmSearchCapabilityProvider : RealmCapabilityProvider {
    fun invoke(
        context: RealmSearchContext,
        runtime: RealmCapabilityRuntime,
        payload: DataValue,
        query: RealmSearchQuery,
    ): RealmSearch<DataValue>
}

interface RealmComputationCapabilityProvider : RealmCapabilityProvider {
    suspend fun invoke(
        context: RealmComputationContext,
        runtime: RealmCapabilityRuntime,
        payload: DataValue,
    ): DataValue
}

interface RealmCommandCapabilityProvider : RealmCapabilityProvider {
    suspend fun invoke(
        context: RealmCommandContext,
        runtime: RealmCapabilityRuntime,
        payload: DataValue,
    ): RealmCommandOutcome
}

class RealmCapabilityRegistry(
    providers: Collection<RealmCapabilityProvider>,
) {
    private val providersById = providers.associateBy { it.descriptor.id }

    val descriptors: List<RealmCapabilityDescriptor> = providers.map(RealmCapabilityProvider::descriptor).sortedBy { it.id.value }

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
