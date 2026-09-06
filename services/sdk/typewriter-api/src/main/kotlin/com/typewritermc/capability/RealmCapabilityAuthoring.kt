package com.typewritermc.capability

import com.typewritermc.types.AbstractTypePrototype
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDecodingContext
import com.typewritermc.types.TypeEncodingContext
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.FlowCollector
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlin.reflect.KClass

/**
 * Marks a class whose annotated methods are processed into Realm capability providers and typed references.
 *
 * Use [RealmCapability] annotations to distinguish streamed searches, computations, and commands.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class RealmCapabilities

/**
 * Classifies generated Realm operations by invocation shape.
 *
 * Search produces updates, computation produces one value, and command produces panel instructions. The
 * classification supplies dispatch metadata; it does not itself enforce authorization or purity.
 */
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

/**
 * Identifies a Realm operation together with the Kotlin request type used by generated callers.
 *
 * Use the specialized search, computation, or command reference to preserve the operation shape.
 */
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
 * Carries normalized search text and parsed selector structure to a search capability.
 *
 * Selector expression leaves refer to selector ids. This data class does not normalize text or validate those
 * references; the invocation boundary supplies validated input.
 */
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

/**
 * Streams partial result batches and an explicit completion signal from a Realm search.
 *
 * Guidance accompanies a partial batch. Flow termination and the [Complete] value are distinct: the emitter does
 * not automatically append a completion update.
 */
sealed interface RealmSearchUpdate<out Result : Any> {
    data class Partial<Result : Any>(
        val values: List<Result>,
        val guidance: List<String> = emptyList(),
    ) : RealmSearchUpdate<Result>

    data object Complete : RealmSearchUpdate<Nothing>
}

/**
 * Wraps the update flow returned by a search capability.
 *
 * Searches built with [realmSearch] are cold: collecting starts the producer, and each collection runs it again.
 * Collection cancellation propagates to the producer.
 */
class RealmSearch<Result : Any> internal constructor(
    val updates: Flow<RealmSearchUpdate<Result>>,
)

/**
 * Emits search updates into the current flow collector with suspending backpressure.
 *
 * [complete] emits a protocol marker; it does not prevent further emissions or terminate the producer block. Emit
 * it deliberately as the final update.
 */
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

/**
 * Builds a cold search whose producer runs when updates are collected.
 *
 * The block owns completion signalling and propagates exceptions to the collector. Use
 * [RealmSearchEmitter.partial] for batches and [RealmSearchEmitter.complete] for explicit successful completion.
 */
fun <Result : Any> realmSearch(block: suspend RealmSearchEmitter<Result>.() -> Unit): RealmSearch<Result> =
    RealmSearch(
        flow {
            RealmSearchEmitter(this).block()
        },
    )

/**
 * Identifies one Realm invocation for handlers and their operation specific contexts.
 *
 * The identifier correlates work; it is not an authorization credential.
 */
interface RealmInvocationContext {
    val invocationId: String
}

interface RealmSearchContext : RealmInvocationContext

interface RealmComputationContext : RealmInvocationContext

interface RealmCommandContext : RealmInvocationContext

/**
 * Signals an authorization refusal that the Realm invocation boundary can map to its permission denied result.
 *
 * Throw with a safe caller facing explanation rather than secret policy or credential details.
 */
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

/**
 * Describes requested panel effects after a Realm command.
 *
 * Instructions are data returned to the caller. Constructing an instruction does not invalidate, navigate, or
 * display anything on its own.
 */
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

/**
 * Returns panel instructions from a completed command.
 *
 * An empty list is a valid outcome. The returned instructions do not constitute a transaction with any server side
 * effects performed by the command.
 */
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

/**
 * Decodes a capability payload through the registered concrete or abstract prototype.
 *
 * The registry must contain the request type and any nested codecs. Missing prototypes and invalid payloads throw
 * for the invocation boundary to classify.
 */
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

/**
 * Encodes a capability result using this deployment registry.
 *
 * Abstract types dispatch through the concrete runtime prototype. Missing or incompatible codecs fail rather than
 * falling back to reflection serialization.
 */
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
