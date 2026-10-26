package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext

val ManagedRuntimeScopeTest by testSuite {
    test("a closing scope refuses new cleanup and new resources") {
        runTest {
            val scope = ManagedRuntimeScope(this, DeploymentFacts())
            val childRunning = CompletableDeferred<Unit>()
            scope.coroutineScope.launch { withContext(NonCancellable) { childRunning.await() } }
            runCurrent()
            val closure = launch { scope.close() }
            runCurrent()
            var lateCleanupRan = false
            var lateResourceClosed = false

            shouldThrow<IllegalStateException> { scope.own { lateCleanupRan = true } }.message shouldBe
                "Runtime scope is already closed."
            shouldThrow<IllegalStateException> { scope.own(AutoCloseable { lateResourceClosed = true }) }.message shouldBe
                "Runtime scope is already closed."

            childRunning.complete(Unit)
            closure.join()
            lateCleanupRan.shouldBeFalse()
            lateResourceClosed.shouldBeFalse()
        }
    }

    test("owned resources close after child coroutines finish, in reverse registration order") {
        runTest {
            val events = mutableListOf<String>()
            val scope = ManagedRuntimeScope(this, DeploymentFacts())
            val releaseChild = CompletableDeferred<Unit>()
            scope.own { events += "first cleanup" }
            scope.own(AutoCloseable { events += "second resource" })
            scope.coroutineScope.launch {
                try {
                    releaseChild.await()
                } finally {
                    withContext(NonCancellable) { releaseChild.await() }
                    events += "child"
                }
            }
            runCurrent()
            val closure = launch { scope.close() }
            runCurrent()
            events shouldContainExactly emptyList()

            releaseChild.complete(Unit)
            closure.join()

            events shouldContainExactly listOf("child", "second resource", "first cleanup")
        }
    }
}
