package com.typewritermc.realm.operation

import com.typewritermc.authoring.with
import com.typewritermc.realm.authoring.record
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import skirout.editor.v1.type_catalog.DataValue
import skirout.kernel.v1.resource_id.ResourceId

val OperationObservationTest by testSuite {
    val quest = ResourceId(value = "quest")

    val saved = mapOf(quest to record(name = "Quest"))

    test("an overlay that replaces and removes the same resource is refused") {
        refusedOverlay(saved, upserts = saved, removals = setOf(quest)) shouldBe "An overlay cannot replace and remove the same resource"
    }

    test("an overlay that removes a resource the saved state does not hold is refused") {
        refusedOverlay(saved, removals = setOf(ResourceId(value = "missing"))) shouldBe "An overlay removes an unknown resource"
    }

    test("an overlay whose resource has invalid authored structure is refused") {
        refusedOverlay(
            saved,
            upserts = mapOf(quest to record(name = "Quest").with("unknown", DataValue.StringValueWrapper("stray"))),
        ) shouldStartWith
            "An overlay resource has invalid authored structure"
    }
}
