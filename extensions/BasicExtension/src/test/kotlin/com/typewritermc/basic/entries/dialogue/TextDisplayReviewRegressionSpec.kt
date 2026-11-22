package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.BedrockTimedTextDisplayDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.JavaTextDisplayDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayConfirmationInput
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayDialogueDisplay
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayOrientation
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayTypewriter
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.Confirmation
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.spyk
import io.mockk.verify
import org.bukkit.entity.Player
import java.time.Duration

class TextDisplayReviewRegressionSpec : FunSpec({
    test("a criteria change cannot confirm a replacement option") {
        val original = Option()
        val replacement = Option()
        val messenger = ReviewMessenger(original)
        val display = mockk<TextDisplayDialogueDisplay>(relaxed = true)
        every { display.invalid } returns false
        every { display.finished } returns false
        every { display.isClosing } returns false
        val typewriter = mockk<TextDisplayTypewriter>()
        every { typewriter.render(any(), any(), any()) } returns null
        messenger.setField("display", display)
        messenger.setField("typewriter", typewriter)
        messenger.setField("confirmation", mockk<Confirmation>(relaxed = true))
        val input = messenger.getField("confirmed") as TextDisplayConfirmationInput
        input.press(original)
        messenger.nextSelection = replacement
        messenger.tick(TickContext(Duration.ZERO, Duration.ofMillis(50)))
        verify(exactly = 0) { display.close() }
        messenger.state shouldBe MessengerState.RUNNING
        input.press(replacement)
        messenger.tick(TickContext(Duration.ZERO, Duration.ofMillis(50)))
        verify(exactly = 1) { display.close() }
    }

    test("completion immediately respects a disabled skip policy") {
        val messenger = ReviewMessenger(Unit)
        messenger.setField("animationDone", true)
        messenger.animationComplete shouldBe true
        messenger.allowed = false
        messenger.animationComplete shouldBe false
    }

    test("Bedrock confirmation during typing preserves the full wait") {
        val messenger = spyk(
            BedrockTimedTextDisplayDialogueDialogueMessenger(
                mockk<Player>(), mockk<InteractionContext>(), TimedTextDisplayDialogueEntry(),
            ),
            recordPrivateCalls = true,
        )
        every { messenger["sendForm"]() } returns Unit
        messenger.setField("playTime", Duration.ofMillis(9990))
        messenger.setField("typingDuration", Duration.ofSeconds(10))
        messenger.setField("totalDuration", Duration.ofSeconds(15))
        val recordConfirmation = messenger.javaClass.getDeclaredMethod("recordConfirmation")
        recordConfirmation.isAccessible = true
        recordConfirmation.invoke(messenger)
        messenger.tick(TickContext(Duration.ZERO, Duration.ofMillis(50)))
        messenger.getField("playTime") shouldBe Duration.ofSeconds(10)
        messenger.state shouldBe MessengerState.RUNNING
        messenger.tick(TickContext(Duration.ZERO, Duration.ofSeconds(4)))
        messenger.state shouldBe MessengerState.RUNNING
        recordConfirmation.invoke(messenger)
        messenger.tick(TickContext(Duration.ZERO, Duration.ofMillis(50)))
        messenger.state shouldBe MessengerState.FINISHED
    }
})

private class ReviewMessenger(override var confirmationTarget: Any?) :
    JavaTextDisplayDialogueMessenger<SpokenTextDisplayDialogueEntry>(
        mockk<Player>(), mockk<InteractionContext>(), SpokenTextDisplayDialogueEntry(), ConstVar(""),
        ConstVar(Duration.ZERO), ConstVar(Position.ORIGIN), TextDisplayOrientation.BILLBOARD, "",
    ) {
    var nextSelection: Any? = confirmationTarget
    var allowed = true
    override val canConfirm: Boolean get() = allowed

    override fun updateDialogue() {
        confirmationTarget = nextSelection
    }
}

private fun Any.getField(name: String): Any? {
    val owner = if (this is ReviewMessenger) JavaTextDisplayDialogueMessenger::class.java else {
        BedrockTimedTextDisplayDialogueDialogueMessenger::class.java
    }
    return owner.getDeclaredField(name).apply { isAccessible = true }.get(this)
}

private fun Any.setField(name: String, value: Any) {
    val owner = if (this is ReviewMessenger) JavaTextDisplayDialogueMessenger::class.java else {
        BedrockTimedTextDisplayDialogueDialogueMessenger::class.java
    }
    owner.getDeclaredField(name).apply { isAccessible = true }.set(this, value)
}
