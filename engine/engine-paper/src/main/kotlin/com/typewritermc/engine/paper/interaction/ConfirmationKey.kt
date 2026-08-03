package com.typewritermc.engine.paper.interaction

import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.config
import com.typewritermc.engine.paper.utils.isFloodgate
import com.typewritermc.engine.paper.utils.reloadable
import net.kyori.adventure.text.minimessage.tag.Tag
import net.kyori.adventure.text.minimessage.tag.resolver.TagResolver
import org.bukkit.entity.Player

private val confirmationKeyString by config(
    "confirmationKey", ConfirmationKey.SNEAK.name, comment = """
    |The key that should be pressed to confirm a dialogue option.
    |Possible values: ${ConfirmationKey.entries.joinToString(", ") { it.name }}
""".trimMargin()
)

/** The key to ask for when the caller has no preference of its own. */
val confirmationKey: ConfirmationKey by reloadable {
    val key = ConfirmationKey.fromString(confirmationKeyString)
    if (key == null) {
        plugin.logger.warning("Invalid confirmation key '$confirmationKeyString'. Using default key '${ConfirmationKey.SNEAK.name}' instead.")
        return@reloadable ConfirmationKey.SNEAK
    }
    key
}

/**
 * Resolves `<confirmation_key>` to the key the message is being parsed for.
 *
 * Which key that is depends on what holds the player's input, so it is taken off the audience the
 * message is parsed for. Parsing for anything other than a player falls back to [confirmationKey].
 */
val confirmationKeyTag: TagResolver = TagResolver.resolver("confirmation_key") { _, context ->
    val player = context.target() as? Player
    val label = player?.let { (it.keyOffered ?: confirmationKey).label(it) } ?: confirmationKey.keybind
    Tag.preProcessParsed(label)
}

/**
 * A key a player can press to confirm.
 *
 * Not every key reaches the server while something else holds the player's input, so ask for a press
 * through [Confirmations] rather than listening for a key directly.
 */
enum class ConfirmationKey(val keybind: String, private val bedrockName: String) {
    JUMP("<key:key.jump>", "Jump"),
    SNEAK("<key:key.sneak>", "Sneak"),
    SWAP_HANDS("<key:key.swapOffhand>", "Swap Offhand"),
    LEFT_CLICK("<key:key.attack>", "Attack"),
    RIGHT_CLICK("<key:key.use>", "Use"),
    ;

    /** The name to show [player] for this key. Bedrock renders no keybind tag, so it gets a plain name. */
    fun label(player: Player): String = if (player.isFloodgate) bedrockName else keybind

    companion object {
        fun fromString(string: String): ConfirmationKey? = entries.find { it.name.equals(string, true) }
    }
}
