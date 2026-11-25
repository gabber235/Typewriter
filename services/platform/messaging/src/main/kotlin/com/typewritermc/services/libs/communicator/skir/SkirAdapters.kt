package com.typewritermc.services.libs.communicator.skir

import build.skir.Serializer
import build.skir.UnrecognizedValuesPolicy
import build.skir.service.Method
import com.typewritermc.protocol.skir.fromBoundedBytes
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.Messages
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.Replies
import com.typewritermc.services.libs.communicator.contract.ReplyAddressRule
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ScatterContract
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.Payload

/**
 * Adapts this serializer to the communicator codec boundary.
 *
 * Encoding copies the serializer output into immutable payload storage. Decoding applies [unrecognizedValues], so both
 * peers must agree on whether unknown protocol values are dropped or rejected.
 */
fun <Value : Any> Serializer<Value>.asPayloadCodec(
    unrecognizedValues: UnrecognizedValuesPolicy = UnrecognizedValuesPolicy.DROP,
): PayloadCodec<Value> =
    object : PayloadCodec<Value> {
        override fun encode(value: Value): Payload = Payload.copyOf(toBytes(value).toByteArray())

        override fun decode(payload: Payload): Value = fromBoundedBytes(payload.toByteArray(), unrecognizedValues)
    }

/**
 * Creates a unary contract using the request and response serializers declared by [method]. Failures are reported
 * under [OperationName.failureSlug] of [name].
 */
fun <Address : Any, Request : Any, Response : Any> skirUnaryContract(
    method: Method<Request, Response>,
    name: OperationName,
    address: AddressTemplate<Address>,
    responsePolicy: ResponsePolicy<Response>,
    replyAddresses: ReplyAddressRule<Address>,
    limits: TransportLimits? = null,
): UnaryContract<Address, Request, Response> =
    UnaryContract(
        name,
        Messages(address, method.requestSerializer.asPayloadCodec()),
        Replies(method.responseSerializer.asPayloadCodec(), responsePolicy),
        replyAddresses,
        limits = limits,
    )

/**
 * Creates a scatter contract using [method] for both request and response serialization. Failures are reported
 * under [OperationName.failureSlug] of [name].
 */
fun <Address : Any, Request : Any, Response : Any> skirScatterContract(
    method: Method<Request, Response>,
    name: OperationName,
    address: AddressTemplate<Address>,
    responsePolicy: ResponsePolicy<Response>,
    replyAddresses: ReplyAddressRule<Address>,
    limits: TransportLimits? = null,
): ScatterContract<Address, Request, Response> =
    ScatterContract(
        name,
        Messages(address, method.requestSerializer.asPayloadCodec()),
        Replies(method.responseSerializer.asPayloadCodec(), responsePolicy),
        replyAddresses,
        limits,
    )

/** Creates a watch contract from its [initial] request and [updateSerializer] for updates published on [updateAddress]. */
fun <Address : Any, Request : Any, Initial : Any, Update : Any> skirWatchContract(
    initial: UnaryContract<Address, Request, Initial>,
    updateSerializer: Serializer<Update>,
    updateAddress: AddressTemplate<Address>,
    updateFilter: (Request, Update) -> Boolean = { _, _ -> true },
): WatchContract<Address, Request, Initial, Update> =
    WatchContract(initial, Messages(updateAddress, updateSerializer.asPayloadCodec()), updateFilter)

/** Creates an event contract encoding events with [serializer]. Failures are reported under [OperationName.failureSlug] of [name]. */
fun <Address : Any, Event : Any> skirEventContract(
    serializer: Serializer<Event>,
    name: OperationName,
    address: AddressTemplate<Address>,
): EventContract<Address, Event> = EventContract(name, address, serializer.asPayloadCodec())
