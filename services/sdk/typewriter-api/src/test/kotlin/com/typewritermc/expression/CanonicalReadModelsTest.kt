package com.typewritermc.expression

import com.typewritermc.types.ColorDefinition
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val CanonicalReadModelsTest by testSuite {
    test("declared types keep their authored identity in the canonical read models") {
        CanonicalReadModels.definitions.single { it.id == ColorDefinition.id } shouldBe ColorDefinition.declaration
    }
}
