package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayConfirmationInput
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class TextDisplayConfirmationInputSpec : FunSpec({
    test("a pending press retains its original option when the selection changes") {
        val input = TextDisplayConfirmationInput()
        val original = Option()
        val replacement = Option()
        input.press(original)
        val pressed = input.consume()
        (pressed === replacement) shouldBe false
        (pressed === original) shouldBe true
        input.consume() shouldBe null
    }

    test("another press cannot replace an unconsumed choice") {
        val input = TextDisplayConfirmationInput()
        val original = Option()
        val replacement = Option()
        input.press(original)
        input.press(replacement)
        (input.consume() === original) shouldBe true
        input.press(replacement)
        (input.consume() === replacement) shouldBe true
    }

    test("no selectable option does not queue a confirmation") {
        val input = TextDisplayConfirmationInput()
        input.press(null)
        input.consume() shouldBe null
    }
})
