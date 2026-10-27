package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.artifact.testing.BLOB
import com.typewritermc.loader.artifact.testing.REALM
import com.typewritermc.loader.artifact.testing.answerMetadata
import com.typewritermc.loader.testing.hostedSession
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transfer.TransferBusy
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
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
                val access = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(hostedSession(fake)))

                withTimeout(1.minutes) {
                    shouldThrow<IllegalStateException> { access.metadata(BLOB.digest) }
                }

                fake.requests.size shouldBe 1
            }
        }
    }

    test("a busy receiver is asked again after a pause on the same session") {
        runTest {
            val fake = FakeMessageTransport()
            fake.failNextRequest(TransportError.Failure(TransferBusy()))
            fake.answerMetadata()
            val access = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(hostedSession(fake)))

            access.metadata(BLOB.digest) shouldBe BlobResult.Success(BLOB)

            fake.requests.size shouldBe 2
            currentTime shouldBe BACK_OFF_DELAYS.first().inWholeMilliseconds
        }
    }

    test("a receiver that stays busy fails once every back off pause is spent") {
        runTest {
            val fake = FakeMessageTransport()
            repeat(BACK_OFF_DELAYS.size + 1) { fake.failNextRequest(TransportError.Failure(TransferBusy())) }
            fake.answerMetadata()
            val access = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(hostedSession(fake)))

            shouldThrow<IllegalStateException> { access.metadata(BLOB.digest) }

            fake.requests.size shouldBe BACK_OFF_DELAYS.size + 1
            currentTime shouldBe BACK_OFF_DELAYS.sumOf { it.inWholeMilliseconds }
        }
    }

    test("an unavailable session waits for its replacement and repeats the call there") {
        runTest {
            val lost = FakeMessageTransport()
            lost.failNextRequest(TransportError.Unavailable())
            val sessions = MutableStateFlow<HostedMessagingSession?>(hostedSession(lost))
            val access = ReconnectingSharedArtifactAccess(REALM, sessions)

            val call = async { access.metadata(BLOB.digest) }
            runCurrent()
            call.isCompleted shouldBe false

            val replacement = FakeMessageTransport()
            replacement.answerMetadata()
            sessions.value = hostedSession(replacement, id = 2)

            call.await() shouldBe BlobResult.Success(BLOB)
            lost.requests.size shouldBe 1
            replacement.requests.size shouldBe 1
        }
    }
}
