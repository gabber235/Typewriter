package com.typewritermc.engine.paper.content

import com.github.retrooper.packetevents.event.PacketReceiveEvent
import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientCreativeInventoryAction
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetSlot
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.content.components.IntractableItem
import com.typewritermc.engine.paper.content.components.ItemInteraction
import com.typewritermc.engine.paper.content.components.ItemInteractionType
import com.typewritermc.engine.paper.events.ContentEditorEndEvent
import com.typewritermc.engine.paper.events.ContentEditorStartEvent
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.engine.paper.interaction.interceptPackets
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.msg
import com.typewritermc.engine.paper.utils.playSound
import io.github.retrooper.packetevents.util.SpigotReflectionUtil
import kotlinx.coroutines.Dispatchers
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import org.bukkit.Bukkit
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.block.Action
import org.bukkit.event.inventory.InventoryClickEvent
import org.bukkit.event.player.PlayerDropItemEvent
import org.bukkit.event.player.PlayerInteractEvent
import org.bukkit.event.player.PlayerSwapHandItemsEvent
import org.bukkit.inventory.ItemStack
import org.koin.java.KoinJavaComponent
import java.time.Duration
import java.util.concurrent.ConcurrentLinkedDeque

class ContentInteraction(
    val contentContext: ContentContext,
    val player: Player,
    mode: ContentMode,
    override val context: InteractionContext,
) : Interaction, Listener {
    private val stack = ConcurrentLinkedDeque(listOf(mode))

    @Volatile
    private var items = emptyMap<Int, IntractableItem>()
    private val cachedOriginalItems = mutableMapOf<Int, ItemStack>()
    private var lastHandledDropTick = Int.MIN_VALUE
    private var creativeGuard: InterceptionBundle? = null

    private val mode: ContentMode?
        get() = stack.peek()

    override val priority: Int
        get() = Int.MAX_VALUE

    override suspend fun initialize(): Result<Unit> {
        player.playSound("block.beacon.activate")
        Dispatchers.Sync.switchContext {
            ContentEditorStartEvent(player).callEvent()
        }
        val mode = mode ?: return failure("No content mode found")
        val result = mode.setup()
        if (result.isFailure) {
            logger.severe("Failed to setup content mode for player ${player.name}: ${result.exceptionOrNull()?.message}")
            player.msg("<red><b>Failed to setup content mode. Please see the console for more details.")
            return result
        }
        mode.initialize()
        plugin.registerEvents(this)
        creativeGuard = player.interceptPackets {
            PacketType.Play.Client.CREATIVE_INVENTORY_ACTION { event -> guardCreativeAction(event) }
        }
        return ok(Unit)
    }

    override suspend fun tick(deltaTime: Duration) {
        applyInventory()
        mode?.tick(deltaTime)
    }

    private suspend fun applyInventory() {
        val previousSlots = items.keys
        items = mode?.items() ?: emptyMap()
        val currentSlots = items.keys
        val newSlots = currentSlots - previousSlots
        val removedSlots = previousSlots - currentSlots
        Dispatchers.Sync.switchContext {
            newSlots.forEach { slot ->
                val originalItem = player.inventory.getItem(slot) ?: ItemStack.empty()
                cachedOriginalItems.putIfAbsent(slot, originalItem)
            }
            items.forEach { (slot, item) ->
                player.inventory.setItem(slot, item.item)
            }
            removedSlots.forEach { slot ->
                val originalItem = cachedOriginalItems.remove(slot)
                player.inventory.setItem(slot, originalItem)
            }
        }
    }

    suspend fun pushMode(newMode: ContentMode): Result<Unit> {
        player.playSound("ui.loom.take_result")
        val previous = mode
        val result = newMode.setup()
        stack.push(newMode)
        previous?.dispose()
        if (result.isFailure) {
            logger.severe("Failed to setup content mode: ${result.exceptionOrNull()?.message}")
            player.msg("<red><bold>Failed to setup content mode. Please see the console for more details.")
            return result
        }
        newMode.initialize()
        return ok(Unit)
    }

    suspend fun swapMode(newMode: ContentMode): Result<Unit> {
        player.playSound("ui.loom.take_result")
        val previous = stack.pop()
        val result = newMode.setup()
        stack.push(newMode)
        previous.dispose()
        if (result.isFailure) {
            logger.severe("Failed to setup content mode: ${result.exceptionOrNull()?.message}")
            player.msg("<red><bold>Failed to setup content mode. Please see the console for more details.")
            return result
        }
        newMode.initialize()
        return ok(Unit)
    }

    suspend fun popMode(): Boolean {
        if (stack.isEmpty()) return false
        player.playSound("ui.cartography_table.take_result")
        stack.pop().dispose()
        mode?.initialize()
        return mode != null
    }

    override suspend fun teardown() {
        unregister()
        creativeGuard?.cancel()
        creativeGuard = null
        Dispatchers.Sync.switchContext {
            cachedOriginalItems.forEach { (slot, item) ->
                player.inventory.setItem(slot, item)
            }
            cachedOriginalItems.clear()
            val cache = stack.toList()
            stack.clear()
            cache.forEach { it.dispose() }
            player.playSound("block.beacon.deactivate")
            ContentEditorEndEvent(player).callEvent()
        }
    }

    fun isInLastMode(): Boolean = stack.size == 1

    /**
     * A creative client owns its own inventory: it applies an edit locally and only then
     * tells the server, so the move cannot be refused, only undone. Dropping the packet
     * keeps the server side intact and the client is sent the truth for the slot it
     * touched.
     *
     * Both directions have to be covered. An edit landing on a slot the editor owns would
     * take a content item away, and an edit carrying a content item towards any other slot
     * or towards the ground would leave a second copy behind once the editor writes its
     * own slot back.
     *
     * Runs on a netty thread, so nothing here may touch the inventory directly.
     */
    private fun guardCreativeAction(event: PacketReceiveEvent) {
        val contentItems = items
        if (contentItems.isEmpty()) return

        val packet = WrapperPlayClientCreativeInventoryAction(event)
        val ownedSlot = creativeSlotToInventorySlot(packet.slot)?.takeIf { it in contentItems }
        if (ownedSlot != null) {
            event.isCancelled = true
            val item = SpigotReflectionUtil.decodeBukkitItemStack(contentItems.getValue(ownedSlot).item)
            WrapperPlayServerSetSlot(PLAYER_INVENTORY_WINDOW_ID, 0, ownedSlot, item) sendPacketTo player
            return
        }

        val written: ItemStack = SpigotReflectionUtil.encodeBukkitItemStack(packet.itemStack) ?: return
        if (contentItems.values.none { it.item.isSimilar(written) }) return
        event.isCancelled = true
        Bukkit.getScheduler().runTask(plugin, Runnable { player.updateInventory() })
    }

    @EventHandler
    fun onInventoryClick(event: InventoryClickEvent) {
        if (event.whoClicked != player) return
        val movesContentItemViaHotbar = event.hotbarButton >= 0 && items[event.hotbarButton] != null
        if (event.clickedInventory != player.inventory) {
            if (movesContentItemViaHotbar) event.isCancelled = true
            return
        }
        val item = items[event.slot]
        if (item == null) {
            if (movesContentItemViaHotbar) event.isCancelled = true
            return
        }
        item.action(
            ItemInteraction(ItemInteractionType.INVENTORY_CLICK, event.slot, null),
        )
        event.isCancelled = true
    }

    @EventHandler
    fun onInteract(event: PlayerInteractEvent) {
        if (event.player != player) return
        // The even triggers twice. Both for the main hand and offhand.
        // We only want to trigger once.
        if (event.hand != org.bukkit.inventory.EquipmentSlot.HAND) return // Disable off-hand interactions
        val slot = player.inventory.heldItemSlot
        val item = items[slot] ?: return
        val type = when (event.action) {
            Action.LEFT_CLICK_AIR,
            Action.LEFT_CLICK_BLOCK -> {
                // Dropping an item also swings the arm, which the server reports as a left click.
                // Without this guard the drop key would trigger the click action as well.
                if (Bukkit.getCurrentTick() <= lastHandledDropTick + 1) {
                    event.isCancelled = true
                    return
                }
                if (event.player.isSneaking) ItemInteractionType.SHIFT_LEFT_CLICK else ItemInteractionType.LEFT_CLICK
            }

            Action.RIGHT_CLICK_AIR,
            Action.RIGHT_CLICK_BLOCK -> if (event.player.isSneaking) ItemInteractionType.SHIFT_RIGHT_CLICK else ItemInteractionType.RIGHT_CLICK

            else -> return
        }
        item.action(ItemInteraction(type, slot, event.clickedBlock))
        event.isCancelled = true
    }

    @EventHandler
    fun onDropItem(event: PlayerDropItemEvent) {
        if (event.player != player) return
        val slot = player.inventory.heldItemSlot
        val item = items[slot] ?: return
        lastHandledDropTick = Bukkit.getCurrentTick()
        item.action(ItemInteraction(ItemInteractionType.DROP, slot, null))
        event.isCancelled = true
    }

    @EventHandler
    fun onSwapItem(event: PlayerSwapHandItemsEvent) {
        if (event.player != player) return
        val slot = player.inventory.heldItemSlot
        val item = items[slot] ?: return
        item.action(ItemInteraction(ItemInteractionType.SWAP, slot, null))
        event.isCancelled = true
    }
}

private val Player.contentInteraction: ContentInteraction?
    get() =
        with(KoinJavaComponent.get<PlayerSessionManager>(PlayerSessionManager::class.java)) {
            session?.interaction as? ContentInteraction
        }

/**
 * Weather the player is currently in a content interaction.
 */
val Player.isInContentInteraction: Boolean
    get() = contentInteraction != null

/**
 * Weather the current content mode is the last one in the stack.
 */
val Player.inLastContentMode: Boolean
    get() = contentInteraction?.isInLastMode() == true