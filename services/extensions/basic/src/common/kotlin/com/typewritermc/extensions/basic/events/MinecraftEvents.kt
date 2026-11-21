package com.typewritermc.extensions.basic.events

import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Event
import com.typewritermc.identity.Protagonist
import com.typewritermc.types.TypewriterType

/** [player] joined this server: a first join, a rejoin within the grace, or a move from another server. */
@TypewriterType(id = PLAYER_JOIN_TYPE_ID)
data class PlayerJoin(
    val player: Protagonist,
) : Event

/** [player] left this server. */
@TypewriterType(id = PLAYER_QUIT_TYPE_ID)
data class PlayerQuit(
    val player: Protagonist,
) : Event

/** [player] sent [message] in chat; denying it keeps the message from being sent. */
@TypewriterType(id = PLAYER_CHAT_TYPE_ID)
data class PlayerChat(
    val player: Protagonist,
    val message: String,
) : CancelableEvent

/** [player] broke a block of [material] (its namespaced key, such as `minecraft:stone`); denying it keeps the block. */
@TypewriterType(id = BLOCK_BREAK_TYPE_ID)
data class BlockBreak(
    val player: Protagonist,
    val material: String,
) : CancelableEvent

const val PLAYER_JOIN_TYPE_ID = "12c1bb17453f4be0a31bad22de504af0"
const val PLAYER_QUIT_TYPE_ID = "92855432174a4bdeb03255ebd570210e"
const val PLAYER_CHAT_TYPE_ID = "8f1c608a1bb147cea41747249b76b13a"
const val BLOCK_BREAK_TYPE_ID = "475e1dc22530469b8eed295a8581f03e"
