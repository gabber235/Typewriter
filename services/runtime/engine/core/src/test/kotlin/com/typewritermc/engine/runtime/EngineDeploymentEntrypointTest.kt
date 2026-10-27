package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.deploymentContext
import com.typewritermc.loader.api.RuntimePlacement
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val EngineDeploymentEntrypointTest by testSuite {
    test("an engine refuses a deployment whose implementation targets another placement") {
        val context = deploymentContext(runtime = RuntimePlacement.PANEL_ENGINE, implementation = RuntimePlacement.PRIMARY_ENGINE)

        shouldThrow<IllegalArgumentException> { EngineDeploymentEntrypoint().stage(context) }.message shouldBe
            "Engine runtime implementation placement does not match the hosted runtime."
    }

    test("an engine refuses a deployment without an implementation") {
        val context = deploymentContext(runtime = RuntimePlacement.PRIMARY_ENGINE, implementation = null)

        shouldThrow<IllegalArgumentException> { EngineDeploymentEntrypoint().stage(context) }.message shouldBe
            "Engine runtime implementation is missing."
    }
}
