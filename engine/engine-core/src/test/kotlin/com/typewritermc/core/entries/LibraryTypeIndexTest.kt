package com.typewritermc.core.entries

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import kotlin.reflect.KClass

private interface Marked : Entry

private abstract class TestEntry(override val id: String, override val name: String) : Entry

private class Alpha(id: String, name: String = id) : TestEntry(id, name)
private class Beta(id: String, name: String = id) : TestEntry(id, name)
private class MarkedAlpha(id: String, name: String = id) : TestEntry(id, name), Marked
private class Unrelated(id: String, name: String = id) : TestEntry(id, name)

private fun Map<KClass<*>, List<Entry>>.idsOf(type: KClass<*>) = this[type].orEmpty().map { it.id }

class LibraryTypeIndexTest : FunSpec({

    test("a concrete type resolves to only its own entries") {
        val index = listOf(Alpha("a1"), Beta("b1"), Alpha("a2")).groupByType()

        index.idsOf(Alpha::class) shouldBe listOf("a1", "a2")
    }

    test("entries stay in catalogue order") {
        val index = listOf(Alpha("third"), Alpha("first"), Alpha("second")).groupByType()

        index.idsOf(Alpha::class) shouldBe listOf("third", "first", "second")
    }

    test("an entry answers to an interface it implements") {
        val index = listOf(Alpha("plain"), MarkedAlpha("marked"), Beta("other")).groupByType()

        index.idsOf(Marked::class) shouldBe listOf("marked")
    }

    test("every entry answers to the Entry supertype, in catalogue order") {
        val index = listOf(Alpha("a"), Beta("b"), MarkedAlpha("m"), Alpha("a2")).groupByType()

        index.idsOf(Entry::class) shouldBe listOf("a", "b", "m", "a2")
    }

    test("a type no entry is assignable to is absent from the index") {
        val index = listOf(Alpha("a"), Beta("b")).groupByType()

        index[Unrelated::class] shouldBe null
    }

    test("an empty catalogue produces an empty index") {
        emptyList<Entry>().groupByType() shouldBe emptyMap()
    }

    test("a subtype does not leak into a sibling's entries") {
        val index = listOf(Alpha("a"), MarkedAlpha("m")).groupByType()

        index.idsOf(Alpha::class) shouldBe listOf("a")
        index.idsOf(MarkedAlpha::class) shouldBe listOf("m")
    }

    test("the index agrees with filterIsInstance for every indexed type") {
        val entries = listOf(Alpha("a1"), Beta("b1"), MarkedAlpha("m1"), Alpha("a2"), Unrelated("u1"))
        val index = entries.groupByType()

        index.keys.forEach { type ->
            index.idsOf(type) shouldBe entries.filter { type.isInstance(it) }.map { it.id }
        }
    }
})
