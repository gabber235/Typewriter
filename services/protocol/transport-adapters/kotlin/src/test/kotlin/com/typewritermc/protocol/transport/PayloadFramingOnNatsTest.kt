package com.typewritermc.protocol.transport

import com.typewritermc.protocol.transport.generated.TRANSPORT_LIMITS
import com.typewritermc.protocol.transport.generated.editorCatalogFetch
import com.typewritermc.protocol.transport.generated.rolloutProbe
import com.typewritermc.protocol.transport.generated.serviceReplyInboxPrefix
import com.typewritermc.protocol.transport.generated.sharedBlobStore
import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ReplyAddressRule
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.disable
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okio.ByteString.Companion.toByteString
import skirout.service.v1.artifact.StoreArtifactBlobRequest
import skirout.service.v1.artifact.StoreArtifactBlobResponse
import java.security.MessageDigest
import java.util.Collections
import java.util.HexFormat
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.BlobMetadata as SkirBlobMetadata
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm

/**
 * Covers payload framing over a real nats-server whose users hold the grants the backend hands out, so NATS
 * enforces max_payload and response permissions. Since a response permission lets a server publish on whatever reply
 * subject a request names, the suite also shows that servers answer only their callers' reply inboxes. The broker runs `src/test/fixtures/payload-framing-nats.conf` and
 * the suite connects to [NATS_URL_VARIABLE]. Without it the suite is skipped locally and fails under CI.
 */
val PayloadFramingOnNatsTest by testSuite(testConfig = brokerTestConfig()) {
    test("a framed blob store request completes through credit windows the host answers under its response permission") {
        brokerFixture { realm, quests, _ ->
            val content = bytes(CHUNK * TRANSPORT_LIMITS.windowFrames * 2 + 5)
            val stored = mutableListOf<ByteArray>()
            realm.serving(
                communicatorRoutes {
                    unaryAt(SCOPE.sharedBlobStore, SCOPE) { call ->
                        stored += call.request.content.toByteArray()
                        StoreArtifactBlobResponse.SuccessWrapper(call.request.expected)
                    }
                },
            ) {
                val expected = content.blobMetadata()

                val response =
                    quests.communicator.request(
                        SCOPE.sharedBlobStore,
                        SCOPE,
                        StoreArtifactBlobRequest(expected = expected, content = content.toByteString()),
                    )

                response.success() shouldBe StoreArtifactBlobResponse.SuccessWrapper(expected)
                stored.single() shouldBe content
            }
        }
    }

    test("a request above the broker's max_payload is framed instead of refused") {
        brokerFixture { realm, quests, _ ->
            val content = bytes(MAX_PAYLOAD + 1)
            realm.serving(
                communicatorRoutes {
                    unaryAt(SCOPE.sharedBlobStore, SCOPE) { call ->
                        StoreArtifactBlobResponse.SuccessWrapper(
                            call.request.content
                                .toByteArray()
                                .blobMetadata(),
                        )
                    }
                },
            ) {
                val response =
                    quests.communicator.request(
                        SCOPE.sharedBlobStore,
                        SCOPE,
                        StoreArtifactBlobRequest(expected = content.blobMetadata(), content = content.toByteString()),
                    )

                response.success() shouldBe StoreArtifactBlobResponse.SuccessWrapper(content.blobMetadata())
            }
        }
    }

    test("a framed reply between services waits for the credits the requester answers under its response permission") {
        brokerFixture { realm, quests, _ ->
            val probe = SCOPE.rolloutProbe.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, it.limits) }
            probe.limits?.replyCredit shouldBe true
            val reply = bytes(CHUNK * TRANSPORT_LIMITS.windowFrames * 2 + 5)
            quests.serving(communicatorRoutes { unaryAt(probe, SCOPE) { reply } }) {
                realm.communicator.request(probe, SCOPE, bytes(1)).success() shouldBe reply
            }
        }
    }

    test("a framed reply to a panel caller streams without credit, since the panel holds no response permission") {
        brokerFixture { realm, _, panel ->
            val fetch = SCOPE.editorCatalogFetch.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, it.limits) }
            (fetch.limits ?: TRANSPORT_LIMITS).replyCredit shouldBe false
            val reply = bytes(CHUNK * TRANSPORT_LIMITS.windowFrames * 2 + 5)
            realm.serving(communicatorRoutes { unaryAt(fetch, SCOPE) { reply } }) {
                panel.communicator.request(fetch, SCOPE, bytes(1)).success() shouldBe reply
            }
        }
    }

    test("a panel request naming a privileged reply subject is not answered there, while its own inbox is") {
        brokerFixture { realm, _, panel ->
            val watcher = watcher()
            val fetch = SCOPE.editorCatalogFetch.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, it.limits) }
            val handled = AtomicInteger()
            realm.serving(communicatorRoutes { unaryAt(fetch, SCOPE) { handled.incrementAndGet().let { bytes(3) } } }) {
                watcher.landedOn(BLOB_STORE_SUBJECT) {
                    panel.requestAimedAt(fetch, BLOB_STORE_SUBJECT)
                    panel.communicator.request(fetch, SCOPE, bytes(1)).success() shouldBe bytes(3)
                } shouldBe emptyList()
            }
            handled.get() shouldBe 1
        }
    }

    test("a service serving a subject it publishes on cannot turn its own request into a publish on a privileged subject") {
        brokerFixture { _, _, _ ->
            val host = connect("host", "${serviceReplyInboxPrefix("host")}.")
            val watcher = watcher()
            val store = SCOPE.sharedBlobStore.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, it.limits) }
            val handled = AtomicInteger()
            host.serving(communicatorRoutes { unaryAt(store, SCOPE) { handled.incrementAndGet().let { bytes(3) } } }) {
                watcher.landedOn(ROLLOUT_PROBE_SUBJECT) {
                    host.requestAimedAt(store, ROLLOUT_PROBE_SUBJECT)
                    host.communicator.request(store, SCOPE, bytes(1)).success() shouldBe bytes(3)
                } shouldBe emptyList()
            }
            handled.get() shouldBe 1
        }
    }

    test("a reply waiting for credit cannot reach a panel caller, whose credit the broker refuses") {
        brokerFixture { realm, _, panel ->
            val credited = TRANSPORT_LIMITS.copy(replyCredit = true, frameInactivity = 2.seconds)
            val fetch = SCOPE.editorCatalogFetch.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, credited) }
            val reply = bytes(CHUNK * TRANSPORT_LIMITS.windowFrames * 2 + 5)
            realm.serving(communicatorRoutes { unaryAt(fetch, SCOPE) { reply } }) {
                panel.communicator.request(fetch, SCOPE, bytes(1)).shouldBeInstanceOf<CommunicationResult.Failure>()
            }
        }
    }
}

/** The environment variable naming the broker; CI always sets it. */
private const val NATS_URL_VARIABLE = "NATS_URL"

// A getter, since the suite reads it while this file's properties are still initializing.
private val natsUrl: String? get() = System.getenv(NATS_URL_VARIABLE)

/**
 * Runs the suite on the wall clock the broker answers on when a broker is named, skips it locally otherwise, and
 * fails under CI where it must never skip.
 */
private fun brokerTestConfig(): TestConfig {
    if (natsUrl != null) return TestConfig.testScope(isEnabled = false)
    check(System.getenv("CI") == null) { "$NATS_URL_VARIABLE must name the payload framing nats-server under CI" }
    return TestConfig.disable()
}

/** The max_payload of the fixture broker, which is the NATS default. */
private const val MAX_PAYLOAD = 1024 * 1024

private val CHUNK = TRANSPORT_LIMITS.chunkBytes

private val SCOPE = RealmRouteScope(organizationId = "writers", realmId = "quests")

private const val PASSWORD = "fixture-secret"

private const val PANEL_INBOX_PREFIX = "_INBOX.alice.0123456789abcdef0123456789abcdef."

/** A subject the panel user alice may not publish to, which the Realm host receives blob stores on. */
private const val BLOB_STORE_SUBJECT = "service.to.quests.organization.writers.realm.shared.blob.store"

/** A subject the dual role host may not publish to, which participants receive rollout probes on. */
private const val ROLLOUT_PROBE_SUBJECT = "service.from.quests.organization.writers.realm.rollout.probe"

/** How long a watcher keeps listening after the exchange, so a late misdirected answer still arrives. */
private val ANSWER_GRACE = 500.milliseconds

/** One broker client: its connection, its transport and a communicator on the generated transport limits. */
private class BrokerClient(
    val connection: NatsConnection,
    val transport: NatsMessageTransport,
    val communicator: Communicator,
)

/** The connected clients of one test; [connect] adds a fixture user the test needs beyond the usual three. */
private class BrokerFixture(
    scope: CoroutineScope,
    private val harness: TelemetryTestHarness,
) : CoroutineScope by scope {
    private val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())
    val clients = mutableListOf<BrokerClient>()

    suspend fun connect(
        user: String,
        inboxPrefix: String,
    ): BrokerClient {
        val connection =
            NatsConnection(
                {
                    NatsConnectionConfiguration(
                        serverUrl = requireNotNull(natsUrl),
                        clientName = user,
                        inboxPrefix = inboxPrefix,
                        maxReconnects = 0,
                    )
                },
                { NatsAuthentication(username = user, password = PASSWORD) },
            )
        connection.connect() shouldBe NatsLifecycleResult.Success
        val transport = NatsMessageTransport(connection, TRANSPORT_LIMITS)
        return BrokerClient(connection, transport, Communicator(transport, harness.telemetry, propagators)).also(clients::add)
    }
}

/**
 * Connects the Realm host, the quests service and the panel user alice, runs [block] and disconnects every client.
 * Services use their generated reply inbox prefix; the panel uses its session inbox.
 */
private suspend fun brokerFixture(block: suspend BrokerFixture.(realm: BrokerClient, quests: BrokerClient, panel: BrokerClient) -> Unit) =
    coroutineScope {
        val harness = TelemetryTestHarness.create()
        val fixture = BrokerFixture(this, harness)
        try {
            fixture.block(
                fixture.connect("realm", "${serviceReplyInboxPrefix("realm")}."),
                fixture.connect("quests", "${serviceReplyInboxPrefix("quests")}."),
                fixture.connect("alice", PANEL_INBOX_PREFIX),
            )
        } finally {
            fixture.clients.forEach { it.connection.shutdown() }
            harness.close()
        }
    }

/** Connects the watcher, which may subscribe to every subject. */
private suspend fun BrokerFixture.watcher() = connect("watcher", "_INBOX.watcher.")

/** Every message published on [subject] while [exchange] runs and for [ANSWER_GRACE] after it. */
private suspend fun BrokerClient.landedOn(
    subject: String,
    exchange: suspend () -> Unit,
): List<InboundMessage> =
    coroutineScope {
        val subscription =
            when (val subscribed = transport.subscribe(AddressPattern.of(subject))) {
                is TransportResult.Success -> subscribed.value
                is TransportResult.Failure -> throw AssertionError("Watching $subject failed with ${subscribed.error}")
            }
        val landed = Collections.synchronizedList(mutableListOf<InboundMessage>())
        val watching =
            launch {
                subscription.deliveries.collect {
                    (it as? TransportDelivery.Message)?.let { delivery ->
                        landed +=
                            delivery.message
                    }
                }
            }
        try {
            exchange()
            delay(ANSWER_GRACE)
        } finally {
            watching.cancel()
            subscription.close()
        }
        landed.toList()
    }

/** Publishes a request to [contract]'s subject at [SCOPE] whose reply subject is [replyTo], as a hostile requester would. */
private suspend fun BrokerClient.requestAimedAt(
    contract: UnaryContract<RealmRouteScope, ByteArray, ByteArray>,
    replyTo: String,
) {
    val request = OutboundMessage(contract.requestAddress.render(SCOPE), bytes(1), replyTo = MessageAddress.of(replyTo))
    transport.publish(request) shouldBe TransportResult.Success(Unit)
}

/** Serves [routes] from this client while [block] runs. */
private suspend fun BrokerClient.serving(
    routes: CommunicatorRoutes,
    block: suspend () -> Unit,
) = coroutineScope {
    val router = communicator.createRouter(routes, this)
    try {
        router.start() shouldBe RouterResult.Success
        block()
    } finally {
        router.stop()
    }
}

private val bytesCodec =
    object : PayloadCodec<ByteArray> {
        override fun encode(value: ByteArray) = Payload.copyOf(value)

        override fun decode(payload: Payload) = payload.toByteArray()
    }

/** A route on a generated subject and limits that carries raw bytes, so a test chooses the exact reply size. */
private fun bytesRoute(
    name: OperationName,
    address: AddressTemplate<RealmRouteScope>,
    replyAddresses: ReplyAddressRule<RealmRouteScope>,
    limits: TransportLimits?,
) = UnaryContract(
    name = name,
    requestAddress = address,
    requestCodec = bytesCodec,
    responseCodec = bytesCodec,
    responsePolicy =
        ResponsePolicy(byteArrayOf()) {
            if (it.isEmpty()) ResponseClassification.internalError("internal") else ResponseClassification.success("bytes")
        },
    replyAddresses = replyAddresses,
    failureSlug = ErrorSlug.of("payload-framing-on-nats-failed"),
    limits = limits,
)

private fun <Value> CommunicationResult<Value>.success(): Value =
    when (this) {
        is CommunicationResult.Success -> value
        is CommunicationResult.Failure -> throw AssertionError("Request failed with $error", error.cause)
    }

private fun ByteArray.blobMetadata() =
    SkirBlobMetadata(
        digest =
            SkirArtifactDigest(
                algorithm = SkirDigestAlgorithm.SHA256,
                value = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(this)),
            ),
        size = size.toLong(),
    )

private fun bytes(size: Int) = ByteArray(size) { (it * 31).toByte() }
