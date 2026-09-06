package com.typewritermc.library

import com.typewritermc.types.Color
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val LibraryModelTest by testSuite {
    test("library names enforce the persisted identifier format") {
        LibraryName("valid_name").value shouldBe "valid_name"
        shouldThrow<IllegalArgumentException> { LibraryName("No spaces") }
        shouldThrow<IllegalArgumentException> { LibraryName("ab") }
    }

    test("chapter replacement respects segment boundaries") {
        ChapterPath.parse("act.one.deep").replacePrefix(
            ChapterPath.parse("act.one"),
            ChapterPath.parse("act.two"),
        ) shouldBe ChapterPath.parse("act.two.deep")

        ChapterPath.parse("act.onerous").isDescendantOf(ChapterPath.parse("act.one")) shouldBe false
        ChapterPath.parse("act.one").isDescendantOf(ChapterPath.Root) shouldBe false
    }

    test("tag hierarchy rejects cycles and redundant links") {
        val root = tag("root")
        val child = tag("child", setOf(root.id.ref()))
        val leaf = tag("leaf", setOf(child.id.ref()))
        val hierarchy = TagHierarchy(listOf(root, child, leaf))

        hierarchy.isAncestor(root.id, leaf.id) shouldBe true
        hierarchy.canLink(root.id, leaf.id) shouldBe false
        hierarchy.canLink(leaf.id, root.id) shouldBe false
        hierarchy.canLink(leaf.id, TagId("missing")) shouldBe false
    }
}

private fun tag(
    id: String,
    parents: Set<com.typewritermc.types.Ref<Tag>> = emptySet(),
): Tag =
    Tag(
        id = TagId(id),
        name = LibraryName(id),
        color = Color(0u),
        parents = parents,
        placement = GridPlacement(0, 0, 1, 1),
    )
