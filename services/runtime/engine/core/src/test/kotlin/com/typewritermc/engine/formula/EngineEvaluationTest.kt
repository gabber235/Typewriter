package com.typewritermc.engine.formula

import com.typewritermc.engine.events.EventEntry
import com.typewritermc.engine.events.condition
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.formula.testing.FormulaPublication
import com.typewritermc.engine.formula.testing.Said
import com.typewritermc.engine.formula.testing.TallyEntry
import com.typewritermc.engine.formula.testing.WithdrawableFormulas
import com.typewritermc.engine.formula.testing.count
import com.typewritermc.engine.formula.testing.definition
import com.typewritermc.engine.formula.testing.formula
import com.typewritermc.engine.formula.testing.int
import com.typewritermc.engine.formula.testing.saidEntry
import com.typewritermc.engine.formula.testing.tallyEntry
import com.typewritermc.engine.formula.testing.text
import com.typewritermc.engine.formula.testing.total
import com.typewritermc.engine.pages.DefinitionFields
import com.typewritermc.events.Context
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Var
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

/** Published entries' formulas evaluate on the engine, over the publication they arrived in. */
val EngineEvaluationTest by testSuite {
    test("a Definition's formula reads the Definitions it names") {
        val publication =
            FormulaPublication(
                definition("total", int, Var.Value(3)),
                definition("message", text, Var.Computed<String, DefinitionScope>(formula("\"Reward: \${total}\"", "total"))),
            )

        publication.environment().evaluate(ResourceId("message"), DefinitionFields.value) shouldBe "Reward: 3"
    }

    test("an event entry's condition reads the event it is about") {
        val publication = FormulaPublication(saidEntry("greeting", Var.Computed(formula("event.message.indexOf(\"hello\") >= 0"))))
        val hello = Context.EMPTY.with(Said(protagonist(), "hello there"))
        val bye = Context.EMPTY.with(Said(protagonist(), "bye"))

        publication.candidate<EventEntry<Said>>("greeting", hello).condition shouldBe true
        publication.candidate<EventEntry<Said>>("greeting", bye).condition shouldBe false
    }

    test("two formula fields with the same text each read as their own field") {
        val publication = FormulaPublication(tallyEntry("tally", count = Var.Computed(formula("7")), total = Var.Computed(formula("7"))))
        val tally = publication.candidate<TallyEntry>("tally", Context.EMPTY.with(Said(protagonist(), "hello")))

        tally.count shouldBe 7
        tally.total shouldBe 7L
    }

    test("a formula with a problem fails its read with the problem") {
        val publication = FormulaPublication(definition("broken", int, Var.Computed<Int, DefinitionScope>(formula("missing + 1"))))

        shouldThrow<FormulaReadException> { publication.environment().evaluate(ResourceId("broken"), DefinitionFields.value) }
            .message shouldContain "`missing` is unknown"
    }

    test("a publication checks each formula once, not on every read") {
        val publication = FormulaPublication(saidEntry("greeting", Var.Computed(formula("event.message.indexOf(\"hello\") >= 0"))))
        val formulas = WithdrawableFormulas()
        val environment = publication.environment(formulas)
        val hello = Context.EMPTY.with(Said(protagonist(), "hello there"))
        val bye = Context.EMPTY.with(Said(protagonist(), "bye"))
        publication.candidate<EventEntry<Said>>("greeting", hello, environment).condition shouldBe true

        formulas.withdrawn = setOf("indexOf")

        publication.candidate<EventEntry<Said>>("greeting", bye, environment).condition shouldBe false
        shouldThrow<FormulaReadException> {
            publication.candidate<EventEntry<Said>>("greeting", bye, publication.environment(formulas)).condition
        }.message shouldContain "indexOf"
    }
}
