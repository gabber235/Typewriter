package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.addPaddingBeforeLines
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.limitLineLength
import com.typewritermc.engine.paper.utils.lineCount
import com.typewritermc.engine.paper.utils.minimalLines
import com.typewritermc.engine.paper.utils.plainText
import com.typewritermc.engine.paper.utils.splitPercentage
import com.typewritermc.engine.paper.utils.stripped
import net.kyori.adventure.audience.Audience
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import kotlin.math.floor

private val textDisplayLinePadding: String by snippet("dialogue.textDisplay.style.linePadding", "")
private val configuredMaxLineLength: Int by snippet("dialogue.textDisplay.style.maxLineLength", 24)
internal val textDisplayMaxLineLength: Int
    get() = configuredMaxLineLength.coerceIn(1, 120)

internal class TextDisplayTypewriter(text: String, private val audience: Audience) {
    private val message = text.lines().joinToString("\n") {
        it.limitLineLength(textDisplayMaxLineLength)
    }.asMini(audience)
    private val plainMessage = message.plainText()
    private val lineCount = plainMessage.lineCount
    private val characterCount = plainMessage.length.coerceAtLeast(1)

    private var lastVisibleCharacters = -1

    val rawText: String = text.stripped()

    fun visibleCharacters(percentage: Double): Int =
        floor(characterCount * percentage.coerceIn(0.0, 1.0)).toInt()

    fun render(format: String, percentage: Double, force: Boolean): Component? {
        val visible = visibleCharacters(percentage)
        if (!force && visible == lastVisibleCharacters) return null
        lastVisibleCharacters = visible
        return format.asMiniWithResolvers(audience, Placeholder.component("message", component(percentage)))
    }

    fun component(percentage: Double): Component =
        message
            .splitPercentage(percentage)
            .minimalLines(lineCount)
            .addPaddingBeforeLines(textDisplayLinePadding)
}
