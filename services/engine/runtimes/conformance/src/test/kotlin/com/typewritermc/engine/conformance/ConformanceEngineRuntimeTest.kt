package com.typewritermc.engine.conformance

import com.typewritermc.engine.runtime.EngineActivationPlan
import com.typewritermc.engine.runtime.EngineGatewayRegistry
import com.typewritermc.engine.runtime.ReloadableEngineRuntime
import com.typewritermc.extensions.conformance.ConformanceFailureActivator
import com.typewritermc.extensions.generated.CapabilityConformanceBaseExtensionActivators
import com.typewritermc.extensions.generated.CapabilityConformanceCompositeExtensionActivators
import com.typewritermc.extensions.generated.CommonExtensionActivators
import com.typewritermc.extensions.generated.EngineConformanceExtensionActivators
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import java.net.URLClassLoader

val ConformanceEngineRuntimeTest by testSuite {
    test("activates common, transitive capability, and explicit engine registries") {
        runTest {
            val activators =
                CommonExtensionActivators.activators +
                    CapabilityConformanceBaseExtensionActivators.activators +
                    CapabilityConformanceCompositeExtensionActivators.activators +
                    EngineConformanceExtensionActivators.activators
            val runtime =
                ReloadableEngineRuntime(
                    URLClassLoader(emptyArray()),
                    EngineActivationPlan(activators, EngineGatewayRegistry(emptyList())),
                    this,
                )

            runtime.activate()
            runtime.stop()
        }
    }

    test("conformance activation failure aborts the staged runtime") {
        runTest {
            val runtime =
                ReloadableEngineRuntime(
                    URLClassLoader(emptyArray()),
                    EngineActivationPlan(
                        CommonExtensionActivators.activators + ConformanceFailureActivator(),
                        EngineGatewayRegistry(emptyList()),
                    ),
                    this,
                )

            runCatching { runtime.activate() }.isFailure shouldBe true
            runtime.stop()
        }
    }
}
