package com.typewritermc.loader.work

import com.typewritermc.loader.api.work.WorkRuntime
import com.typewritermc.loader.api.work.testing.RecordedWork
import com.typewritermc.loader.api.work.testing.WorkEvent
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.artifact.testing.BLOB
import com.typewritermc.loader.rollout.testing.Backend
import com.typewritermc.loader.testing.withIdleHost
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** What the loader does for itself counts as its host's own work, as what a runtime does counts as that runtime's. */
val LoaderWorkTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("a task the host runs for itself counts as its own work, in no runtime, from its dispatch until it ran") {
        val recorded = RecordedWork()
        val scope = HostWork(recorded.work, 1.seconds).scope(CoroutineScope(Dispatchers.Default))
        var runtimeWhileRunning: WorkRuntime? = WorkRuntime("not read")

        scope
            .launch(CoroutineName("inbox")) {
                runtimeWhileRunning =
                    recorded.work.items
                        .single()
                        .runtime
            }.join()
        while (recorded.work.count > 0) delay(1.milliseconds)
        scope.cancel()

        runtimeWhileRunning shouldBe null
        recorded.events shouldContainExactly listOf(WorkEvent.Began("loader task inbox", null), WorkEvent.Ended("loader task inbox"))
    }

    test("a file the host's blob store reads counts as the host's own work until it was read") {
        val recorded = RecordedWork()
        val root = Files.createTempDirectory("typewriter-loader-work")
        try {
            val blobs = FileDigestBlobStore(root, io = HostWork(recorded.work, 1.seconds).io)

            blobs.fetch(BLOB.digest) shouldBe BlobResult.NotFound

            recorded.events shouldContainExactly listOf(WorkEvent.Began("loader io", null), WorkEvent.Ended("loader io"))
        } finally {
            root.toFile().deleteRecursively()
        }
    }

    test("the host's registration and the request opening its assignment watch count as its own work until their replies are back") {
        runTest {
            Backend().use { backend ->
                val recorded = RecordedWork()

                backend.source(ready = true, work = recorded.work).assignments().first()

                val requests = recorded.eventsOf("request")
                requests.filterIsInstance<WorkEvent.Began>().map { it.subjects } shouldBe listOf(null, null)
                requests.filterIsInstance<WorkEvent.Ended>().size shouldBe 2
            }
        }
    }

    test("a started host runs its own background work as its own work") {
        runTest {
            val recorded = RecordedWork()
            withIdleHost(recorded.work, 1.seconds, OpenTelemetry.noop()) { host ->
                recorded.eventsOf("loader task").shouldNotBeEmpty()
                host.stop()
            }
        }
    }
}
