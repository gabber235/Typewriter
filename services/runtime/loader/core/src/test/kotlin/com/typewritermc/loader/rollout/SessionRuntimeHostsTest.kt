package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkItem
import com.typewritermc.loader.api.work.WorkObserver
import com.typewritermc.loader.api.work.WorkRuntime
import com.typewritermc.loader.artifact.ReconnectingSharedArtifactAccess
import com.typewritermc.loader.artifact.testing.BLOB
import com.typewritermc.loader.artifact.testing.REALM
import com.typewritermc.loader.artifact.testing.answerMetadata
import com.typewritermc.loader.testing.hostedSession
import com.typewritermc.loader.work.HostWork
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.time.Duration.Companion.seconds

/** Each runtime a host stages sees the host through its own view, so the work it causes names it. */
val SessionRuntimeHostsTest by testSuite {
    test("a runtime's messaging and shared artifact operations count as its own work in the host's total") {
        val work = InFlightWork()
        val began = mutableListOf<WorkRuntime?>()
        work.observe(
            object : WorkObserver {
                override fun began(item: WorkItem) {
                    began += item.runtime
                }

                override fun ended(
                    item: WorkItem,
                    failure: Throwable?,
                ) = Unit
            },
        )
        val transport = FakeMessageTransport()
        transport.answerMetadata()
        val session = hostedSession(transport)
        val hosts =
            SessionRuntimeHosts(
                HostWork(work, 10.seconds),
                ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(session)),
                OpenTelemetry.noop(),
                null,
            )
        hosts.follow(session)
        val engine = WorkRuntime("primary engine")
        val view = hosts.open(engine)

        ReconnectingSharedArtifactAccess(REALM, view.messaging).metadata(BLOB.digest) shouldBe BlobResult.Success(BLOB)
        transport.answerMetadata()
        view.sharedArtifacts.metadata(BLOB.digest) shouldBe BlobResult.Success(BLOB)

        began shouldContainExactly listOf(engine, engine)
        work.count shouldBe 0
    }

    test("a runtime's view follows every session the host replaces until the view closes") {
        val first = hostedSession(FakeMessageTransport(), id = 1)
        val hosts =
            SessionRuntimeHosts(
                HostWork(InFlightWork(), 10.seconds),
                ReconnectingSharedArtifactAccess(REALM, MutableStateFlow(first)),
                OpenTelemetry.noop(),
                null,
            )
        val view = hosts.open(WorkRuntime("realm"))

        view.messaging.value shouldBe null
        hosts.follow(first)
        view.messaging.value?.id shouldBe 1L
        view.close()
        hosts.follow(hostedSession(FakeMessageTransport(), id = 2))

        view.messaging.value?.id shouldBe 1L
    }
}
