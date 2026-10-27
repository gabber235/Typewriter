package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ReplyAddressRule
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterOptions
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.transfer.Assembly
import com.typewritermc.services.libs.communicator.transfer.PayloadAssembler
import com.typewritermc.services.libs.communicator.transfer.PayloadPlan
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transfer.planPayload
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark

/** Limits of a route between services, whose framed replies wait for credit. */
val framedLimits: TransportLimits =
    TransportLimits(
        chunkBytes = 64,
        windowFrames = 2,
        requestMaxBytes = 64L * 16,
        replyMaxBytes = 64L * 16,
        frameInactivity = 5.seconds,
        replyTtl = 5.minutes,
        replyCredit = true,
    )

/** The router fixture's limits: a short inactivity, so a missing answer would show as a slow failure. */
val uploadRouterLimits: TransportLimits = framedLimits.copy(frameInactivity = 1.seconds)

/** Address of the framed requests the tests send. */
val framedRequest: MessageAddress = MessageAddress.of("service.to.quests.organization.writers.realm.editor.catalog.fetch")

/** Reply inbox of the framed requests the tests send. */
val framedReply: MessageAddress = MessageAddress.of("_INBOX.sender.window")

/** The target whose `{id}` segment the upload route fills. */
data class UploadTarget(
    val id: String,
)

/** Codec of raw byte payloads, so a contract can carry bytes unchanged. */
val bytesCodec: PayloadCodec<ByteArray> =
    object : PayloadCodec<ByteArray> {
        override fun encode(value: ByteArray) = Payload.copyOf(value)

        override fun decode(payload: Payload) = payload.toByteArray()
    }

/** Answers the reply inboxes MemoryNatsBroker connections use. */
val brokerInboxes: ReplyAddressRule<Any> = ReplyAddressRule { _, reply -> reply.value.startsWith("_INBOX.") }

/** Upload contract whose policy answers an empty reply with an internal error and any other with success. */
val UPLOAD =
    UnaryContract(
        OperationName.of("upload.put"),
        "upload.{id}.put".addressTemplate({ addressValuesOf("id" to it.id) }, { UploadTarget(it.require("id")) }),
        bytesCodec,
        bytesCodec,
        ResponsePolicy(byteArrayOf()) {
            if (it.isEmpty()) {
                ResponseClassification(ResponseOutcome.INTERNAL_ERROR, ResponseVariant.of("internal"))
            } else {
                ResponseClassification(ResponseOutcome.SUCCESS, ResponseVariant.of("success"))
            }
        },
        replyAddresses = brokerInboxes,
        timeout = 5.seconds,
        failureSlug = ErrorSlug.of("upload-put-failed"),
        limits = uploadRouterLimits,
    )

/** Counts the upload requests the router's handler received since the last [withUploadRouter] started. */
val uploadHandled = AtomicInteger()

/** A client that sends upload requests to the `quests` target. */
class UploadClient(
    private val communicator: Communicator,
) {
    /** Uploads [request] and returns the reply bytes, throwing the transfer failure when the upload fails. */
    suspend fun upload(request: ByteArray): ByteArray =
        when (val result = communicator.request(UPLOAD, UploadTarget("quests"), request)) {
            is CommunicationResult.Success -> result.value
            is CommunicationResult.Failure -> throw AssertionError("Upload failed with ${result.error}", result.error.cause)
        }

    /** Uploads [request] and returns the cause of its failure, failing the check if the upload succeeds. */
    suspend fun uploadFailure(request: ByteArray): Throwable? =
        when (val result = communicator.request(UPLOAD, UploadTarget("quests"), request)) {
            is CommunicationResult.Success -> throw AssertionError("Upload unexpectedly succeeded")
            is CommunicationResult.Failure -> result.error.cause
        }
}

/**
 * Runs [block] against a router serving [UPLOAD], which answers every request with its bytes reversed, and a client
 * on a second broker connection. [intercept] may drop or alter the broker's messages on their way.
 */
suspend fun withUploadRouter(
    options: RouterOptions = RouterOptions(),
    intercept: (BrokerMessage) -> List<BrokerMessage> = { listOf(it) },
    block: suspend (MemoryNatsBroker, UploadClient) -> Unit,
) = coroutineScope {
    uploadHandled.set(0)
    val broker = MemoryNatsBroker(intercept)
    val harness = TelemetryTestHarness.create()
    val serverTransport = broker.transport(uploadRouterLimits)
    val routes =
        communicatorRoutes {
            unaryAt(UPLOAD, UploadTarget("quests")) { call ->
                uploadHandled.incrementAndGet()
                call.request.reversedArray()
            }
        }
    val router =
        CommunicatorRouter(
            serverTransport,
            routes,
            Communicator(serverTransport, harness.telemetry, testPropagators),
            harness.telemetry,
            testPropagators,
            this,
            options,
        )
    try {
        val started = router.start()
        check(started == RouterResult.Success) { "The upload router failed to start: $started" }
        val clientTransport = broker.transport(uploadRouterLimits)
        block(broker, UploadClient(Communicator(clientTransport, harness.telemetry, testPropagators)))
    } finally {
        router.stop()
        harness.close()
    }
}

/**
 * Answers every request on [framedRequest] with [reply], as if each arrived at [received], and records the reply
 * results into [results].
 */
suspend fun serveReplies(
    transport: NatsMessageTransport,
    reply: ByteArray,
    results: MutableList<TransportResult<Unit>> = mutableListOf(),
    received: TimeMark? = null,
) = coroutineScope {
    val subscription = (transport.subscribe(AddressPattern.of(framedRequest.value)) as TransportResult.Success).value
    try {
        subscription.deliveries.collect { delivery ->
            val message = (delivery as? TransportDelivery.Message)?.message ?: return@collect
            launch { results += transport.reply(OutboundMessage(requireNotNull(message.replyTo), reply), received = received) }
        }
    } finally {
        subscription.close()
    }
}

/** Requests [payload] on [framedRequest] from a fresh client and returns the complete reply, throwing its transfer failure. */
suspend fun MemoryNatsBroker.request(
    payload: ByteArray,
    limits: TransportLimits = framedLimits,
): ByteArray {
    val transport = transport(limits)
    while (activeSubscriptionCount == 0) yield()
    return when (val result = transport.request(OutboundMessage(framedRequest, payload), 5.seconds)) {
        is TransportResult.Success -> result.value.payload.toByteArray()
        is TransportResult.Failure -> throw result.error.cause ?: AssertionError("Request failed with ${result.error}")
    }
}

/** Messages published to reply inboxes by the responder, excluding credits the requester sent back. */
fun MemoryNatsBroker.replies(): List<PublishedMessage> =
    published.filter { it.subject.startsWith("_INBOX.") && it.header("Typewriter-Credit") == null }

/** Deterministic bytes of [size]: each byte is its index scaled by 31 and shifted by [seed]. */
fun bytes(
    size: Int,
    seed: Int = 0,
) = ByteArray(size) { (it * 31 + seed).toByte() }

/** The one result a responder recorded, waiting briefly because it records after its last message went out. */
suspend fun <Value> List<Value>.awaitSingle(): Value =
    withTimeout(5.seconds) {
        while (isEmpty()) delay(10.milliseconds)
        single()
    }

/** The cause of a failed result, or null when the failure carries none. */
fun TransportResult<*>.failureCause(): Throwable? = ((this as TransportResult.Failure).error as? TransportError.Failure)?.cause

/**
 * The answer at the window end of a new upload of four chunks, whose bytes only fit once an abandoned upload is gone.
 * [seed] varies the bytes, so each upload is distinct.
 */
internal suspend fun PayloadAssembler.windowEndOfUpload(seed: Int): Assembly {
    val upload =
        framedLimits.planPayload(
            Payload.copyOf(bytes(framedLimits.chunkBytes * 4, seed = seed)),
            framedLimits.requestMaxBytes,
        ) as PayloadPlan.Framed
    accept(InboundMessage(framedRequest, upload.frames[0].payload, headers = upload.frames[0].headers))
    return accept(InboundMessage(framedRequest, upload.frames[1].payload, framedReply, upload.frames[1].headers))
}
