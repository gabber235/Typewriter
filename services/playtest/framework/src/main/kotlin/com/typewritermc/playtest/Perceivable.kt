package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Perception

/** Something a player can perceive, judged from one perception record. */
interface Perceivable {
    /** How a failure names it, for example `chat "Hello"`. */
    val description: String

    /** Whether [perception] shows this, counting only what arrived after tick [since]. */
    fun shownIn(
        perception: Perception,
        since: Int,
    ): Boolean
}

/** A chat line holding [text] that arrived after the window's stimulus and is drawn legibly in the chat. */
fun chat(text: String): Perceivable = ChatText(text)

private class ChatText(
    private val text: String,
) : Perceivable {
    override val description = "chat \"$text\""

    override fun shownIn(
        perception: Perception,
        since: Int,
    ): Boolean =
        perception.chat().any { it.tick() > since && text in it.text() } &&
            perception.texts().any { it.element() == "chat" && text in it.text() }
}
