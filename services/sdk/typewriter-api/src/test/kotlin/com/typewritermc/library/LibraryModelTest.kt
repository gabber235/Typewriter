package com.typewritermc.library

import com.typewritermc.types.Color
import com.typewritermc.types.Resource
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val LibraryModelTest by testSuite {
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
): Resource<TagId, Tag> =
    Resource(
        TagId(id),
        Tag(
            name = id,
            color = Color(0u),
            parents = parents,
            placement = com.typewritermc.authoring.GraphPlacement(0, 0, 1, 1),
        ),
    )
