package com.typewritermc.extensions.conformance

import com.typewritermc.extensions.generated.CapabilityConformanceBaseExtensionActivators
import com.typewritermc.extensions.generated.CapabilityConformanceCompositeExtensionActivators
import com.typewritermc.extensions.generated.CapabilityMinecraftExtensionActivators
import com.typewritermc.extensions.generated.CommonExtensionActivators
import com.typewritermc.extensions.generated.EngineConformanceExtensionActivators
import com.typewritermc.extensions.generated.EnginePaperExtensionActivators
import com.typewritermc.extensions.generated.PanelExtensionActivators
import com.typewritermc.extensions.generated.RealmExtensionActivators
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.nulls.shouldNotBeNull

val GeneratedActivatorsTest by testSuite {
    test("generates one direct activator for every derived source set") {
        CommonExtensionActivators.activators shouldHaveSize 1
        RealmExtensionActivators.activators shouldHaveSize 1
        PanelExtensionActivators.activators shouldHaveSize 1
        CapabilityMinecraftExtensionActivators.activators shouldHaveSize 1
        CapabilityConformanceBaseExtensionActivators.activators shouldHaveSize 1
        CapabilityConformanceCompositeExtensionActivators.activators shouldHaveSize 1
        EnginePaperExtensionActivators.activators shouldHaveSize 1
        EngineConformanceExtensionActivators.activators shouldHaveSize 1
    }

    test("packages the generated extension manifest") {
        CommonExtensionActivators::class.java
            .getResourceAsStream("/META-INF/typewriter/extension.cbor")
            .shouldNotBeNull()
            .use { stream ->
                stream.readAllBytes().shouldNotBeEmpty()
            }
    }
}
