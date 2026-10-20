package com.typewritermc.engine.pages

import com.typewritermc.types.Color
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
                color = Color(0xFF2196F3u),
            )
        StaticPageDefinition.display shouldBe
            TypeDisplay(
                name = "Static",
                description = "",
                icon = "material-symbols:push-pin",
                color = Color(0xFF673AB7u),
            )
        ScenePageDefinition.display shouldBe
            TypeDisplay(
                name = "Scene",
                description = "",
                icon = "material-symbols:movie",
                color = Color(0xFFFF9800u),
            )
        ManifestPageDefinition.display shouldBe
            TypeDisplay(
                name = "Manifest",
                description = "",
                icon = "material-symbols:schema",
                color = Color(0xFF4CAF50u),
            )
    }
}
