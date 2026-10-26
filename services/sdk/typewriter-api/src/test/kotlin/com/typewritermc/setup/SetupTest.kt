package com.typewritermc.setup

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.library.Book
import com.typewritermc.library.Tag
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import io.kotest.property.checkAll
import java.util.UUID

val SetupTest by testSuite {
    test("the same setup gives the same resource ids in every run") {
        val book = setup("a") { library { books.book("x") { handle } } }

        book.handles.id.value shouldBe PINNED_BOOK_ID
        book.resources shouldBe setup("a") { library { books.book("x") { } } }.resources
    }

    test("resource ids are version 5 UUIDs") {
        val id = setup("a") { library { books.book("x") { handle } } }.handles.id

        UUID.fromString(id.value).version() shouldBe 5
    }

    test("distinct key paths always get distinct ids, and one path always the same id") {
        // Steps from a tiny alphabet with the separator and space, so near collisions like "x/y" against "x", "y" are common.
        val step = Arb.list(Arb.element("x", "y", "/", " "), 0..3).map { it.joinToString("") }
        val path = Arb.list(step, 1..4)
        checkAll(PropTestConfig(seed = STABLE_ID_SEED, iterations = 2000), path, path) { first, second ->
            stableId(first) shouldBe stableId(first.toList())
            if (first != second) stableId(first) shouldNotBe stableId(second)
        }
    }

    test("keys that join to the same path still get different ids") {
        // A book keyed "x/pages y" and a page "y" in book "x" spell the same text when the steps are joined by "/".
        stableId(listOf("library", "books x/pages y")) shouldNotBe stableId(listOf("library", "books x", "pages y"))
    }

    test("a key path defined twice in one setup is refused") {
        rejectionOf {
            setup("a") {
                library {
                    books.book("x") { }
                    books.book("x") { }
                }
            }
        } shouldBe "library / books x is defined twice in setup a."
    }

    test("combining setups creates a part both contain once") {
        val shared =
            setup("a") { library { books.book("x") { title = "Same" } } } + setup("b") { library { books.book("x") { title = "Same" } } }

        shared.parts.map { it.path } shouldContainExactly listOf(listOf("library", "books x"))
        shared.name shouldBe SetupName("a+b")
    }

    test("two different parts under one id are refused when merged") {
        rejectionOf {
            setup("a") { library { books.book("x") { title = "One" } } } +
                setup("b") { library { books.book("x") { title = "Two" } } }
        } shouldBe "library / books x is defined differently by two setups."
    }

    for (name in listOf("Quest Log", "quest log", "quest_log", "")) {
        test("the setup name '$name' is refused") {
            rejectionOf { SetupName(name) } shouldBe "Setup names are lowercase words joined by '-', found '$name'."
        }
    }

    test("a setup name of lowercase words joined by dashes is accepted") {
        SetupName("quest-log-2").value shouldBe "quest-log-2"
    }

    test("constructing a part keeps Kotlin defaults for fields the setup left unassigned") {
        val book = setup("a") { library { books.book("x") { title = "Atlas" } } }.parts.single().construct() as Book

        book.title shouldBe "Atlas"
        book.pages shouldBe emptyList()
        book.tags shouldBe emptySet()
    }

    test("constructing a part with a field its type does not declare names that field") {
        val part = setup("a") { library { books.book("x") { } } }.parts.single()

        constructionFailure(part.copy(assigned = mapOf("subtitle" to "x"))) shouldBe
            "library / books x: Book has no constructor parameter subtitle."
    }

    test("constructing a placed part whose owner has no layout asks for a placement") {
        val tag = tagPart(placement = null)

        constructionFailure(tag) shouldBe "taxonomy / tags x: Tag requires placement; its owner has no known layout, so set placement."
    }

    test("tags in the taxonomy graph are placed in rows of eight") {
        val placements =
            setup("a") {
                taxonomy { (0 until 9).forEach { tags.tag("t$it") } }
            }.parts.map { it.placement }

        placements.take(2) shouldContainExactly
            listOf(GraphPlacement(x = 0, y = 0, width = 2, height = 1), GraphPlacement(x = 3, y = 0, width = 2, height = 1))
        placements[7] shouldBe GraphPlacement(x = 21, y = 0, width = 2, height = 1)
        placements[8] shouldBe GraphPlacement(x = 0, y = 2, width = 2, height = 1)
    }

    test("an explicit placement replaces the one the graph layout would give") {
        val explicit = GraphPlacement(x = 40, y = 40, width = 4, height = 2)
        val tag = setup("a") { taxonomy { tags.tag("x") { placement = explicit } } }.parts.single()

        (tag.construct() as Tag).placement shouldBe explicit
    }

    test("parts outside a graph layout get no placement") {
        setup("a") { library { books.book("x") { } } }.parts.single().placement shouldBe null
    }

    test("handles assigned to link fields become refs to the created resource, inside collections too") {
        val content =
            setup("a") {
                val tag = taxonomy { tags.tag("t") }
                library { books.book("x") { tags = setOf(tag) } }
                tag
            }
        val book = content.parts.single { it.type == Book::class }.construct() as Book

        book.tags.map { it.target } shouldContainExactly listOf(content.handles.id)
        listOf(SetupHandle<Tag>(content.handles.id)).toRefsOf() shouldBe listOf(content.handles.id.value)
        mapOf("k" to SetupHandle<Tag>(content.handles.id)).toRefsOf() shouldBe listOf(content.handles.id.value)
    }

    test("reading a setup field that was never assigned fails with the field name") {
        shouldThrow<IllegalStateException> {
            setup("a") { library { books.book("x") { title } } }
        }.message shouldBe "title was not assigned."
    }
}

/** The ids that [value] holds after construction turned its handles into refs, read from a book's tag field. */
private fun Any.toRefsOf(): List<String> {
    val part = setup("a") { library { books.book("x") { } } }.parts.single()
    val constructed = part.copy(type = Holder::class, ownerField = null, assigned = mapOf("value" to this)).construct() as Holder
    return when (val held = constructed.value) {
        is List<*> -> held.map { (it as Ref<*, *>).target.value }
        is Map<*, *> -> held.values.map { (it as Ref<*, *>).target.value }
        else -> error("Unexpected $held")
    }
}

/** A resource that holds any value, to observe what construction does to a handle nested in a collection. */
internal data class Holder(
    val value: Any,
) : Resource

private fun tagPart(placement: GraphPlacement?): SetupPart =
    setup("a") { taxonomy { tags.tag("x") } }
        .parts
        .single()
        .copy(placement = placement)

private fun constructionFailure(part: SetupPart): String? = shouldThrow<IllegalStateException> { part.construct() }.message

private fun rejectionOf(block: () -> Unit): String? = shouldThrow<IllegalArgumentException> { block() }.message

private const val STABLE_ID_SEED = 5_123_456L
private const val PINNED_BOOK_ID = "e362597a-988d-596b-8663-63ab6877e66b"
