package com.typewritermc.playtest.plugin

import com.destroystokyo.paper.event.player.PlayerUseUnknownEntityEvent
import com.typewritermc.playtest.wire.Payload
import io.papermc.paper.adventure.PaperAdventure
import net.kyori.adventure.text.Component
import net.minecraft.core.registries.BuiltInRegistries
import net.minecraft.network.protocol.Packet
import net.minecraft.network.protocol.common.ClientboundCustomPayloadPacket
import net.minecraft.network.protocol.common.custom.DiscardedPayload
import net.minecraft.network.protocol.game.ClientboundAddEntityPacket
import net.minecraft.network.protocol.game.ClientboundRemoveEntitiesPacket
import net.minecraft.network.protocol.game.ClientboundSetEntityDataPacket
import net.minecraft.resources.Identifier
import net.minecraft.world.entity.EntitySpawnReason
import net.minecraft.world.phys.Vec3
import org.bukkit.Bukkit
import org.bukkit.GameMode
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.NamespacedKey
import org.bukkit.Registry
import org.bukkit.World
import org.bukkit.command.Command
import org.bukkit.command.CommandSender
import org.bukkit.craftbukkit.CraftServer
import org.bukkit.craftbukkit.CraftWorld
import org.bukkit.craftbukkit.entity.CraftEntity
import org.bukkit.craftbukkit.entity.CraftPlayer
import org.bukkit.entity.Entity
import org.bukkit.entity.LivingEntity
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockBreakEvent
import org.bukkit.event.entity.EntityDamageByEntityEvent
import org.bukkit.event.player.PlayerInteractEntityEvent
import org.bukkit.inventory.ItemStack
import org.bukkit.plugin.Plugin
import org.bukkit.scoreboard.Criteria
import org.bukkit.scoreboard.DisplaySlot
import org.bukkit.util.Vector
import skirout.harness.v1.wire.BlockPos
import skirout.harness.v1.wire.PlayerAction
import skirout.harness.v1.wire.ProbeAction
import skirout.harness.v1.wire.StateKind
import skirout.harness.v1.wire.Watch
import skirout.harness.v1.wire.WorldAction
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import skirout.harness.v1.wire.GameMode as WireGameMode

private const val MAX_FILL = 4_096
private val WATCH: Identifier = Identifier.parse(Payload.WATCH_CHANNEL)

/**
 * The arrangements a requirement asks Paper for. Main thread only. Each runs at once and returns null,
 * or returns why it could not. What a probe gives a player (a command, an entity only its client knows)
 * is that player's alone, and a claim takes it away again; what it places in the world stays in the
 * attempt's region, which no later attempt uses.
 */
internal class Probes(
    private val plugin: Plugin,
    /** Leaves a mark of a kind of state on a player, for the framework's own test kit. */
    private val mark: (Player, StateKind) -> Unit,
) : Listener {
    /** How a probe entity answers a player: the name tag it shows once hit or used. */
    private data class Reactions(
        val onHit: String?,
        val onClick: String?,
    )

    /**
     * A packet only entity: the client that knows it, how it reacts, and a detached server entity of its
     * type, never added to a world, that gives it a network id and builds the metadata the client expects.
     */
    private data class PacketEntity(
        val viewer: UUID,
        val detached: net.minecraft.world.entity.Entity,
        val reactions: Reactions,
    )

    private val spawned = HashMap<UUID, Reactions>()
    private val packetEntities = HashMap<Int, PacketEntity>()
    private val unbreakable = HashSet<Location>()
    private val commands = HashMap<String, SuggestingCommand>()

    /**
     * Runs [action]: an action on a player for each of [players], an action on the world once, in their
     * world. Null when it ran, else why not.
     */
    fun run(
        players: List<Player>,
        action: ProbeAction,
    ): String? {
        watch(players, action)
        return when (action) {
            is ProbeAction.OnWorldWrapper -> run(players.first().world, action.value)
            is ProbeAction.OnPlayerWrapper -> players.firstNotNullOfOrNull { run(it, action.value) }
            else -> "a probe action this Paper does not know: $action"
        }
    }

    private fun run(
        world: World,
        action: WorldAction,
    ): String? =
        when (action) {
            is WorldAction.FillWrapper -> {
                fill(world, action.value.from, action.value.to, action.value.block)
            }

            is WorldAction.BlockWrapper -> {
                fill(world, action.value.at, action.value.at, action.value.block)
            }

            is WorldAction.SpawnWrapper -> {
                spawn(world, action.value)
            }

            is WorldAction.CancelBreakingWrapper -> {
                unbreakable.add(location(world, action.value.at))
                null
            }

            else -> {
                "a world action this Paper does not know: $action"
            }
        }

    /** Arranges [player] itself: its game mode, place, inventory, marks, work and saved data; else what its client is shown. */
    private fun run(
        player: Player,
        action: PlayerAction,
    ): String? =
        when (action) {
            is PlayerAction.GameModeWrapper -> {
                gameMode(player, action.value)
            }

            is PlayerAction.TeleportWrapper -> {
                val teleport = action.value
                player.velocity = Vector()
                player.fallDistance = 0f
                player.teleport(Location(player.world, teleport.x, teleport.y, teleport.z, teleport.yaw, teleport.pitch))
                null
            }

            is PlayerAction.GiveWrapper -> {
                give(player, action.value)
            }

            is PlayerAction.SelectSlotWrapper -> {
                selectSlot(player, action.value.slot)
            }

            is PlayerAction.MarkWrapper -> {
                mark(player, action.value.kind)
                null
            }

            is PlayerAction.WorkWrapper -> {
                work(player, action.value)
                null
            }

            PlayerAction.SAVE -> {
                player.saveData()
                null
            }

            else -> {
                show(player, action)
            }
        }

    /** Shows [player]'s client what [action] names: a chat line, an entity, a command, a sidebar or a time of day. */
    private fun show(
        player: Player,
        action: PlayerAction,
    ): String? =
        when (action) {
            is PlayerAction.ChatWrapper -> {
                player.sendMessage(Component.text(action.value.text))
                null
            }

            is PlayerAction.PacketEntityWrapper -> {
                packetEntity(player, action.value)
            }

            is PlayerAction.CommandWrapper -> {
                command(player, action.value)
            }

            is PlayerAction.SidebarWrapper -> {
                sidebar(player, action.value)
            }

            is PlayerAction.TimeWrapper -> {
                player.setPlayerTime(action.value.time, false)
                null
            }

            else -> {
                "a player action this Paper does not know: $action"
            }
        }

    /**
     * Takes from [players] what earlier probes gave them alone: every probe command and every entity only
     * their clients know.
     */
    fun forget(players: List<Player>) {
        for (player in players) {
            for (command in commands.values) command.answers.remove(player.uniqueId)
            val known = packetEntities.filterValues { it.viewer == player.uniqueId }.keys.toList()
            if (known.isNotEmpty()) send(player, ClientboundRemoveEntitiesPacket(*known.toIntArray()))
            known.forEach { packetEntities.remove(it) }
            player.updateCommands()
        }
    }

    /**
     * Runs the work on Bukkit's async scheduler as a plugin would, counted from the moment it is handed
     * over. An interrupt would cancel it before its chat line; nothing here interrupts it.
     */
    private fun work(
        player: Player,
        work: PlayerAction.Work,
    ) {
        Bukkit.getScheduler().runTaskAsynchronously(
            plugin,
            PlayerWork.task(player, work.name) {
                try {
                    Thread.sleep(work.millis.toLong())
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return@task
                }
                player.sendMessage(Component.text(work.chat))
            },
        )
    }

    private fun spawn(
        world: World,
        spawn: WorldAction.Spawn,
    ): String? {
        val type = NamespacedKey.fromString(spawn.entityType)?.let { Registry.ENTITY_TYPE.get(it) }
        val entityClass = type?.entityClass
        if (type == null || !type.isSpawnable || entityClass == null) return "no entity type ${spawn.entityType}"
        val at = Location(world, spawn.x, spawn.y, spawn.z, spawn.yaw, 0f)
        world.spawn(at, entityClass) { entity ->
            (entity as CraftEntity).handle.setUUID(UUID.fromString(spawn.uuid))
            entity.isSilent = true
            entity.isPersistent = true
            entity.isInvisible = spawn.invisible
            if (entity is LivingEntity) {
                entity.setAI(false)
                entity.removeWhenFarAway = false
            }
        }
        spawned[UUID.fromString(spawn.uuid)] = Reactions(spawn.onHit, spawn.onClick)
        return null
    }

    private fun packetEntity(
        viewer: Player,
        spawn: PlayerAction.PacketEntity,
    ): String? {
        val key = Identifier.tryParse(spawn.entityType)
        val type = key?.let { BuiltInRegistries.ENTITY_TYPE.getOptional(it).orElse(null) } ?: return "no entity type ${spawn.entityType}"
        val detached =
            type.create((viewer.world as CraftWorld).handle, EntitySpawnReason.COMMAND)
                ?: return "entity type ${spawn.entityType} cannot be created"
        val id = detached.id
        send(
            viewer,
            ClientboundAddEntityPacket(
                id,
                UUID.fromString(spawn.uuid),
                spawn.x,
                spawn.y,
                spawn.z,
                0f,
                spawn.yaw,
                type,
                0,
                Vec3.ZERO,
                spawn.yaw.toDouble(),
            ),
        )
        packetEntities[id] = PacketEntity(viewer.uniqueId, detached, Reactions(spawn.onHit, spawn.onClick))
        return null
    }

    /** [player] may run `/name`, which suggests and answers as [probe] says, for it alone. */
    private fun command(
        player: Player,
        probe: PlayerAction.Command,
    ): String? {
        val command =
            commands.getOrPut(probe.name) {
                SuggestingCommand(probe.name).also {
                    Bukkit.getCommandMap().register("playtest", it)
                    (Bukkit.getServer() as CraftServer).syncCommands()
                }
            }
        command.answers[player.uniqueId] = SuggestingCommand.Answer(probe.suggestions.toList(), probe.answer)
        player.updateCommands()
        return null
    }

    @EventHandler(ignoreCancelled = true)
    fun onBreak(event: BlockBreakEvent) {
        if (event.block.location in unbreakable) event.isCancelled = true
    }

    @EventHandler
    fun onHit(event: EntityDamageByEntityEvent) {
        val onHit = spawned[event.entity.uniqueId]?.onHit
        if (onHit != null && event.damager is Player) name(event.entity, onHit)
    }

    @EventHandler
    fun onUse(event: PlayerInteractEntityEvent) {
        val onClick = spawned[event.rightClicked.uniqueId]?.onClick
        if (onClick != null) name(event.rightClicked, onClick)
    }

    @EventHandler
    fun onUseUnknown(event: PlayerUseUnknownEntityEvent) {
        val entity = packetEntities[event.entityId]
        if (entity == null || entity.viewer != event.player.uniqueId) return
        val name = (if (event.isAttack) entity.reactions.onHit else entity.reactions.onClick) ?: return
        // The client knows this entity from packets alone, so its name tag changes by packet too.
        val detached = entity.detached
        detached.setCustomName(PaperAdventure.asVanilla(Component.text(name)))
        detached.setCustomNameVisible(true)
        val changed = detached.entityData.packDirty()
        if (changed != null) send(event.player, ClientboundSetEntityDataPacket(detached.id, changed))
    }

    /**
     * A command probes made: exists only for the players a probe gave it to, and for each suggests what
     * that probe named and answers with what was typed. Suggestions run on Paper's own threads.
     */
    private class SuggestingCommand(
        name: String,
    ) : Command(name) {
        data class Answer(
            val suggestions: List<String>,
            val answer: String,
        )

        val answers: MutableMap<UUID, Answer> = ConcurrentHashMap()

        override fun testPermissionSilent(sender: CommandSender): Boolean = sender is Player && answers.containsKey(sender.uniqueId)

        override fun execute(
            sender: CommandSender,
            label: String,
            args: Array<String>,
        ): Boolean {
            val answer = (sender as? Player)?.let { answers[it.uniqueId] }
            if (answer != null) sender.sendMessage(Component.text(answer.answer + " " + args.joinToString(" ")))
            return true
        }

        override fun tabComplete(
            sender: CommandSender,
            alias: String,
            args: Array<String>,
        ): List<String> {
            val answer = (sender as? Player)?.let { answers[it.uniqueId] } ?: return listOf()
            val typed = args.lastOrNull() ?: ""
            return answer.suggestions.filter { it.startsWith(typed) }
        }
    }
}

/** Selects hotbar [slot] of [player], or says why not. */
private fun selectSlot(
    player: Player,
    slot: Int,
): String? {
    if (slot !in 0..8) return "hotbar slot $slot is not 0 to 8"
    player.inventory.heldItemSlot = slot
    return null
}

/**
 * Each of [players] watches what [action] puts in front of it. Paper sends the watch on the player's
 * own connection ahead of the packets that show the block or entity, so the client handles the watch
 * first and records them from the tick those packets arrive in.
 */
private fun watch(
    players: List<Player>,
    action: ProbeAction,
) {
    val watched = watchOf(action)
    if (watched != null) players.forEach { watch(it, watched) }
}

/** What [action] puts in front of its players: a block or an entity, or nothing to watch. */
private fun watchOf(action: ProbeAction): Watch? {
    if (action is ProbeAction.OnWorldWrapper) {
        val world = action.value
        if (world is WorldAction.BlockWrapper) return watch(blocks = listOf(world.value.at), entities = listOf())
        if (world is WorldAction.SpawnWrapper) return watch(blocks = listOf(), entities = listOf(world.value.uuid))
    }
    val each = (action as? ProbeAction.OnPlayerWrapper)?.value
    if (each is PlayerAction.PacketEntityWrapper) return watch(blocks = listOf(), entities = listOf(each.value.uuid))
    return null
}

private fun watch(
    blocks: List<BlockPos>,
    entities: List<String>,
): Watch = Watch(blocks = blocks, entities = entities)

/**
 * Sends [player]'s client [watch] as a raw payload, since Bukkit's plugin
 * messages drop channels the client never announced.
 */
private fun watch(
    player: Player,
    watch: Watch,
) {
    send(player, ClientboundCustomPayloadPacket(DiscardedPayload(WATCH, Payload.body(watch))))
}

/**
 * Gives the player a scoreboard of its own whose sidebar shows the lines top to bottom: each line
 * scores one more than the line below it. The wipe hands the player the main scoreboard again.
 */
private fun sidebar(
    player: Player,
    sidebar: PlayerAction.Sidebar,
): String? {
    val lines = sidebar.lines
    if (lines.toSet().size != lines.size) return "a sidebar shows each line once: $lines"
    val board = Bukkit.getScoreboardManager().newScoreboard
    val objective = board.registerNewObjective("playtest_sidebar", Criteria.DUMMY, Component.text(sidebar.title))
    objective.displaySlot = DisplaySlot.SIDEBAR
    lines.forEachIndexed { index, line -> objective.getScore(line).score = lines.size - index }
    player.scoreboard = board
    return null
}

private fun gameMode(
    player: Player,
    mode: WireGameMode,
): String? {
    val bukkit =
        when (mode.kind) {
            WireGameMode.Kind.SURVIVAL_CONST -> GameMode.SURVIVAL
            WireGameMode.Kind.CREATIVE_CONST -> GameMode.CREATIVE
            WireGameMode.Kind.ADVENTURE_CONST -> GameMode.ADVENTURE
            WireGameMode.Kind.SPECTATOR_CONST -> GameMode.SPECTATOR
            WireGameMode.Kind.UNKNOWN -> null
        } ?: return "game mode $mode is none this plugin knows"
    player.gameMode = bukkit
    return null
}

private fun give(
    player: Player,
    give: PlayerAction.Give,
): String? {
    val material = Material.matchMaterial(give.item)
    if (material == null || !material.isItem) return "no item ${give.item}"
    if (give.slot !in 0..40) return "inventory slot ${give.slot} is not 0 to 40"
    player.inventory.setItem(give.slot, if (material.isAir) null else ItemStack(material, give.count))
    return null
}

private fun fill(
    world: World,
    from: BlockPos,
    to: BlockPos,
    block: String,
): String? {
    val data =
        try {
            Bukkit.createBlockData(block)
        } catch (_: IllegalArgumentException) {
            return "no block state $block"
        }
    val count = (abs(to.x - from.x) + 1).toLong() * (abs(to.y - from.y) + 1) * (abs(to.z - from.z) + 1)
    if (count > MAX_FILL) return "a fill of $count blocks is over the limit of $MAX_FILL"
    for (x in min(from.x, to.x)..max(from.x, to.x)) {
        for (y in min(from.y, to.y)..max(from.y, to.y)) {
            for (z in min(from.z, to.z)..max(from.z, to.z)) {
                world.getBlockAt(x, y, z).setBlockData(data, false)
            }
        }
    }
    return null
}

private fun name(
    entity: Entity,
    name: String,
) {
    entity.customName(Component.text(name))
    entity.isCustomNameVisible = true
}

private fun send(
    player: Player,
    packet: Packet<*>,
) {
    (player as CraftPlayer).handle.connection.send(packet)
}

private fun location(
    world: World,
    at: BlockPos,
): Location = Location(world, at.x.toDouble(), at.y.toDouble(), at.z.toDouble())
