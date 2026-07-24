package com.typewritermc.services.libs.communicator.contract

import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.telemetry.ErrorSlug
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** Stable low-cardinality operation name. */
@JvmInline
value class OperationName private constructor(val value: String) {
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
value class ResponseVariant private constructor(val value: String) {
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
    SUCCESS, DOMAIN_ERROR, INTERNAL_ERROR,
}

/** Semantic response outcome and stable variant. */
data class ResponseClassification(val outcome: ResponseOutcome, val variant: ResponseVariant)

/** Classification and internal-failure response policy for replying operations. */
class ResponsePolicy<Response : Any>(
    val internalFailureResponse: Response,
    val classify: (Response) -> ResponseClassification,
) {
    init {
        require(classify(internalFailureResponse).outcome == ResponseOutcome.INTERNAL_ERROR) {
            "ResponsePolicy.internalFailureResponse must classify as INTERNAL_ERROR"
        }
    }
}

/** Binary payload encoder and decoder. */
interface PayloadCodec<Value : Any> {
    fun encode(value: Value): ByteArray
    fun decode(payload: ByteArray): Value
}

/** Typed unary request/reply operation contract. */
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

/** Typed event publication contract. */
class EventContract<Address : Any, Event : Any>(
    val name: OperationName,
    val address: AddressTemplate<Address>,
    val codec: PayloadCodec<Event>,
    val failureSlug: ErrorSlug,
)

/** Typed request and streamed-update operation contract. */
class WatchContract<Address : Any, Request : Any, Update : Any>(
    val name: OperationName,
    val requestAddress: AddressTemplate<Address>,
    val updateAddress: AddressTemplate<Address>,
    val requestCodec: PayloadCodec<Request>,
    val updateCodec: PayloadCodec<Update>,
    val responsePolicy: ResponsePolicy<Update>,
    val failureSlug: ErrorSlug,
)
