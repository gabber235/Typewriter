package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.runtime
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.work.InFlightWork
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.job
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest

/** A deployment whose scope fails reports itself failed to its host, so a rollout replaces it. */
val EngineScopeFailureTest by testSuite {
    test("a part that throws in the deployment scope makes the deployment report failed with the cause") {
        runTest {
            val deploymentScope = engineScope(InFlightWork())
            val fixture = runtime(emptyList(), deploymentScope = deploymentScope)
            fixture.runtime.activate()

            deploymentScope.launch { throw IllegalStateException("part loop broke") }
            deploymentScope.coroutineContext.job.join()

            val health =
                fixture.runtime.health.value
                    .shouldBeInstanceOf<RuntimeHealth.Unhealthy>()
            health.reason shouldContain "IllegalStateException"
            health.reason shouldContain "part loop broke"
        }
    }
}
