package com.typewritermc.services.libs.communicator.contract

import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.telemetry.ErrorSlug
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** Stable low-cardinality operation name. */
@JvmInline
value class OperationName private constructor(
    val value: String,
) {
    /** Creates a validated operation name. */
    companion object {
        fun of(value: String): OperationName {
            require(value.matches(Regex("[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*"))) { "Invalid operation name '$value'" }
            return OperationName(value)
        }
    }
}

/** Stable response variant name. */
@JvmInline
value class ResponseVariant private constructor(
    val value: String,
) {
    /** Creates a validated response variant. */
    companion object {
        fun of(value: String): ResponseVariant {
            require(value.matches(Regex("[a-z][a-z0-9-]*"))) { "Invalid response variant '$value'" }
            return ResponseVariant(value)
        }
    }
}

/** Semantic outcome of a typed response. */
enum class ResponseOutcome {
    SUCCESS,
    DOMAIN_ERROR,
    INTERNAL_ERROR,
}

/** Semantic response outcome and stable variant. */
data class ResponseClassification(
    val outcome: ResponseOutcome,
    val variant: ResponseVariant,
)

/** Typed result of classifying a normal response. */
internal sealed interface OperationOutcome<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : OperationOutcome<Value>

    data class DomainError<Value>(
        val value: Value,
    ) : OperationOutcome<Value>

    data class InternalError<Value>(
        val value: Value,
    ) : OperationOutcome<Value>
}

internal fun <Value> ResponseClassification.operationOutcome(value: Value): OperationOutcome<Value> =
    when (outcome) {
        ResponseOutcome.SUCCESS -> OperationOutcome.Success(value)
        ResponseOutcome.DOMAIN_ERROR -> OperationOutcome.DomainError(value)
        ResponseOutcome.INTERNAL_ERROR -> OperationOutcome.InternalError(value)
    }

/** Classifies a typed response into its semantic outcome and stable variant. */
fun interface ResponseClassifier<Response : Any> {
    fun classify(response: Response): ResponseClassification
}

/**
 * Pairs a safe internal failure response with semantic classification of normal replies.
 *
 * Handlers and clients use the same classification for telemetry. Domain rejection remains a typed response; it is
 * distinct from a transport or codec failure.
 */
class ResponsePolicy<Response : Any>(
    val internalFailureResponse: Response,
    private val classifier: ResponseClassifier<Response>,
) : ResponseClassifier<Response> by classifier {
    init {
        require(classify(internalFailureResponse).outcome == ResponseOutcome.INTERNAL_ERROR) {
            "ResponsePolicy.internalFailureResponse must classify as INTERNAL_ERROR"
        }
    }
}

/**
 * Converts a contract payload between typed values and immutable bytes.
 *
 * Codec failures may throw and are classified by communicator boundaries. Implementations must use the same wire
 * representation on both ends.
 */
interface PayloadCodec<Value : Any> {
    fun encode(value: Value): Payload

    fun decode(payload: Payload): Value
}

/**
 * Defines a typed request with one reply, timeout, response semantics, and failure identity.
 *
 * A contract is metadata shared by caller and router; constructing it creates no subscription.
 */
class UnaryContract<Address : Any, Request : Any, Response : Any>(
    val name: OperationName,
    val requestAddress: AddressTemplate<Address>,
    val requestCodec: PayloadCodec<Request>,
    val responseCodec: PayloadCodec<Response>,
    val responsePolicy: ResponsePolicy<Response>,
    val timeout: Duration = 10.seconds,
    val failureSlug: ErrorSlug,
) {
    init {
        require(timeout.isPositive() && timeout.isFinite()) { "Unary timeout must be positive and finite" }
    }
}

/**
 * Defines a request that can receive replies from multiple listeners through one reply channel.
 *
 * Collection lifetime and completion policy are supplied by the caller. Responders may deliberately decline to
 * reply.
 */
class ScatterContract<Address : Any, Request : Any, Response : Any>(
    val name: OperationName,
    val requestAddress: AddressTemplate<Address>,
    val requestCodec: PayloadCodec<Request>,
    val responseCodec: PayloadCodec<Response>,
    val responsePolicy: ResponsePolicy<Response>,
    val failureSlug: ErrorSlug,
)

/**
 * Defines a typed publication with no application reply.
 *
 * Successful publication means transport acceptance, not confirmation that every consumer processed the event.
 */
class EventContract<Address : Any, Event : Any>(
    val name: OperationName,
    val address: AddressTemplate<Address>,
    val codec: PayloadCodec<Event>,
    val failureSlug: ErrorSlug,
)

/**
 * Combines an initial request with a separate update subscription and optional update filtering.
 *
 * The client subscribes before requesting initial state to reduce lost updates. Snapshot and update consistency
 * still belongs to the application protocol; this metadata provides no transactional snapshot boundary.
 */
class WatchContract<Address : Any, Request : Any, Initial : Any, Update : Any>(
    val name: OperationName,
    val requestAddress: AddressTemplate<Address>,
    val updateAddress: AddressTemplate<Address>,
    val requestCodec: PayloadCodec<Request>,
    val initialCodec: PayloadCodec<Initial>,
    val updateCodec: PayloadCodec<Update>,
    val initialPolicy: ResponsePolicy<Initial>,
    val updateClassifier: ResponseClassifier<Update>,
    val timeout: Duration = 10.seconds,
    val failureSlug: ErrorSlug,
    val updateFilter: (Request, Update) -> Boolean = { _, _ -> true },
) {
    init {
        require(timeout.isPositive() && timeout.isFinite()) { "Watch timeout must be positive and finite" }
    }
}

/** A watch's single initial response or subsequent update. */
sealed interface WatchMessage<out Initial : Any, out Update : Any> {
    data class Initial<Value : Any>(
        val value: Value,
    ) : WatchMessage<Value, Nothing>

    data class Update<Value : Any>(
        val value: Value,
    ) : WatchMessage<Nothing, Value>
}
