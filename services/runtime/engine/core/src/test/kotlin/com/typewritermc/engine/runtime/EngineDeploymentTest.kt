package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.deploymentContext
import com.typewritermc.engine.runtime.testing.wiredDeploymentContext
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.testing.OnlineSet
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.loader.api.RuntimePlacement
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import org.koin.dsl.module
import java.nio.file.Files
import kotlin.time.Duration.Companion.seconds

val EngineDeploymentTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("an engine refuses a deployment whose implementation targets another placement") {
        val context = deploymentContext(runtime = RuntimePlacement.PANEL_ENGINE, implementation = RuntimePlacement.PRIMARY_ENGINE)

        shouldThrow<IllegalArgumentException> { EngineDeployment(module { }).stage(context) }.message shouldBe
            "Engine runtime implementation placement does not match the hosted runtime."
    }

    test("an engine refuses a deployment without an implementation") {
        val context = deploymentContext(runtime = RuntimePlacement.PRIMARY_ENGINE, implementation = null)

        shouldThrow<IllegalArgumentException> { EngineDeployment(module { }).stage(context) }.message shouldBe
            "Engine runtime implementation is missing."
    }

    test("work an engine kind part starts in the scope it receives ends when the deployment closes") {
        val artifact = Files.createTempDirectory("engine")
        val started = CompletableDeferred<Job>()
        val kind =
            module {
                single<SessionTimings> { SessionHarness.SHORT }
                single<OnlineSessions> { OnlineSet() }
                single(createdAtStart = true) { get<CoroutineScope>().launch { awaitCancellation() }.also(started::complete) }
            }
        val deployment = EngineDeployment(kind).stage(wiredDeploymentContext(runtimeArtifact = artifact))
        val work = started.await()

        deployment.close()

        withTimeout(10.seconds) { work.join() }
        work.isCancelled shouldBe true
        Files.delete(artifact)
    }
}
