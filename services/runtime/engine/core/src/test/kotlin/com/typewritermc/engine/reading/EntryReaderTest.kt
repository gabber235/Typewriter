package com.typewritermc.engine.reading

import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.formula.testing.DialogueEntry
import com.typewritermc.engine.formula.testing.DialogueEntryFields
import com.typewritermc.engine.formula.testing.Said
import com.typewritermc.engine.formula.testing.Spoken
import com.typewritermc.engine.formula.testing.aside
import com.typewritermc.engine.formula.testing.choices
import com.typewritermc.engine.formula.testing.dialoguePublication
import com.typewritermc.engine.formula.testing.formula
import com.typewritermc.engine.formula.testing.greeting
import com.typewritermc.engine.formula.testing.maxLineLength
import com.typewritermc.engine.formula.testing.minLines
import com.typewritermc.engine.formula.testing.spoken
import com.typewritermc.engine.formula.testing.text
import com.typewritermc.engine.reading.testing.LayeredValues
import com.typewritermc.engine.reading.testing.entry
import com.typewritermc.engine.reading.testing.locationOf
import com.typewritermc.events.Context
import com.typewritermc.events.EventContext
import com.typewritermc.formula.Var
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

/** Handlers read entry values through accessors at any depth, and the entry reader resolves every stored value at one seam. */
val EntryReaderTest by testSuite {
    val leave = Context.EMPTY.with(Said(protagonist(), "leave"))

    val minLines = Var.Computed<Int, EventContext<Said>>(formula("2 + 1"))
    val choices = listOf<Var<String, EventContext<Said>>>(Var.Value("stay"), Var.Computed(formula("event.message")))

    test("a candidate reads a formula inside a nested record and inside each record of a list") {
        val candidate = dialoguePublication(minLines, 12, choices).candidate<DialogueEntry>("dialogue", leave)

        candidate.spoken.minLines shouldBe 3
        candidate.spoken.maxLineLength shouldBe 12
        candidate.choices.map { it.text } shouldContainExactly listOf("stay", "leave")
    }

    test("a triggered step reads a formula inside a nested record and inside each record of a list") {
        val step = dialoguePublication(minLines, 12, choices).triggered<DialogueEntry>("dialogue", leave)

        step.spoken.minLines shouldBe 3
        step.choices.indices.map { step.choices[it].text } shouldContainExactly listOf("stay", "leave")
    }

    test("a candidate reads an optional record as absent while none is stored and as its scope once one is") {
        dialoguePublication().candidate<DialogueEntry>("dialogue", leave).aside shouldBe null

        val withAside = dialoguePublication(aside = Spoken(minLines)).candidate<DialogueEntry>("dialogue", leave)
        withAside.aside?.minLines shouldBe 3
    }

    test("a stored value source at the seam answers for an accessor, with no change to the accessor or its caller") {
        val publication = dialoguePublication(minLines, 12, choices)
        val environment = publication.environment()
        val greeting = environment.locationOf(publication.entry("dialogue"), DialogueEntryFields.greeting)
        val configured =
            LayeredValues(
                environment.published,
            ).with(greeting, PublishedValues(dialoguePublication(minLines, 12, choices, greeting = "welcome back").graph).at(greeting))

        val candidate =
            publication.candidate<DialogueEntry>(
                "dialogue",
                leave,
                environment,
                reader = PublishedEntryReader(environment, configured),
            )

        candidate.greeting shouldBe "welcome back"
        candidate.spoken.minLines shouldBe 3
    }
}
