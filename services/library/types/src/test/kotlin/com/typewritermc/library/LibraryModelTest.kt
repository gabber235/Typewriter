package com.typewritermc.library

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.types.Color
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json
import kotlin.uuid.Uuid

val LibraryModelTest by testSuite {
    test("page references preserve simple and composite record ids") {
        val references =
            listOf(
                PageRef<PageKind>(PageId("simple")),
                PageRef<PageKind>(
                    PageId(
                        RecordIdKey.Array(
                            listOf(
                                RecordIdValue.String("chapter"),
                                RecordIdValue.Number(7),
                            ),
                        ),
                    ),
                ),
                PageRef<PageKind>(PageId("~literal")),
            )

        references.forEach { reference ->
            val encoded = Json.encodeToString(PageRefSerializer, reference)
            Json.decodeFromString(PageRefSerializer, encoded) shouldBe reference
        }
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
        val child = tag("child", setOf(root.id))
        val leaf = tag("leaf", setOf(child.id))
        val hierarchy = TagHierarchy(listOf(root, child, leaf))

        hierarchy.isAncestor(root.id, leaf.id) shouldBe true
        hierarchy.canLink(root.id, leaf.id) shouldBe false
        hierarchy.canLink(leaf.id, root.id) shouldBe false
        hierarchy.canLink(leaf.id, TagId("missing")) shouldBe false
    }

    test("timeline tracks and snapshot page contents are unique") {
        val elementId = ElementInstanceId(Uuid.parseHex("00000000000000000000000000000001"))
        shouldThrow<IllegalArgumentException> {
            PageLayout.Timeline(listOf(elementId, elementId))
        }

        shouldThrow<IllegalArgumentException> {
            LibrarySnapshot(
                revision = LibraryRevision(1),
                books = emptyList(),
                tags = emptyList(),
                pages = emptyList(),
                contents = listOf(PageContents(PageId("missing"), emptyList(), PageLayout.Timeline(emptyList()))),
            )
        }
    }
}

private fun tag(
    id: String,
    parents: Set<TagId> = emptySet(),
): Tag =
    Tag(
        id = TagId(id),
        revision = ResourceRevision(1),
        name = LibraryName(id),
        color = Color(0u),
        parents = parents,
        placement = GridPlacement(0, 0, 1, 1),
    )
