package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.BedrockTimedTextDisplayDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.JavaTimedTextDisplayDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayDialoguePlayback
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayConfirmationInput
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayDialogueDisplay
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayOrientation
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayTypewriter
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.snippets.SnippetDatabase
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.spyk
import io.mockk.verify
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import java.time.Duration

class TextDisplayReviewRegressionSpec : FunSpec({
    beforeSpec {
        val snippets = mockk<SnippetDatabase>(relaxed = true)
        every { snippets.getSnippet(any(), String::class, any(), any()) } answers { thirdArg<String>() }
        startKoin { modules(module { single<SnippetDatabase> { snippets } }) }
    }

    afterSpec { stopKoin() }

    test("a criteria change cannot confirm a replacement option") {
        val original = Option()
        val replacement = Option()
        val display = mockk<TextDisplayDialogueDisplay>(relaxed = true)
        val playback = TextDisplayDialoguePlayback(
            mockk<Player>(), mockk<InteractionContext>(), ConstVar(Position.ORIGIN),
            TextDisplayOrientation.BILLBOARD, "",
        ) { display }
        val typewriter = mockk<TextDisplayTypewriter>()
        every { typewriter.render(any(), any(), any()) } returns null
        playback.setField("typewriter", typewriter)
        playback.setField("confirmation", mockk<Confirmation>(relaxed = true))
        val input = playback.getField("confirmed") as TextDisplayConfirmationInput
        val tick = TickContext(Duration.ZERO, Duration.ofMillis(50))

        input.press(original)
        playback.tick(tick, target = replacement) shouldBe MessengerState.RUNNING
        verify(exactly = 0) { display.close() }

        input.press(replacement)
        playback.tick(tick, target = replacement)
        verify(exactly = 1) { display.close() }
    }

    test("completion immediately respects a disabled skip policy") {
        val allowSkip = mockk<Var<Boolean>>()
        val messenger = JavaTimedTextDisplayDialogueDialogueMessenger(
            mockk<Player>(), mockk<InteractionContext>(), TimedTextDisplayDialogueEntry(allowSkip = allowSkip),
        )
        val playback = messenger.getField("playback") as TextDisplayDialoguePlayback
        playback.setField("animationComplete", true)
        every { allowSkip.get(any<Player>(), any<InteractionContext>()) } returns true
        messenger.animationComplete shouldBe true
        every { allowSkip.get(any<Player>(), any<InteractionContext>()) } returns false
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

private fun Any.getField(name: String): Any? =
    javaClass.getDeclaredField(name).apply { isAccessible = true }.get(this)

private fun Any.setField(name: String, value: Any) {
    javaClass.getDeclaredField(name).apply { isAccessible = true }.set(this, value)
}
