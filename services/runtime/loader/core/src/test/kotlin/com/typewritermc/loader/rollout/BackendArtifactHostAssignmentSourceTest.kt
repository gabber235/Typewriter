package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.rollout.testing.ASSIGNMENT_HOST
import com.typewritermc.loader.rollout.testing.Backend
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration.Companion.seconds

val BackendArtifactHostAssignmentSourceTest by testSuite {
    test("a ready host registers before it watches and then receives its Realm assignment") {
        runTest {
            Backend().use { backend ->
                val assignment = backend.source(ready = true).assignments().first()

                backend.events shouldContainExactly listOf("register", "watch")
                assignment.revision shouldBe ExecutionRevision(ASSIGNMENT_HOST, 1)
                assignment.assignment?.roles shouldBe setOf(RuntimePlacement.REALM, RuntimePlacement.PANEL_ENGINE)
            }
        }
    }

    test("a failed registration is retried before the host watches") {
        runTest {
            Backend(failedRegistrations = 1).use { backend ->
                backend.source(ready = true).assignments().first()

                backend.events shouldContainExactly listOf("register", "register", "watch")
            }
        }
    }

    test("a host that is not ready registers nothing and emits no assignment") {
        runTest {
            Backend().use { backend ->
                withTimeoutOrNull(10.seconds) { backend.source(ready = false).assignments().first() }.shouldBeNull()

                backend.events.shouldBeEmpty()
            }
        }
    }
}
