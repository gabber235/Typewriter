package com.typewritermc.engine.paper.utils

import com.typewritermc.engine.paper.entry.dialogue.confirmationKey
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.TextComponent
import net.kyori.adventure.text.TextReplacementConfig
import net.kyori.adventure.text.format.NamedTextColor
import net.kyori.adventure.text.format.Style
import net.kyori.adventure.text.minimessage.MiniMessage
import net.kyori.adventure.text.minimessage.tag.Tag
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import net.kyori.adventure.text.minimessage.tag.resolver.TagResolver
import net.kyori.adventure.text.minimessage.tag.standard.StandardTags
import net.kyori.adventure.text.serializer.legacy.LegacyComponentSerializer
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer
import org.bukkit.ChatColor
import org.bukkit.command.CommandSender

private val mm = MiniMessage.builder()
    .tags(
        TagResolver.builder()
            .resolvers(
                StandardTags.decorations(),
                StandardTags.color(),
                StandardTags.hoverEvent(),
                StandardTags.clickEvent(),
                StandardTags.keybind(),
                StandardTags.translatable(),
                StandardTags.translatableFallback(),
                StandardTags.insertion(),
                StandardTags.font(),
                StandardTags.gradient(),
                StandardTags.rainbow(),
                StandardTags.transition(),
                StandardTags.reset(),
//                StandardTags.newline(), // Disable because breaks most formatting
                StandardTags.selector(),
                StandardTags.score(),
                StandardTags.nbt(),
            )
            .tag("confirmation_key") { _, _ -> Tag.preProcessParsed(confirmationKey.keybind) }
            .resolver(Placeholder.parsed("line", "<#ECFFF8><bold>│</bold></#ECFFF8><white>"))
            .build()
    )
    .build()

fun Component.asMini() = mm.serialize(this)

fun String.asMini() = mm.deserialize(this)

fun String.asMiniWithResolvers(vararg resolvers: TagResolver) = mm.deserialize(this, *resolvers)

fun CommandSender.sendMini(message: String) = sendMessage(message.asMini())

fun CommandSender.sendMiniWithResolvers(message: String, vararg resolvers: TagResolver) =
    sendMessage(message.asMiniWithResolvers(*resolvers))

fun CommandSender.msg(message: String) = sendMini("<red><bold>Typewriter »<reset><white> $message")

fun Component.plainText(): String = ChatColor.stripColor(PlainTextComponentSerializer.plainText().serialize(this)) ?: ""

fun Component.legacy(): String = LegacyComponentSerializer.legacy('§').serialize(this)

fun String.stripped(): String =
    this.asMini().plainText().replace("§", "")

fun String.legacy(): String =
    this.asMini().legacy()

fun String.legacy(vararg resolvers: TagResolver): String =
    this.asMiniWithResolvers(*resolvers).legacy()


fun String.asPartialFormattedMini(
    percentage: Double,
    minLines: Int = 3,
    maxLineLength: Int = 40,
    padding: String = "    ",
): Component {
    return replace("\n", "\n<reset><white>")
        .limitLineLength(maxLineLength)
        .asMini()
        .splitPercentage(percentage)
        .addPaddingBeforeLines(padding)
        .minimalLines(minLines)
        .color(NamedTextColor.WHITE)
}

fun Component.minimalLines(minLines: Int = 3): Component {
    val message = this.plainText()
    val lineCount = message.count { it == '\n' } + 1
    val missingLines = (minLines - lineCount).coerceAtLeast(0)
    val missingLinesString = "\n".repeat(missingLines)
    return this.append(Component.text(missingLinesString))
}

fun Component.addPaddingBeforeLines(padding: String = "    "): Component {
    val paddingComponent = Component.text(padding)
    val prePadded = paddingComponent.append(this)
    return prePadded.replaceText(
        TextReplacementConfig.builder().match("\\n").replacement(Component.text("\n$padding")).build()
    )
}

fun Component.splitPercentage(percentage: Double): Component {
    if (percentage >= 1.0) return this

    val message = plainText()
    val totalLength = message.length
    val subLength = (totalLength * percentage.coerceIn(.0, 1.0)).toInt().coerceIn(0, totalLength)

    val textRemaining = RunningText(subLength)
    return splitText(textRemaining, Style.empty())
}

private data class RunningText(var textRemaining: Int)

private fun Component.splitText(runningText: RunningText, style: Style): Component {
    if (runningText.textRemaining <= 0) return Component.empty()

    if (this !is TextComponent) return this

    val mergedStyle = this.style().merge(style, Style.Merge.Strategy.IF_ABSENT_ON_TARGET)

    val text = this.content()
    val size = text.length

    // If the text is longer than the remaining text, this is the last component.
    if (size > runningText.textRemaining) {
        val newText = text.substring(0, runningText.textRemaining)
        runningText.textRemaining = 0
        return this.content(newText).style(mergedStyle)
            .noChildren()
    }
    runningText.textRemaining -= size

    val children = this.children().map { it.splitText(runningText, mergedStyle) }

    return this.style(mergedStyle).children(children)
}


fun Component.noChildren() = this.children(mutableListOf())

/**
 * Splits a string into multiple lines with a maximum length.
 */
fun String.limitLineLength(maxLength: Int = 40): String {
    if (this.stripped().length <= maxLength) return this

    val words = this.split(" ")
    var text = ""

    for (word in words) {
        if (word.contains("\n")) {
            text += "$word "
            continue
        }

        val rawText = "$text$word".stripped()
        val lastNewLine = rawText.lastIndexOf("\n")
        val line = rawText.substring(lastNewLine + 1)
        if (line.length > maxLength) {
            text += "\n"
        }
        text += "$word "
    }

    text = text.trim()
    return text
}