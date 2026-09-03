package com.typewritermc.engine.paper.utils

import com.github.retrooper.packetevents.manager.server.ServerVersion
import com.github.retrooper.packetevents.protocol.component.ComponentTypes
import com.github.retrooper.packetevents.protocol.component.builtin.item.ItemModel
import com.github.retrooper.packetevents.protocol.component.builtin.item.ItemTooltipDisplay
import com.github.retrooper.packetevents.protocol.item.type.ItemTypes
import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.resources.ResourceLocation
import com.github.retrooper.packetevents.util.Dummy
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerAbilities
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetSlot
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTimeUpdate
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerWindowItems
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.plugin
import io.github.retrooper.packetevents.util.SpigotReflectionUtil
import net.kyori.adventure.text.Component
import org.bukkit.GameMode
import org.bukkit.Location
import org.bukkit.entity.Player
import org.bukkit.inventory.EquipmentSlot
import org.bukkit.inventory.ItemStack
import org.bukkit.potion.PotionEffect
import org.bukkit.potion.PotionEffectType

interface PlayerStateProvider {
    fun store(player: Player): Any
    fun restore(player: Player, value: Any)
}

data class PlayerState(
    val state: Map<PlayerStateProvider, Any>
)

enum class GenericPlayerStateProvider(private val store: Player.() -> Any, private val restore: Player.(Any) -> Unit) :
    PlayerStateProvider {
    LOCATION({ location }, { teleport(it as Location) }),
    GAME_MODE({ gameMode }, { gameMode = it as GameMode }),
    EXP({ exp }, { exp = it as Float }),
    LEVEL({ level }, { level = it as Int }),
    ALLOW_FLIGHT({ allowFlight }, { allowFlight = it as Boolean }),
    FLYING({ isFlying }, { isFlying = it as Boolean }),
    GAME_TIME({ playerTime }, {
        resetPlayerTime()
        WrapperPlayServerTimeUpdate(world.gameTime, playerTime).sendPacketTo(this)
    }),
    VELOCITY({ velocity.toVector() }, { velocity = (it as Vector).toBukkitVector() }),

    // All Players that are visible to the player
    @Deprecated(
        "Scheduled for removal. Restoring this shows every player that was visible when the state " +
                "was captured, which also cancels a hide another feature took in the meantime. Take " +
                "hides through PlayerHides and release them by owner instead.",
        level = DeprecationLevel.ERROR
    )
    VISIBLE_PLAYERS({
        server.onlinePlayers.filter { it != this && canSee(it) }.map { it.uniqueId.toString() }.toList()
    }, { data ->
        val visible = data as List<*>
        server.onlinePlayers.filter { it != this && it.uniqueId.toString() in visible }
            .forEach { showPlayer(plugin, it) }
    }),

    // All Players that can see the player
    @Deprecated(
        "Scheduled for removal. Restoring this shows the player to everyone that could see them when " +
                "the state was captured, which also cancels a hide another feature took in the " +
                "meantime. Take hides through PlayerHides and release them by owner instead.",
        level = DeprecationLevel.ERROR
    )
    SHOWING_PLAYER({
        server.onlinePlayers.filter { it != this && it.canSee(this) }.map { it.uniqueId.toString() }.toList()
    }, { data ->
        val showing = data as List<*>
        server.onlinePlayers.filter { it != this && it.uniqueId.toString() in showing }
            .forEach { it.showPlayer(plugin, this) }
    })
    ;

    override fun store(player: Player): Any = player.store()
    override fun restore(player: Player, value: Any) = player.restore(value)
}

data class EffectStateProvider(
    private val effect: PotionEffectType,
) : PlayerStateProvider {
    override fun store(player: Player): Any {
        return player.getPotionEffect(effect) ?: return false
    }

    override fun restore(player: Player, value: Any) {
        player.removePotionEffect(effect)
        if (value !is PotionEffect) return
        player.addPotionEffect(value)
    }
}

data class InventorySlotStateProvider(
    private val slot: Int,
) : PlayerStateProvider {

    override fun store(player: Player): Any {
        EquipmentSlot.HAND
        return player.inventory.getItem(slot) ?: return false
    }

    override fun restore(player: Player, value: Any) {
        if (value !is ItemStack) {
            player.inventory.setItem(slot, null)
            return
        }
        player.inventory.setItem(slot, value)
    }
}

data class EquipmentSlotStateProvider(
    private val slot: EquipmentSlot,
) : PlayerStateProvider {

    override fun store(player: Player): Any {
        return player.inventory.getItem(slot)
    }

    override fun restore(player: Player, value: Any) {
        if (value !is ItemStack) {
            player.inventory.setItem(slot, null)
            return
        }
        player.inventory.setItem(slot, value)
    }
}

fun Player.state(vararg keys: PlayerStateProvider): PlayerState = state(keys)

@JvmName("stateArray")
fun Player.state(keys: Array<out PlayerStateProvider>): PlayerState {
    return PlayerState(keys.associateWith { it.store(this) })
}

fun Player.state(keys: List<PlayerStateProvider>): PlayerState {
    return PlayerState(keys.associateWith { it.store(this) })
}

fun Player.restore(state: PlayerState?) {
    state?.state?.forEach { (key, value) -> key.restore(this, value) }
}

val fakeAir: com.github.retrooper.packetevents.protocol.item.ItemStack by lazy {
    var builder =
        com.github.retrooper.packetevents.protocol.item.ItemStack.builder()
            .type(ItemTypes.PAPER)
            .component(ComponentTypes.ITEM_MODEL, ItemModel(ResourceLocation("minecraft", "air")))
            .component(ComponentTypes.ITEM_NAME, Component.text(" "))

    builder = if (serverVersion.isOlderThanOrEquals(ServerVersion.V_1_21_4)) {
        builder
            .component(ComponentTypes.HIDE_TOOLTIP, Dummy.dummy())
            .component(ComponentTypes.HIDE_ADDITIONAL_TOOLTIP, Dummy.dummy())
    } else { // 1.21.5+
        builder.component(ComponentTypes.TOOLTIP_DISPLAY, ItemTooltipDisplay(true, emptySet()))
    }

    return@lazy builder.build()
}


fun Player.fakeClearInventory() {
    WrapperPlayServerWindowItems(
        0,
        0,
        (0..45).map { slot ->
            if (slot >= 36) fakeAir else com.github.retrooper.packetevents.protocol.item.ItemStack.EMPTY
        },
        null,
    ) sendPacketTo this
}

fun Player.restoreInventory() {
    // I can't be bother to transform the ids from the normal version to the weird version need for the WrapperPlayServerWindowItems
    // So we just send many packets instead
    for (i in 0..45) {
        val item = inventory.getItem(i) ?: ItemStack.empty()

        val packet = WrapperPlayServerSetSlot(-2, 0, i, SpigotReflectionUtil.decodeBukkitItemStack(item))
        packet.sendPacketTo(this)
    }
}

fun InterceptionBundle.keepFakeInventory() {
    PacketType.Play.Client.CLICK_WINDOW { event ->
        event.isCancelled = true
        event.getPlayer<Player>().fakeClearInventory()
    }
    PacketType.Play.Client.CLICK_WINDOW_BUTTON { event ->
        event.isCancelled = true
        event.getPlayer<Player>().fakeClearInventory()
    }
    !PacketType.Play.Client.USE_ITEM
    !PacketType.Play.Client.INTERACT_ENTITY
    !PacketType.Play.Client.PLAYER_DIGGING
    PacketType.Play.Server.WINDOW_ITEMS { event ->
        val packet = WrapperPlayServerWindowItems(event)
        packet.items = List(packet.items.size) { index ->
            if (index >= 36) fakeAir
            else com.github.retrooper.packetevents.protocol.item.ItemStack.EMPTY
        }
    }
    PacketType.Play.Server.SET_SLOT { event ->
        val packet = WrapperPlayServerSetSlot(event)
        packet.item = if (packet.slot in 0..8) fakeAir
        else com.github.retrooper.packetevents.protocol.item.ItemStack.EMPTY
    }
}

/**
 * Tells this client it can fly, without the server handing out flight.
 *
 * Holding a player still in the air with [Player.setAllowFlight] puts real flight on them, which
 * every other plugin can read back. Plugins that hand out flight themselves take that for flight of
 * their own and can leave the player owed flight long after Typewriter is done with them. Only the
 * client has to believe it, so only the client is told.
 *
 * Hold it with [keepFakeFlight] and end it with [sendRealAbilities].
 */
fun Player.sendFakeFlight() = sendAbilities(flying = true, flightAllowed = true)

/**
 * Puts this client back on the abilities the player actually has, ending [sendFakeFlight].
 *
 * Call it once the [keepFakeFlight] interception is cancelled and the player is standing where they
 * are meant to end up. The interception rewrites this packet back into the faked flight while it is
 * still up, and a player who is put back on real abilities in mid air drops out of it.
 */
fun Player.sendRealAbilities() = sendAbilities(flying = isFlying, flightAllowed = allowFlight)

private fun Player.sendAbilities(flying: Boolean, flightAllowed: Boolean) {
    WrapperPlayServerPlayerAbilities(
        isInvulnerable || gameMode == GameMode.CREATIVE || gameMode == GameMode.SPECTATOR,
        flying,
        flightAllowed,
        gameMode == GameMode.CREATIVE,
        flySpeed.asPacketSpeed(),
        walkSpeed.asPacketSpeed(),
    ) sendPacketTo this
}

/** Bukkit reports a player's speeds at twice what the abilities packet carries. */
private fun Float.asPacketSpeed() = this / 2

/**
 * Keeps a client held up by [sendFakeFlight] in the air.
 *
 * Anything writing the player's flight, speed or game mode makes the server send the abilities they
 * really have, which would drop them out of the air halfway through. The client announces its own
 * flight toggles as well, and the server answers those with the real abilities again.
 *
 * Add it to the bundle the caller intercepts with once [sendFakeFlight] has gone out, and keep that
 * bundle for as long as the player is held. Cancelling it is what lets [sendRealAbilities] through.
 */
fun InterceptionBundle.keepFakeFlight() {
    PacketType.Play.Server.PLAYER_ABILITIES { event ->
        val packet = WrapperPlayServerPlayerAbilities(event)
        packet.isFlying = true
        packet.isFlightAllowed = true
    }
    !PacketType.Play.Client.PLAYER_ABILITIES
}
