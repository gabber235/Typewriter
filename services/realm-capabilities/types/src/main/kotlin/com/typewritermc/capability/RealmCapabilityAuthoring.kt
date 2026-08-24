package com.typewritermc.capability

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDecodingContext
import com.typewritermc.types.TypeEncodingContext
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.AbstractTypePrototype
import com.typewritermc.types.ConcreteTypePrototype
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

@JvmInline
value class CapabilityId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Capability IDs must not be blank." }
    }
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

fun <Result : Any> realmSearch(
    block: suspend RealmSearchEmitter<Result>.() -> Unit,
): RealmSearch<Result> =
    RealmSearch(
        flow {
            RealmSearchEmitter(this).block()
        },
    )

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
    val type: ResolvedTypeRef,
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

fun <Source : Any, Target : Any> RealmSearch<Source>.mapValues(
    transform: (Source) -> Target,
): RealmSearch<Target> =
    RealmSearch(
        updates.map { update ->
            when (update) {
                is RealmSearchUpdate.Partial -> RealmSearchUpdate.Partial(update.values.map(transform), update.guidance)
                RealmSearchUpdate.Complete -> RealmSearchUpdate.Complete
            }
        },
    )

fun <T : Any> TypePrototypeRegistry.decodeCapabilityValue(
    type: KClass<T>,
    value: DataValue,
): T {
    val context = RegistryCodecContext(this)
    return when (val prototype = require(type)) {
        is ConcreteTypePrototype<T> -> with(context) { prototype.decode(value) }
        is AbstractTypePrototype<T> -> with(this) { with(context) { prototype.decode(value) } }
        else -> error("Type prototype cannot decode capability values: ${prototype.type}")
    }
}

fun <T : Any> TypePrototypeRegistry.encodeCapabilityValue(
    type: KClass<T>,
    value: T,
): DataValue {
    val context = RegistryCodecContext(this)
    return when (val prototype = require(type)) {
        is ConcreteTypePrototype<T> -> with(context) { prototype.encode(value) }
        is AbstractTypePrototype<T> -> with(this) { with(context) { prototype.encode(value) } }
        else -> error("Type prototype cannot encode capability values: ${prototype.type}")
    }
}

private class RegistryCodecContext(
    override val prototypes: TypePrototypeRegistry,
) : TypeEncodingContext,
    TypeDecodingContext
