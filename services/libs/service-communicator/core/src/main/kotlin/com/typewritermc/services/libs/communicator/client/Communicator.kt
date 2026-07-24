package com.typewritermc.services.libs.communicator.client

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.contract.*
import com.typewritermc.services.libs.communicator.result.CommunicationError
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.telemetry.MessageHeadersGetter
import com.typewritermc.services.libs.communicator.telemetry.MessageHeadersSetter
import com.typewritermc.services.libs.communicator.transport.*
import com.typewritermc.services.libs.telemetry.*
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.context.Context
import io.opentelemetry.context.propagation.ContextPropagators
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.transformWhile
import kotlinx.coroutines.withContext
import kotlin.time.Duration

/** Typed outbound communication client with mandatory telemetry and context propagation. */
class Communicator(
    private val transport: MessageTransport,
    private val telemetry: ServiceTelemetry,
    private val propagators: ContextPropagators,
) {
    /** Performs a typed unary request. */
    suspend fun <Address : Any, Request : Any, Response : Any> request(
        contract: UnaryContract<Address, Request, Response>,
        address: Address,
        request: Request,
        headers: MessageHeaders = MessageHeaders.Empty,
        timeout: Duration? = null,
    ): CommunicationResult<Response> {
        val effectiveTimeout = timeout ?: contract.timeout
        require(effectiveTimeout.isPositive() && effectiveTimeout.isFinite()) {
            "Request timeout must be positive and finite"
        }
        val result = operation(
            contract.name.value,
            "request",
            contract.failureSlug,
            SpanKind.CLIENT,
            contract.requestAddress.template
        ) { annotate ->
            val payload = classify(
                block = { contract.requestCodec.encode(request) },
                error = { CommunicationError.Encode(contract.failureSlug, it) })
            val message = outbound(contract.requestAddress.render(address), payload, headers)
            annotate { attribute("messaging.destination.name", message.address.value) }
            val inbound = classifyTransport(contract.failureSlug, transport.request(message, effectiveTimeout))
            val response = classify(block = { contract.responseCodec.decode(inbound.payload) }, error = {
                CommunicationError.Decode(contract.failureSlug, it)
            })
            val classification = contract.responsePolicy.classify(response)
            annotate {
                attribute("domain.outcome", classification.variant.value)
                attribute("operation.outcome", classification.outcome.name.lowercase())
            }
            if (classification.outcome == ResponseOutcome.INTERNAL_ERROR) {
                throw Classified(
                    CommunicationError.Transport(
                        contract.failureSlug,
                        InternalResponseException(response)
                    )
                )
            }
            response
        }
        if (result is CommunicationResult.Failure && result.error.cause is InternalResponseException) {
            val internal = result.error.cause as InternalResponseException
            @Suppress("UNCHECKED_CAST") return CommunicationResult.Success(internal.response as Response)
        }
        return result
    }

    /** Publishes a typed event. */
    suspend fun <Address : Any, Event : Any> publish(
        contract: EventContract<Address, Event>,
        address: Address,
        event: Event,
        headers: MessageHeaders = MessageHeaders.Empty,
    ): CommunicationResult<Unit> = operation(
        contract.name.value,
        "publish",
        contract.failureSlug,
        SpanKind.PRODUCER,
        contract.address.template,
    ) { annotate ->
        val payload = classify(
            block = { contract.codec.encode(event) },
            error = { CommunicationError.Encode(contract.failureSlug, it) })
        val message = outbound(contract.address.render(address), payload, headers)
        annotate { attribute("messaging.destination.name", message.address.value) }
        classifyTransport(contract.failureSlug, transport.publish(message))
    }

    /** Publishes an independent typed watch update. */
    suspend fun <Address : Any, Request : Any, Update : Any> publishUpdate(
        contract: WatchContract<Address, Request, Update>,
        address: Address,
        update: Update,
        headers: MessageHeaders = MessageHeaders.Empty,
    ): CommunicationResult<Unit> {
        val destination = contract.updateAddress.render(address)
        return operation(
            contract.name.value,
            "publish",
            contract.failureSlug,
            SpanKind.PRODUCER,
            contract.updateAddress.template,
        ) { annotate ->
            val classification = contract.responsePolicy.classify(update)
            publishResponse(
                destination,
                update,
                contract.updateCodec,
                classification,
                contract.failureSlug,
                headers,
                annotate
            )
        }.normalizeInternalResponse()
    }

    internal suspend fun <Response : Any> sendResponse(
        name: String,
        template: String?,
        destination: com.typewritermc.services.libs.communicator.address.MessageAddress,
        response: Response,
        codec: PayloadCodec<Response>,
        classification: ResponseClassification,
        failureSlug: ErrorSlug,
        headers: MessageHeaders = MessageHeaders.Empty,
    ): CommunicationResult<Unit> = operation(name, "publish", failureSlug, SpanKind.PRODUCER, template) { annotate ->
        publishResponse(destination, response, codec, classification, failureSlug, headers, annotate)
    }.normalizeInternalResponse()

    private suspend fun <Response : Any> publishResponse(
        destination: com.typewritermc.services.libs.communicator.address.MessageAddress,
        response: Response,
        codec: PayloadCodec<Response>,
        classification: ResponseClassification,
        failureSlug: ErrorSlug,
        headers: MessageHeaders,
        annotate: (TypedAttributes.() -> Unit) -> Unit,
    ) {
        annotate {
            attribute("messaging.destination.name", destination.value)
            attribute("domain.outcome", classification.variant.value)
            attribute("operation.outcome", classification.outcome.name.lowercase())
        }
        val payload = classify({ codec.encode(response) }) { CommunicationError.Encode(failureSlug, it) }
        classifyTransport(failureSlug, transport.publish(outbound(destination, payload, headers)))
        if (classification.outcome == ResponseOutcome.INTERNAL_ERROR) {
            throw Classified(CommunicationError.Transport(failureSlug, InternalResponseException(response)))
        }
    }

    private fun CommunicationResult<Unit>.normalizeInternalResponse(): CommunicationResult<Unit> =
        if (this is CommunicationResult.Failure && error.cause is InternalResponseException) CommunicationResult.Success(
            Unit
        )
        else this

    /** Creates a cold-typed watch flow; every collector owns a subscription. */
    fun <Address : Any, Request : Any, Update : Any> watch(
        contract: WatchContract<Address, Request, Update>,
        address: Address,
        request: Request,
        headers: MessageHeaders = MessageHeaders.Empty,
    ): Flow<CommunicationResult<Update>> = flow {
        val updateAddress = contract.updateAddress.render(address)
        val subscriptionResult = operation(
            contract.name.value,
            "subscribe",
            contract.failureSlug,
            SpanKind.CONSUMER,
            contract.updateAddress.template,
        ) { annotate ->
            annotate { attribute("messaging.destination.name", updateAddress.value) }
            classifyTransport(contract.failureSlug, transport.subscribe(AddressPattern.of(updateAddress.value)))
        }
        val subscription = when (subscriptionResult) {
            is CommunicationResult.Failure -> {
                emit(subscriptionResult)
                return@flow
            }

            is CommunicationResult.Success -> subscriptionResult.value
        }
        var primaryFailure: Throwable? = null
        try {
            val initial = operation(
                contract.name.value,
                "publish",
                contract.failureSlug,
                SpanKind.PRODUCER,
                contract.requestAddress.template,
            ) { annotate ->
                val payload = classify(block = { contract.requestCodec.encode(request) }, error = {
                    CommunicationError.Encode(contract.failureSlug, it)
                })
                val message = outbound(contract.requestAddress.render(address), payload, headers, updateAddress)
                annotate { attribute("messaging.destination.name", message.address.value) }
                classifyTransport(contract.failureSlug, transport.publish(message))
            }
            if (initial is CommunicationResult.Failure) {
                emit(initial)
                return@flow
            }
            subscription.deliveries.transformWhile { delivery ->
                    emit(delivery)
                    delivery is TransportDelivery.Message
                }.collect { delivery ->
                    when (delivery) {
                        TransportDelivery.Completed -> Unit
                        is TransportDelivery.Failure -> emit(
                            terminalWatchFailure(
                                contract,
                                updateAddress.value,
                                delivery.error
                            )
                        )

                        is TransportDelivery.Message -> emit(decodeUpdate(contract, delivery.message))
                    }
                }
        } catch (failure: Throwable) {
            primaryFailure = failure
            throw failure
        } finally {
            try {
                withContext(NonCancellable) { subscription.close() }
            } catch (cleanupFailure: Throwable) {
                rethrowExceptional(cleanupFailure)
                val primary = primaryFailure ?: throw cleanupFailure
                primary.addSuppressed(cleanupFailure)
            }
        }
    }

    private suspend fun <Update : Any> decodeUpdate(
        contract: WatchContract<*, *, Update>,
        message: InboundMessage,
    ): CommunicationResult<Update> {
        val parent = propagators.textMapPropagator.extract(Context.current(), message.headers, MessageHeadersGetter)
        return try {
            val value = telemetry.consumerSpan(
                "${contract.name.value} receive",
                contract.failureSlug,
                parent,
                attributes("receive", contract.name.value, contract.updateAddress.template).toBuilder()
                    .put("messaging.destination.name", message.address.value).build(),
            ) { main ->
                val update = classify(block = { contract.updateCodec.decode(message.payload) }, error = {
                    CommunicationError.Decode(contract.failureSlug, it)
                })
                val classification = contract.responsePolicy.classify(update)
                main.annotate {
                    domainOutcome(classification.variant.value)
                    operationOutcome(classification.outcome.name.lowercase())
                }
                if (classification.outcome == ResponseOutcome.INTERNAL_ERROR) {
                    val error = CommunicationError.Transport(contract.failureSlug, InternalResponseException(update))
                    throw SluggedException.wrap(error.slug, Classified(error))
                }
                update
            }
            CommunicationResult.Success(value)
        } catch (failure: Throwable) {
            val internal = failure.causes().filterIsInstance<InternalResponseException>().firstOrNull()
            if (internal != null) {
                @Suppress("UNCHECKED_CAST") CommunicationResult.Success(internal.response as Update)
            } else {
                recover(failure)
            }
        }
    }

    private suspend fun terminalWatchFailure(
        contract: WatchContract<*, *, *>,
        destination: String,
        transportError: TransportError,
    ): CommunicationResult.Failure {
        val result = operation<Unit>(
            contract.name.value,
            "receive",
            contract.failureSlug,
            SpanKind.CONSUMER,
            contract.updateAddress.template,
        ) { annotate ->
            annotate { attribute("messaging.destination.name", destination) }
            val error = transportError.toCommunicationError(contract.failureSlug)
            throw SluggedException.wrap(error.slug, Classified(error))
        }
        check(result is CommunicationResult.Failure)
        return result
    }

    private suspend fun <Value> operation(
        name: String,
        type: String,
        slug: ErrorSlug,
        kind: SpanKind,
        template: String?,
        block: suspend (annotate: (TypedAttributes.() -> Unit) -> Unit) -> Value,
    ): CommunicationResult<Value> = try {
        val attributes = attributes(type, name, template)
        val currentMain = Context.current().mainSpanScope()
        val value = if (currentMain == null) {
            telemetry.mainSpan(
                "$name $type",
                slug,
                kind,
                attributes = attributes
            ) { main -> block { annotation -> main.annotate { annotation(this) } } }
        } else {
            context(currentMain) {
                childSpan("$name $type", kind, attributes) { child ->
                    block { annotation ->
                        child.annotate {
                            annotation(
                                this
                            )
                        }
                    }
                }
            }
        }
        CommunicationResult.Success(value)
    } catch (failure: Throwable) {
        recover(failure)
    }

    private fun outbound(
        address: com.typewritermc.services.libs.communicator.address.MessageAddress,
        payload: ByteArray,
        headers: MessageHeaders,
        replyTo: com.typewritermc.services.libs.communicator.address.MessageAddress? = null,
    ): OutboundMessage {
        val propagator = propagators.textMapPropagator
        val setter = MessageHeadersSetter(headers, propagator.fields())
        propagator.inject(Context.current(), Unit, setter)
        return OutboundMessage(address, payload, replyTo, setter.headers)
    }

    private fun attributes(type: String, name: String, template: String?): Attributes {
        val attributes =
            Attributes.builder().put("messaging.system", transport.system.value).put("messaging.operation.name", name)
                .put("messaging.operation.type", type)
        if (template != null) attributes.put("messaging.destination.template", template)
        return attributes.build()
    }

    private fun <Value> classify(block: () -> Value, error: (Throwable) -> CommunicationError): Value = try {
        block()
    } catch (failure: Throwable) {
        rethrowExceptional(failure)
        throw SluggedException.wrap(error(failure).slug, Classified(error(failure)))
    }

    private fun <Value> classifyTransport(slug: ErrorSlug, result: TransportResult<Value>): Value = when (result) {
        is TransportResult.Success -> result.value
        is TransportResult.Failure -> {
            val error = result.error.toCommunicationError(slug)
            throw SluggedException.wrap(error.slug, Classified(error))
        }
    }

    private fun recover(failure: Throwable): CommunicationResult.Failure {
        rethrowExceptional(failure)
        val classified = failure.causes().filterIsInstance<Classified>().firstOrNull() ?: throw failure
        return CommunicationResult.Failure(classified.error)
    }

    private class Classified(val error: CommunicationError) : RuntimeException(error.cause)
    private class InternalResponseException(val response: Any) : RuntimeException("Typed internal-error response")
}

private fun TransportError.toCommunicationError(slug: ErrorSlug): CommunicationError = when (this) {
    is TransportError.Timeout -> CommunicationError.Timeout(slug, cause)
    is TransportError.Unavailable -> CommunicationError.Unavailable(slug, cause)
    is TransportError.NoResponders -> CommunicationError.NoResponders(slug, cause)
    is TransportError.Failure -> CommunicationError.Transport(slug, cause)
}

private fun Throwable.causes(): Sequence<Throwable> = sequence {
    val visited = mutableSetOf<Throwable>()
    var current: Throwable? = this@causes
    while (current != null && visited.add(current)) {
        yield(current)
        current = current.cause
    }
}

private fun rethrowExceptional(failure: Throwable) = rethrowExceptionalThrowable(failure)
