package com.typewritermc.engine.pages

import com.typewritermc.types.TypeDisplay
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val CorePageTypeDisplayTest by testSuite {
    test("core page providers publish their declared display metadata") {
        SequencePageDefinition.display shouldBe
            TypeDisplay(
                name = "Sequence",
                description = "",
                icon = "material-symbols:account-tree",
                color = "#2196F3",
            )
        StaticPageDefinition.display shouldBe
            TypeDisplay(
                name = "Static",
                description = "",
                icon = "material-symbols:push-pin",
                color = "#673AB7",
            )
        ScenePageDefinition.display shouldBe
            TypeDisplay(
                name = "Scene",
                description = "",
                icon = "material-symbols:movie",
                color = "#FF9800",
            )
        ManifestPageDefinition.display shouldBe
            TypeDisplay(
                name = "Manifest",
                description = "",
                icon = "material-symbols:schema",
                color = "#4CAF50",
            )
    }
}
