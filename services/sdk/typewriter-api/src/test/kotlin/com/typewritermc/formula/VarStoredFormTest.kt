package com.typewritermc.formula

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.testkit.ready
import com.typewritermc.types.integer
import com.typewritermc.types.memberName
import com.typewritermc.types.named
import com.typewritermc.types.record
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.type_catalog.DataValue

val VarStoredFormTest by testSuite {
    test("a plain value is stored as Var.Value and decodes to it") {
        val stored = DataValue.named(varValue(int), DataValue.record("value" to DataValue.integer(50)))
        decode<Var<Int, DefinitionScope>>(varOf(int), stored) shouldBe Var.Value(50)
        encode<Var<Int, DefinitionScope>>(varOf(int), Var.Value(50)) shouldBe stored
    }

    test("a formula is stored as Var.Computed holding source and references, and decodes to it") {
        val stored = DataValue.named(varComputed(int), DataValue.record("formula" to formulaValue("level * 2")))
        val decoded = decode<Var<Int, DefinitionScope>>(varOf(int), stored)
        decoded shouldBe Var.Computed(Formula("level * 2"))
        encode(varOf(int), decoded) shouldBe stored
    }

    test("a function typed value stores its body as a Formula under Var.Value") {
        val scorer = function("level" to int, result = int)
        val stored = DataValue.named(varValue(scorer), DataValue.record("value" to formulaValue("level * 2")))
        formulaCatalog.ready(varOf(scorer)).complete(stored).shouldBeInstanceOf<CompletenessResult.Complete>()
        decode<Var<Formula, DefinitionScope>>(varOf(scorer), stored) shouldBe Var.Value(Formula("level * 2"))
    }

    test("a Var field's concrete forms are its two cases, for the plain and formula toggle") {
        val forms = formulaCatalog.concreteForms(formulaCatalog.ready(varOf(int)))
        forms.map {
            it.schema.use.named
                ?.definition
                ?.memberName
        } shouldBe listOf("Value", "Computed")
    }
}
