package com.typewritermc.loader.work

import com.typewritermc.loader.api.work.WorkSubjects
import com.typewritermc.loader.api.work.testing.RecordedWork
import com.typewritermc.loader.api.work.testing.WorkEvent
import com.typewritermc.loader.api.work.testing.minecraftSubject
import com.typewritermc.loader.artifact.ReconnectingSharedArtifactAccess
import com.typewritermc.loader.artifact.testing.BLOB
import com.typewritermc.loader.artifact.testing.REALM
import com.typewritermc.loader.artifact.testing.answerMetadata
import com.typewritermc.loader.testing.hostedSession
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.onBroker
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.withContext
import kotlin.time.Duration.Companion.seconds

/** What a runtime does through its host's messaging and shared artifacts counts as in flight work of the host. */
val HostWorkTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("each key value operation of a runtime counts for the subjects of its coroutine until it returns") {
        NatsTestServer.startWithJetStream().use { server ->
            onBroker(server.url) {
                val recorded = RecordedWork()
                val session = hostedSession(FakeMessageTransport()).copy(buckets = buckets()).counted(recorded.work)
                val player = minecraftSubject("8d6c")

                val written =
                    withContext(WorkSubjects(setOf(player))) {
                        val opened = session.buckets.ensure(KeyValueBucketDeclaration("sessions", 1.seconds))
                        val bucket = opened.shouldBeInstanceOf<KeyValueOpen.Opened>().bucket
                        bucket.create("minecraft.8d6c.8d6c", byteArrayOf(1), 60.seconds)
                    }

                written.shouldBeInstanceOf<KeyValueWrite.Written>()
                recorded.events shouldContainExactly
                    listOf(
                        WorkEvent.Began("kv ensure sessions", setOf(player)),
                        WorkEvent.Ended("kv ensure sessions"),
                        WorkEvent.Began("kv create sessions minecraft.8d6c.8d6c", setOf(player)),
                        WorkEvent.Ended("kv create sessions minecraft.8d6c.8d6c"),
                    )
                recorded.work.count shouldBe 0
            }
        }
    }

    test("a key value operation that fails ends its item with the cause, and a lost checked write ends it plainly") {
        NatsTestServer.startWithJetStream().use { server ->
            onBroker(server.url) {
                val recorded = RecordedWork()
                val reachable = hostedSession(FakeMessageTransport()).copy(buckets = buckets()).counted(recorded.work)
                val unreachable = hostedSession(FakeMessageTransport()).counted(recorded.work)

                val bucket = (reachable.buckets.ensure(KeyValueBucketDeclaration("sessions", 1.seconds)) as KeyValueOpen.Opened).bucket
                bucket.create("taken", byteArrayOf(1), 60.seconds)
                bucket.create("taken", byteArrayOf(2), 60.seconds) shouldBe KeyValueWrite.Conflict
                unreachable.buckets.open("sessions").shouldBeInstanceOf<KeyValueOpen.Failed>()

                recorded.eventsOf("kv create").last() shouldBe WorkEvent.Ended("kv create sessions taken")
                recorded.eventsOf("kv open").last() shouldBe
                    WorkEvent.Failed("kv open sessions", "This test messaging reaches no bucket: sessions")
            }
        }
    }

    test("a request through a runtime's communicator counts until its reply is back, and fails its item when it fails") {
        val recorded = RecordedWork()
        val transport = FakeMessageTransport()
        val access = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(hostedSession(transport).counted(recorded.work)))
        transport.answerMetadata()

        access.metadata(BLOB.digest) shouldBe BlobResult.Success(BLOB)
        transport.failNextRequest(TransportError.Timeout())
        shouldThrow<IllegalStateException> { access.metadata(BLOB.digest) }

        val requests = recorded.eventsOf("request")
        requests.map { it::class } shouldContainExactly
            listOf(WorkEvent.Began::class, WorkEvent.Ended::class, WorkEvent.Began::class, WorkEvent.Failed::class)
        (requests.first() as WorkEvent.Began).subjects shouldBe null
        recorded.work.count shouldBe 0
    }

    test("a shared artifact read that throws fails its item with the cause") {
        val recorded = RecordedWork()
        val transport = FakeMessageTransport()
        val shared = ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(hostedSession(transport))).counted(recorded.work)
        transport.failNextRequest(TransportError.Timeout())

        shouldThrow<IllegalStateException> { shared.fetch(BLOB.digest) }

        recorded.eventsOf("blob").map { it::class } shouldContainExactly listOf(WorkEvent.Began::class, WorkEvent.Failed::class)
        recorded.work.count shouldBe 0
    }
}
