package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayTypewriter
import com.typewritermc.engine.paper.snippets.SnippetDatabase
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.lineCount
import com.typewritermc.engine.paper.utils.plainText
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.unmockkStatic
import net.kyori.adventure.text.minimessage.MiniMessage
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module

class TextDisplayTypewriterSpec : FunSpec({
    beforeSpec {
        mockkStatic("com.typewritermc.engine.paper.utils.MiniMessagesKt")
        every { any<String>().asMini() } answers { MiniMessage.miniMessage().deserialize(firstArg<String>()) }
        val snippets = mockk<SnippetDatabase>(relaxed = true)
        every { snippets.getSnippet(any(), String::class, any(), any()) } answers { thirdArg<String>() }
        every { snippets.getSnippet(any(), Int::class, any(), any()) } answers { thirdArg<Int>() }
        startKoin { modules(module { single<SnippetDatabase> { snippets } }) }
    }

    afterSpec {
        stopKoin()
        unmockkStatic("com.typewritermc.engine.paper.utils.MiniMessagesKt")
    }

    test("long multiline dialogue keeps every line and reserves its height throughout typing") {
        val typewriter = TextDisplayTypewriter("one\ntwo\nthree\nfour\nfive")
        for (step in 0..20) {
            val lines = typewriter.component(step / 20.0).plainText().lines()
            lines.size shouldBe 5
        }
        typewriter.component(1.0).plainText() shouldBe "one\ntwo\nthree\nfour\nfive"
    }

    test("formatting tags do not consume typing characters") {
        val typewriter = TextDisplayTypewriter("<red>abcd</red>")
        typewriter.visibleCharacters(0.5) shouldBe 2
        typewriter.component(0.5).plainText() shouldBe "ab"
        typewriter.component(1.0).plainText() shouldBe "abcd"
    }

    test("empty dialogue remains a valid single line") {
        val typewriter = TextDisplayTypewriter("")
        typewriter.component(0.0).plainText() shouldBe ""
        typewriter.component(1.0).plainText() shouldBe ""
    }

    test("paragraphs wrap before typing without changing their reserved height") {
        val text = "A quiet village waits beyond the bridge and the old mill.\n" +
            "Follow the river until you reach the lantern beside the gate."
        val typewriter = TextDisplayTypewriter(text)
        val complete = typewriter.component(1.0).plainText()
        complete.lines().all { it.length <= 24 } shouldBe true
        for (step in 0..20) {
            typewriter.component(step / 20.0).plainText().lineCount shouldBe complete.lineCount
        }
        complete.replace(Regex("\\s+"), " ").trim() shouldBe text.replace('\n', ' ')
    }
})
