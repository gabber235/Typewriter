package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transfer.TransferBusy
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse
import kotlin.time.Duration.Companion.minutes

val ReconnectingSharedArtifactAccessTest by testSuite {
    listOf(
        "a payload above the transfer ceiling" to TransportError.Failure(TransferTooLarge(size = 2, limit = 1)),
        "a rejected frame" to TransportError.Failure(TransferRejected("Frame lacks its digest")),
        "a timeout" to TransportError.Timeout(),
    ).forEach { (name, failure) ->
        test("$name fails at once instead of waiting for another session") {
            runTest {
                val fake = FakeMessageTransport()
                fake.failNextRequest(failure)
                val access = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(session(1, fake)))

                withTimeout(1.minutes) {
                    shouldThrow<IllegalStateException> { access.metadata(BLOB.digest) }
                }

                fake.requestCount() shouldBe 1
            }
        }
    }

    test("a busy receiver is asked again after a pause on the same session") {
        runTest {
            val fake = FakeMessageTransport()
            fake.failNextRequest(TransportError.Failure(TransferBusy()))
            fake.answerMetadata()
            val access = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(session(1, fake)))

            access.metadata(BLOB.digest) shouldBe BlobResult.Success(BLOB)

            fake.requestCount() shouldBe 2
            currentTime shouldBe BACK_OFF_DELAYS.first().inWholeMilliseconds
        }
    }

    test("a receiver that stays busy fails once every back off pause is spent") {
        runTest {
            val fake = FakeMessageTransport()
            repeat(BACK_OFF_DELAYS.size + 1) { fake.failNextRequest(TransportError.Failure(TransferBusy())) }
            fake.answerMetadata()
            val access = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(session(1, fake)))

            shouldThrow<IllegalStateException> { access.metadata(BLOB.digest) }

            fake.requestCount() shouldBe BACK_OFF_DELAYS.size + 1
            currentTime shouldBe BACK_OFF_DELAYS.sumOf { it.inWholeMilliseconds }
        }
    }

    test("an unavailable session waits for its replacement and repeats the call there") {
        runTest {
            val lost = FakeMessageTransport()
            lost.failNextRequest(TransportError.Unavailable())
            val sessions = MutableStateFlow<HostedMessagingSession?>(session(1, lost))
            val access = ReconnectingSharedArtifactAccess(REALM, sessions)

            val call = async { access.metadata(BLOB.digest) }
            runCurrent()
            call.isCompleted shouldBe false

            val replacement = FakeMessageTransport()
            replacement.answerMetadata()
            sessions.value = session(2, replacement)

            call.await() shouldBe BlobResult.Success(BLOB)
            lost.requestCount() shouldBe 1
            replacement.requestCount() shouldBe 1
        }
    }
}

private const val REALM = "quests"
private const val ORGANIZATION = "writers"

private val BLOB = "artifact".encodeToByteArray().let { BlobMetadata(ArtifactDigest.sha256(it), it.size.toLong()) }

private fun session(
    id: Long,
    transport: FakeMessageTransport,
) = HostedMessagingSession(
    id,
    ORGANIZATION,
    Communicator(transport, OpenTelemetry.noop().serviceTelemetry("artifact access test"), ContextPropagators.noop()),
)

private fun FakeMessageTransport.requestCount() = actions.count { it is FakeMessageTransport.Action.Request }

/** Answers the next request with the metadata of [BLOB], as a Realm host that holds it does. */
private fun FakeMessageTransport.answerMetadata() =
    respondWith { message, _ ->
        val contract = RealmRouteScope(realmId = REALM, organizationId = ORGANIZATION).sharedBlobMetadata
        TransportResult.Success(
            InboundMessage(
                message.address,
                contract.responseCodec.encode(FetchArtifactBlobMetadataResponse.SuccessWrapper(BLOB.toSkir())),
            ),
        )
    }
