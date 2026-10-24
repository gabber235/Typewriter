package com.typewritermc.realm.deployment

import com.typewritermc.loader.api.RuntimeHealth
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

val RealmDeploymentEntrypointTest by testSuite {
    test("successful activation exposes one healthy staged Realm generation") {
        runTest {
            val managed = RecordingManagedRealmRuntime()
            val runtime = RealmDeploymentRuntime(managed)

            runtime.activate()

            runtime.health.value shouldBe RuntimeHealth.Healthy
            managed.operations shouldContainExactly listOf("activate")
            runtime.close()
            managed.operations shouldContainExactly listOf("activate", "stop")
        }
    }

    test("failed activation stays unavailable until staged Realm resources are drained") {
        runTest {
            val managed = RecordingManagedRealmRuntime(failActivation = true)
            val runtime = RealmDeploymentRuntime(managed)

            runCatching { runtime.activate() }.exceptionOrNull()?.message shouldBe "catalog activation failed"

            runtime.health.value shouldBe RuntimeHealth.Unhealthy("catalog activation failed")
            runtime.close()
            managed.operations shouldContainExactly listOf("activate", "stop")
        }
    }
}

private class RecordingManagedRealmRuntime(
    private val failActivation: Boolean = false,
) : ManagedRealmRuntime {
    val operations = mutableListOf<String>()

    override suspend fun activate() {
        operations += "activate"
        if (failActivation) error("catalog activation failed")
    }

    override suspend fun quiesce() {
        operations += "quiesce"
    }

    override suspend fun resume() {
        operations += "resume"
    }

    override suspend fun stop() {
        operations += "stop"
    }
}
