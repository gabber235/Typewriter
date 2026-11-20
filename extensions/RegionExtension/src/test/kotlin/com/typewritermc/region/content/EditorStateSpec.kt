package com.typewritermc.region.content

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

class EditorStateSpec : FunSpec({
    val radius = EditField("radius", 1.0)
    val label = EditField<String?>("label", null)

    test("a field the snapshot does not hold reads as its default") {
        EditorState.EMPTY[radius] shouldBe 1.0
        EditorState.EMPTY[label] shouldBe null
    }

    test("with replaces one value and leaves the original snapshot untouched") {
        val original = EditorState.of(radius of 2.0)
        val changed = original.with(radius, 3.0)

        original[radius] shouldBe 2.0
        changed[radius] shouldBe 3.0
    }

    test("an override replaces only the fields it holds") {
        val current = EditorState.of(radius of 4.0, label of "kept")
        val restored = current.overriddenBy(EditorState.of(radius of 2.0))

        restored[radius] shouldBe 2.0
        restored[label] shouldBe "kept"
    }

    test("two fields with the same name are still different fields") {
        val twin = EditField("radius", 1.0)
        val state = EditorState.of(radius of 5.0)

        state[twin] shouldBe 1.0
        state.fields.contains(twin) shouldBe false
    }

    test("changed fields compare a missing field by its default") {
        val before = EditorState.of(radius of 1.0)
        val after = EditorState.of(radius of 1.0, label of "new")

        changedFields(before, after).shouldContainExactlyInAnyOrder(label)
        changedFields(after, after) shouldBe emptySet()
    }
})
