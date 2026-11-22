package com.typewritermc.engine.reading

import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.formula.testing.DialogueEntry
import com.typewritermc.engine.formula.testing.DialogueEntryFields
import com.typewritermc.engine.formula.testing.Spoken
import com.typewritermc.engine.formula.testing.dialoguePublication
import com.typewritermc.engine.reading.testing.AsideLinesDerive
import com.typewritermc.engine.reading.testing.ComputeCounts
import com.typewritermc.engine.reading.testing.CountingLoader
import com.typewritermc.engine.reading.testing.GatedLoader
import com.typewritermc.engine.reading.testing.GreetingDerive
import com.typewritermc.engine.reading.testing.HasAsideDerive
import com.typewritermc.engine.reading.testing.LayeredValues
import com.typewritermc.engine.reading.testing.entry
import com.typewritermc.engine.reading.testing.locationOf
import com.typewritermc.formula.Var
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

/**
 * A derive reads entry values through the tracked graph: it reruns only when a value it actually read changes, and a
 * value that is not loaded yet fails as a recorded read that loads once and reruns.
 */
val TrackedEntryReadsTest by testSuite {
    val publication = dialoguePublication()
    val environment = publication.environment()
    val entry = publication.entry<DialogueEntry>("dialogue")
    val opens = environment.locationOf(entry, DialogueEntryFields.opens)
    val greeting = environment.locationOf(entry, DialogueEntryFields.greeting)
    val farewell = environment.locationOf(entry, DialogueEntryFields.farewell)
    val derive = GreetingDerive(entry, protagonist())

    test("a change on the branch a derive did not take does not rerun it, and a change to its condition does") {
        val counts = ComputeCounts()
        val reads = TrackedEntryReads(EntryValues(environment, environment.published), CountingLoader(environment.published), counts)
        reads.read(derive) shouldBe "hello"

        reads.change(mapOf(farewell to PublishedValues(dialoguePublication(farewell = "see you").graph).at(farewell)))
        reads.read(derive) shouldBe "hello"
        counts.of(derive) shouldBe 1

        reads.change(mapOf(opens to PublishedValues(dialoguePublication(opens = false).graph).at(opens)))
        reads.read(derive) shouldBe "see you"
        counts.of(derive) shouldBe 2
    }

    test("a value that is not loaded fails the derive's first run, and the derive reruns once it loads") {
        val counts = ComputeCounts()
        val loader = CountingLoader(environment.published)
        val reads = TrackedEntryReads(EntryValues(environment, LayeredValues(environment.published).notLoaded(greeting)), loader, counts)

        shouldThrow<ValueNotLoaded> { reads.read(derive) }.location shouldBe greeting
        reads.load(setOf(greeting))

        reads.read(derive) shouldBe "hello"
        counts.of(derive) shouldBe 2
        loader.rounds shouldContainExactly listOf(setOf(greeting))
    }

    test("a rerun first loads everything the previous run read, so it needs one load round") {
        val counts = ComputeCounts()
        val loader = CountingLoader(environment.published)
        val reads = TrackedEntryReads(EntryValues(environment, environment.published), loader, counts)
        reads.read(derive) shouldBe "hello"

        loader.truth = PublishedValues(dialoguePublication(greeting = "welcome back").graph)
        reads.change(mapOf(opens to Stored.NotLoaded, greeting to Stored.NotLoaded))

        reads.read(derive) shouldBe "welcome back"
        loader.rounds shouldContainExactly listOf(setOf(opens, greeting))
        counts.of(derive) shouldBe 2
    }

    test(
        "an optional record's presence is its own read: a change inside the record keeps a derive that asked only for it, removing the record reruns it",
    ) {
        val withAside = dialoguePublication(aside = Spoken(Var.Value(2)))
        val asideEnvironment = withAside.environment()
        val asideEntry = withAside.entry<DialogueEntry>("dialogue")
        val aside = asideEnvironment.locationOf(asideEntry, DialogueEntryFields.aside)
        val hasAside = HasAsideDerive(asideEntry, protagonist())
        val counts = ComputeCounts()
        val reads =
            TrackedEntryReads(EntryValues(asideEnvironment, asideEnvironment.published), CountingLoader(asideEnvironment.published), counts)
        reads.read(hasAside) shouldBe true

        reads.change(mapOf(aside to PublishedValues(dialoguePublication(aside = Spoken(Var.Value(3))).graph).at(aside)))
        reads.read(hasAside) shouldBe true
        counts.of(hasAside) shouldBe 1

        reads.change(mapOf(aside to PublishedValues(dialoguePublication().graph).at(aside)))
        reads.read(hasAside) shouldBe false
        counts.of(hasAside) shouldBe 2
    }

    test("a change that arrives while a load waits survives the load") {
        val loader = GatedLoader(environment.published)
        val values = LayeredValues(environment.published).notLoaded(greeting)
        val reads = TrackedEntryReads(EntryValues(environment, values), loader)

        coroutineScope {
            val loading = launch { reads.load(setOf(greeting)) }
            loader.started.await()
            reads.change(mapOf(opens to PublishedValues(dialoguePublication(opens = false).graph).at(opens)))
            loader.release.complete(Unit)
            loading.join()
        }

        reads.read(derive) shouldBe "goodbye"
    }

    test("a change at a record covers the reads below it: a derive reruns only when the value it read below actually differs") {
        val withAside = dialoguePublication(aside = Spoken(Var.Value(2)))
        val asideEnvironment = withAside.environment()
        val asideEntry = withAside.entry<DialogueEntry>("dialogue")
        val aside = asideEnvironment.locationOf(asideEntry, DialogueEntryFields.aside)
        val asideLines = AsideLinesDerive(asideEntry, protagonist())
        val counts = ComputeCounts()
        val reads =
            TrackedEntryReads(EntryValues(asideEnvironment, asideEnvironment.published), CountingLoader(asideEnvironment.published), counts)
        reads.read(asideLines) shouldBe 2

        reads.change(mapOf(aside to PublishedValues(dialoguePublication(aside = Spoken(Var.Value(2), 60)).graph).at(aside)))
        reads.read(asideLines) shouldBe 2
        counts.of(asideLines) shouldBe 1

        reads.change(mapOf(aside to PublishedValues(dialoguePublication(aside = Spoken(Var.Value(3))).graph).at(aside)))
        reads.read(asideLines) shouldBe 3
        counts.of(asideLines) shouldBe 2
    }
}
