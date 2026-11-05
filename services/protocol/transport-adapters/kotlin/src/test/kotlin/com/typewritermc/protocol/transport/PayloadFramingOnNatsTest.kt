package com.typewritermc.protocol.transport

import com.typewritermc.protocol.transport.generated.TRANSPORT_LIMITS
import com.typewritermc.protocol.transport.generated.editorCatalogFetch
import com.typewritermc.protocol.transport.generated.rolloutProbe
import com.typewritermc.protocol.transport.generated.serviceReplyInboxPrefix
import com.typewritermc.protocol.transport.generated.sharedBlobStore
import com.typewritermc.protocol.transport.testing.SCOPE
import com.typewritermc.protocol.transport.testing.blobMetadata
import com.typewritermc.protocol.transport.testing.brokerFixture
import com.typewritermc.protocol.transport.testing.bytes
import com.typewritermc.protocol.transport.testing.bytesRoute
import com.typewritermc.protocol.transport.testing.landedOn
import com.typewritermc.protocol.transport.testing.requestAimedAt
import com.typewritermc.protocol.transport.testing.serving
import com.typewritermc.protocol.transport.testing.success
import com.typewritermc.protocol.transport.testing.watcher
import com.typewritermc.services.libs.communicator.result.CommunicationError
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.transfer.TransferInterrupted
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import okio.ByteString.Companion.toByteString
import skirout.service.v1.artifact.StoreArtifactBlobRequest
import skirout.service.v1.artifact.StoreArtifactBlobResponse
import java.nio.file.Path
import java.util.concurrent.atomic.AtomicInteger
import kotlin.io.path.readText
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * Covers payload framing over a real nats-server whose users hold the grants the backend hands out, so NATS
 * enforces max_payload and response permissions. Since a response permission lets a server publish on whatever reply
 * subject a request names, the suite also shows that servers answer only their callers' reply inboxes. The suite starts
 * its own broker on `src/test/fixtures/payload-framing-nats.conf` and runs on the wall clock the broker answers on.
 */
val PayloadFramingOnNatsTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val chunk = TRANSPORT_LIMITS.chunkBytes

    val broker = testFixture { NatsTestServer.start(Path.of(BROKER_CONFIG).readText()) }

    test("a framed blob store request completes through credit windows the host answers under its response permission") {
        brokerFixture(broker().url) { realm, quests, _ ->
            val content = bytes(chunk * TRANSPORT_LIMITS.windowFrames * 2 + 5)
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
        brokerFixture(broker().url) { realm, quests, _ ->
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
        brokerFixture(broker().url) { realm, quests, _ ->
            val probe = SCOPE.rolloutProbe.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, it.limits) }
            probe.limits?.replyCredit shouldBe true
            val reply = bytes(chunk * TRANSPORT_LIMITS.windowFrames * 2 + 5)
            quests.serving(communicatorRoutes { unaryAt(probe, SCOPE) { reply } }) {
                realm.communicator.request(probe, SCOPE, bytes(1)).success() shouldBe reply
            }
        }
    }

    test("a framed reply to a panel caller streams without credit, since the panel holds no response permission") {
        brokerFixture(broker().url) { realm, _, panel ->
            val fetch = SCOPE.editorCatalogFetch.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, it.limits) }
            (fetch.limits ?: TRANSPORT_LIMITS).replyCredit shouldBe false
            val reply = bytes(chunk * TRANSPORT_LIMITS.windowFrames * 2 + 5)
            realm.serving(communicatorRoutes { unaryAt(fetch, SCOPE) { reply } }) {
                panel.communicator.request(fetch, SCOPE, bytes(1)).success() shouldBe reply
            }
        }
    }

    test("a panel request naming a privileged reply subject is not answered there, while its own inbox is") {
        brokerFixture(broker().url) { realm, _, panel ->
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
        brokerFixture(broker().url) { _, _, _ ->
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
        brokerFixture(broker().url) { realm, _, panel ->
            val credited = TRANSPORT_LIMITS.copy(replyCredit = true, frameInactivity = 2.seconds)
            val fetch = SCOPE.editorCatalogFetch.let { bytesRoute(it.name, it.requestAddress, it.replyAddresses, credited) }
            val reply = bytes(chunk * TRANSPORT_LIMITS.windowFrames * 2 + 5)
            realm.serving(communicatorRoutes { unaryAt(fetch, SCOPE) { reply } }) {
                val started = TimeSource.Monotonic.markNow()
                val result = panel.communicator.request(fetch, SCOPE, bytes(1))

                // Both sides wait the frame inactivity: the caller for the next frame, the host for the credit. Whichever gives
                // up first decides whether the caller sees its own timeout or the host's interruption; either ends the call
                // long before its timeout.
                when (val error = result.shouldBeInstanceOf<CommunicationResult.Failure>().error) {
                    is CommunicationError.Timeout -> Unit
                    is CommunicationError.Transport -> error.cause.shouldBeInstanceOf<TransferInterrupted>()
                    else -> throw AssertionError("Expected the frame inactivity to end the call, got $error")
                }
                started.elapsedNow() shouldBeLessThan fetch.timeout
            }
        }
    }
}

/** The broker configuration: users holding the grants the backend hands out. */
private const val BROKER_CONFIG = "src/test/fixtures/payload-framing-nats.conf"

/** The max_payload of the fixture broker, which is the NATS default. */
private const val MAX_PAYLOAD = 1024 * 1024

/** A subject the panel user alice may not publish to, which the Realm host receives blob stores on. */
private const val BLOB_STORE_SUBJECT = "service.to.quests.organization.writers.realm.shared.blob.store"

/** A subject the dual role host may not publish to, which participants receive rollout probes on. */
private const val ROLLOUT_PROBE_SUBJECT = "service.from.quests.organization.writers.realm.rollout.probe"
