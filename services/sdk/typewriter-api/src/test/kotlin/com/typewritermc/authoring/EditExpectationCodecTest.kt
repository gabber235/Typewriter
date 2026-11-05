package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring_facts.EditExpectation

val EditExpectationCodecTest by testSuite {
    test("set facts are canonical: duplicates collapse and members follow one order") {
        val quest = ResourceId("quest").toSkir()
        val chapter = ResourceId("chapter").toSkir()

        EditExpectation.ResourceIdsWrapper(listOf(quest, chapter, quest)).requireValid() shouldBe
            EditExpectation.resourceIds(listOf(chapter, quest))
    }

    test("a set fact with a blank resource id is refused") {
        shouldThrow<IllegalArgumentException> {
            EditExpectation.ResourceIdsWrapper(listOf(ResourceId("quest").toSkir().copy(value = ""))).requireValid()
        }.message shouldBe "Resource ids must not be blank."
    }
}
