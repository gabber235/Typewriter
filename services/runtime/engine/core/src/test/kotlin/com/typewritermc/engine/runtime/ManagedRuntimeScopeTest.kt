package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext

val ManagedRuntimeScopeTest by testSuite {
    test("rejects both ownership overloads while joining children before releasing resources") {
        runTest {
            val events = mutableListOf<String>()
            val scope = ManagedRuntimeScope(this, DeploymentFacts())
            val releaseChild = CompletableDeferred<Unit>()
            scope.own { events += "cleanup" }
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

            shouldThrow<IllegalStateException> { scope.own { events += "late" } }
            shouldThrow<IllegalStateException> { scope.own(AutoCloseable { events += "late resource" }) }
            events shouldContainExactly emptyList()
            releaseChild.complete(Unit)
            closure.join()
            scope.close()

            events shouldContainExactly listOf("child", "cleanup")
        }
    }
}
