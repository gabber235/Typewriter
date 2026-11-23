package com.typewritermc.playtest.bridge

import com.typewritermc.events.Event
import com.typewritermc.events.Handler
import com.typewritermc.events.HasChat
import com.typewritermc.identity.Protagonist
import com.typewritermc.types.TypewriterType

/**
 * A test event about [player] whose handler shows [text] in the player's chat, so a game requirement sees an event sent
 * from elsewhere, such as a panel tab, run on the engine that holds the player.
 */
@TypewriterType(id = PLAYTEST_SIGNAL_TYPE_ID)
data class PlaytestSignal(
    val player: Protagonist,
    val text: String,
) : Event

/** Shows the signal's text to the player it is about. */
@Handler
fun PlaytestSignal.show(chat: HasChat) {
    chat.send(text)
}

const val PLAYTEST_SIGNAL_TYPE_ID = "308993e6526946dcb8a1038ca9ee5e1c"
