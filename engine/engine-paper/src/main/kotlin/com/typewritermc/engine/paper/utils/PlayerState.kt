package com.typewritermc.engine.paper.utils

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetSlot
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTimeUpdate
import io.github.retrooper.packetevents.util.SpigotReflectionUtil
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.plugin
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

    // All Players that are visible to the player
    VISIBLE_PLAYERS({
        server.onlinePlayers.filter { it != this && canSee(it) }.map { it.uniqueId.toString() }.toList()
    }, { data ->
        val visible = data as List<*>
        server.onlinePlayers.filter { it != this && it.uniqueId.toString() in visible }
            .forEach { showPlayer(plugin, it) }
    }),

    // All Players that can see the player
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

fun Player.restore(state: PlayerState?) {
    state?.state?.forEach { (key, value) -> key.restore(this, value) }
}

fun Player.fakeClearInventory() {
    for (i in 0..46) {
        val item = inventory.getItem(i) ?: continue
        if (item.type.isAir) continue

        val packet = WrapperPlayServerSetSlot(-2, 0, i, com.github.retrooper.packetevents.protocol.item.ItemStack.EMPTY)
        packet.sendPacketTo(this)
    }
}

fun Player.restoreInventory() {
    for (i in 0..46) {
        val item = inventory.getItem(i) ?: continue
        if (item.type.isAir) continue

        val packet = WrapperPlayServerSetSlot(-2, 0, i, SpigotReflectionUtil.decodeBukkitItemStack(item))
        packet.sendPacketTo(this)
    }
}
