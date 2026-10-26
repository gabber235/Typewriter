package com.typewritermc.realm

import com.typewritermc.loader.api.RuntimeHealth
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

val RealmDeploymentEntrypointTest by testSuite {
    test("successful activation reports Healthy and close releases the Realm") {
        runTest {
            val managed = FakeManagedRealmRuntime()
            val runtime = RealmDeploymentRuntime(managed)

            runtime.health.value shouldBe RuntimeHealth.Staged
            runtime.activate()
            runtime.health.value shouldBe RuntimeHealth.Healthy

            runtime.close()
            managed.released shouldBe true
        }
    }

    test("failed activation reports Unhealthy with its reason and close still releases the Realm") {
        runTest {
            val managed = FakeManagedRealmRuntime(failActivation = true)
            val runtime = RealmDeploymentRuntime(managed)

            runCatching { runtime.activate() }.exceptionOrNull()?.message shouldBe "catalog activation failed"

            runtime.health.value shouldBe RuntimeHealth.Unhealthy("catalog activation failed")
            runtime.close()
            managed.released shouldBe true
        }
    }

    test("quiesce reports Staged and resume reports Healthy again") {
        runTest {
            val runtime = RealmDeploymentRuntime(FakeManagedRealmRuntime())
            runtime.activate()

            runtime.quiesce()
            runtime.health.value shouldBe RuntimeHealth.Staged

            runtime.resume()
            runtime.health.value shouldBe RuntimeHealth.Healthy
        }
    }
}

private class FakeManagedRealmRuntime(
    private val failActivation: Boolean = false,
) : ManagedRealmRuntime {
    var released = false
        private set

    override suspend fun activate() {
        if (failActivation) error("catalog activation failed")
    }

    override suspend fun quiesce() = Unit

    override suspend fun resume() = Unit

    override suspend fun stop() {
        released = true
    }
}
