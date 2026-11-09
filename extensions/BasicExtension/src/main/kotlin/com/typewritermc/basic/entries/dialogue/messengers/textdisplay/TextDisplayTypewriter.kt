package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.addPaddingBeforeLines
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.limitLineLength
import com.typewritermc.engine.paper.utils.lineCount
import com.typewritermc.engine.paper.utils.minimalLines
import com.typewritermc.engine.paper.utils.plainText
import com.typewritermc.engine.paper.utils.splitPercentage
import com.typewritermc.engine.paper.utils.stripped
import net.kyori.adventure.text.Component
import kotlin.math.floor

private val textDisplayLinePadding: String by snippet("dialogue.textDisplay.style.linePadding", "")
internal val textDisplayMaxLineLength: Int by snippet("dialogue.textDisplay.style.maxLineLength", 24)

internal class TextDisplayTypewriter(text: String) {
    private val message = text.lines().joinToString("\n") {
        it.limitLineLength(textDisplayMaxLineLength.coerceAtLeast(1))
    }.asMini()
    private val plainMessage = message.plainText()
    private val characterCount = plainMessage.length.coerceAtLeast(1)

    val rawText: String = text.stripped()

    fun visibleCharacters(percentage: Double): Int =
        floor(characterCount * percentage.coerceIn(0.0, 1.0)).toInt()

    fun component(percentage: Double): Component =
        message
            .splitPercentage(percentage)
            .minimalLines(plainMessage.lineCount)
            .addPaddingBeforeLines(textDisplayLinePadding)
}
