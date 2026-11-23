package com.typewritermc.engine.reading

import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.formula.testing.DialogueEntry
import com.typewritermc.engine.formula.testing.FormulaPublication
import com.typewritermc.engine.formula.testing.Said
import com.typewritermc.engine.formula.testing.Spoken
import com.typewritermc.engine.formula.testing.aside
import com.typewritermc.engine.formula.testing.choices
import com.typewritermc.engine.formula.testing.dialogueEntry
import com.typewritermc.engine.formula.testing.dialoguePublication
import com.typewritermc.engine.formula.testing.formula
import com.typewritermc.engine.formula.testing.maxLineLength
import com.typewritermc.engine.formula.testing.minLines
import com.typewritermc.engine.formula.testing.spoken
import com.typewritermc.engine.formula.testing.text
import com.typewritermc.engine.formula.testing.unset
import com.typewritermc.engine.reading.testing.entry
import com.typewritermc.events.Context
import com.typewritermc.events.EventContext
import com.typewritermc.formula.Var
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ValuePath

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

    test("a field no creator set reads as its constructor default, beside the fields the entry stores") {
        val unsetLength = ValuePath.root.field("spoken").field("maxLineLength")
        val publication = FormulaPublication(dialogueEntry("dialogue", Spoken(minLines, 12)).unset(unsetLength))

        val candidate = publication.candidate<DialogueEntry>("dialogue", leave)

        candidate.spoken.maxLineLength shouldBe 40
        candidate.spoken.minLines shouldBe 3
    }
}
