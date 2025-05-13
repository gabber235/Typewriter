package com.typewritermc.engine.paper.entry.dialogue

import com.destroystokyo.paper.event.player.PlayerJumpEvent
import com.typewritermc.core.utils.server
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.config
import com.typewritermc.engine.paper.utils.reloadable
import lirand.api.extensions.events.unregister
import org.bukkit.NamespacedKey
import org.bukkit.attribute.Attribute
import org.bukkit.attribute.AttributeModifier
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerSwapHandItemsEvent
import org.bukkit.event.player.PlayerToggleSneakEvent

private val confirmationKeyString by config(
    "confirmationKey", ConfirmationKey.JUMP.name, comment = """
    |The key that should be pressed to confirm a dialogue option.
    |Possible values: ${ConfirmationKey.entries.joinToString(", ") { it.name }}
""".trimMargin()
)

val confirmationKey: ConfirmationKey by reloadable {
    val key = ConfirmationKey.fromString(confirmationKeyString)
    if (key == null) {
        plugin.logger.warning("Invalid confirmation key '$confirmationKeyString'. Using default key '${ConfirmationKey.JUMP.name}' instead.")
        return@reloadable ConfirmationKey.JUMP
    }
    key
}


enum class ConfirmationKey(val keybind: String) {
    JUMP("<key:key.jump>"),
    SWAP_HANDS("<key:key.swapOffhand>"),
    SNEAK("<key:key.sneak>"),
    ;

    fun handler(player: Player, block: () -> Unit): ConfirmationKeyHandler {
        return when (this) {
            SWAP_HANDS -> SwapHandsHandler(player, block)
            JUMP -> JumpHandler(player, block)
            SNEAK -> SneakHandler(player, block)
        }.apply { initialize() }
    }

    companion object {
        fun fromString(string: String): ConfirmationKey? {
            return entries.find { it.name.equals(string, true) }
        }
    }
}

sealed interface ConfirmationKeyHandler : Listener {
    val player: Player
    val block: () -> Unit

    fun initialize() {
        server.pluginManager.registerEvents(this, plugin)
    }

    fun dispose() {
        unregister()
    }
}

class SwapHandsHandler(override val player: Player, override val block: () -> Unit) : ConfirmationKeyHandler {
    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onSwapHands(event: PlayerSwapHandItemsEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        event.isCancelled = true
        block()
    }
}

class JumpHandler(override val player: Player, override val block: () -> Unit) : ConfirmationKeyHandler {
    private val key = NamespacedKey(plugin, "jump_confirmation")

    override fun initialize() {
        super.initialize()
        player.getAttribute(Attribute.JUMP_STRENGTH)?.let { attribute ->
            attribute.removeModifier(key)
            attribute.addModifier(AttributeModifier(key, -0.999, AttributeModifier.Operation.MULTIPLY_SCALAR_1))
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onJump(event: PlayerJumpEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        block()
    }

    override fun dispose() {
        super.dispose()
        player.getAttribute(Attribute.JUMP_STRENGTH)?.removeModifier(key)
    }
}

class SneakHandler(override val player: Player, override val block: () -> Unit) : ConfirmationKeyHandler {
    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onSneak(event: PlayerToggleSneakEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (!event.isSneaking) return
        event.isCancelled = true
        block()
    }
}