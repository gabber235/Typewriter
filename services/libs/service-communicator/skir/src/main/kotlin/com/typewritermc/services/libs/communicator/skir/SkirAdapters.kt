package com.typewritermc.services.libs.communicator.skir

import build.skir.Serializer
import build.skir.UnrecognizedValuesPolicy
import build.skir.service.Method
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** Adapts this serializer to a codec with explicit unknown-value handling. */
fun <Value : Any> Serializer<Value>.asPayloadCodec(
    unrecognizedValues: UnrecognizedValuesPolicy = UnrecognizedValuesPolicy.DROP,
): PayloadCodec<Value> = object : PayloadCodec<Value> {
    override fun encode(value: Value): ByteArray = toBytes(value).toByteArray()

    override fun decode(payload: ByteArray): Value = fromBytes(payload, unrecognizedValues)
}

/** Creates a validated unary contract while keeping address and failure semantics explicit. */
fun <Address : Any, Request : Any, Response : Any> skirUnaryContract(
    method: Method<Request, Response>,
    name: OperationName,
    address: AddressTemplate<Address>,
    responsePolicy: ResponsePolicy<Response>,
    failureSlug: ErrorSlug,
    timeout: Duration = 10.seconds,
): UnaryContract<Address, Request, Response> = UnaryContract(
    name,
    address,
    method.requestSerializer.asPayloadCodec(),
    method.responseSerializer.asPayloadCodec(),
    responsePolicy,
    timeout,
    failureSlug,
)

/** Creates a watch contract from an initial request method and separate update serializer. */
fun <Address : Any, Request : Any, Initial : Any, Update : Any> skirWatchContract(
    method: Method<Request, Initial>,
    updateSerializer: Serializer<Update>,
    name: OperationName,
    requestAddress: AddressTemplate<Address>,
    updateAddress: AddressTemplate<Address>,
    initialPolicy: ResponsePolicy<Initial>,
    updateClassifier: ResponseClassifier<Update>,
    failureSlug: ErrorSlug,
    timeout: Duration = 10.seconds,
    updateFilter: (Request, Update) -> Boolean = { _, _ -> true },
): WatchContract<Address, Request, Initial, Update> = WatchContract(
    name,
    requestAddress,
    updateAddress,
    method.requestSerializer.asPayloadCodec(),
    method.responseSerializer.asPayloadCodec(),
    updateSerializer.asPayloadCodec(),
    initialPolicy,
    updateClassifier,
    timeout,
    failureSlug,
    updateFilter,
)
