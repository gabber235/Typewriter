package com.typewritermc.region.content

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.components.*
import com.typewritermc.engine.paper.content.entryId
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.data.displayColor
import com.typewritermc.region.tracker.RegionTracker
import kotlinx.coroutines.Dispatchers
import net.kyori.adventure.bossbar.BossBar
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.Sound
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.koin.java.KoinJavaComponent
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap

/**
 * The in game debugger for one region definition. Instead of chat spam, the live state
 * renders on the HUD: the boss bar answers "am I inside and did the events see it", and the
 * region draws itself as a glowing outline in its color. The action bar can additionally
 * stream the exact distance numbers, off by default to keep the HUD calm.
 *
 * When a region "does not trigger", this shows which link of the chain is broken.
 */
class RegionDebugContentMode(context: ContentContext, player: Player) : ContentMode(context, player) {
    private val engine: RegionEngine by KoinJavaComponent.inject(RegionEngine::class.java)
    private val editRegistry: RegionEditRegistry by KoinJavaComponent.inject(RegionEditRegistry::class.java)
    private var definitionRef: Ref<RegionDefinitionEntry>? = null
    private val channels = ConcurrentHashMap(
        mapOf(
            DebugChannel.OVERVIEW to true,
            DebugChannel.DISTANCES to false,
            DebugChannel.PREVIEW to true,
        ),
    )
    private val outline = RegionOutline(player)

    @Volatile
    private var lastSample: DebugSample? = null

    @Volatile
    private var disposed = false

    override suspend fun setup(): Result<Unit> {
        val entryId = context.entryId
            ?: return failure("No entryId found for ${this::class.simpleName}. This is a bug. Please report it.")
        definitionRef = Ref(entryId, RegionDefinitionEntry::class)

        bossBar {
            val sample = lastSample
            title = when {
                sample == null -> "<gray>Waiting for the region to resolve…"
                !channels.getValue(DebugChannel.OVERVIEW) -> "<white><bold>${sample.name}</bold> <gray>(overview off)"
                sample.transformResolved -> "<white><bold>${sample.name}</bold> <gray>· ${sample.membershipLine}"
                else -> "<white><bold>${sample.name}</bold> <red>transform unresolved: a placement variable returned nothing"
            }
            color = when {
                sample == null || !sample.transformResolved -> BossBar.Color.PURPLE
                sample.inside && sample.entered -> BossBar.Color.GREEN
                sample.inside && sample.enterMissed -> BossBar.Color.RED
                else -> BossBar.Color.YELLOW
            }
        }
        exit(doubleShiftExits = true)
        +toggleItem(
            0,
            DebugChannel.OVERVIEW,
            Material.ENDER_EYE,
            "Overview",
            "Membership and event state on the boss bar."
        )
        +toggleItem(
            1,
            DebugChannel.DISTANCES,
            Material.BLAZE_ROD,
            "Distances",
            "Hitbox, point and XZ distances on the action bar."
        )
        +toggleItem(
            2,
            DebugChannel.PREVIEW,
            Material.GLOWSTONE_DUST,
            "Boundary",
            "Draw the region's outline in its color."
        )

        return ok(Unit)
    }

    override suspend fun initialize() {
        // Armed again here as well as set in dispose: this mode is initialized again whenever a mode
        // pushed on top of it is popped, and left set it would render nothing ever after.
        disposed = false
        editRegistry.enterMode(player.uniqueId, RegionModeKind.Debug)
        super.initialize()
    }

    override suspend fun tick(deltaTime: Duration) {
        super.tick(deltaTime)
        val definition = definitionRef?.get() ?: return
        val sample = sample(definition)
        lastSample = sample

        if (channels.getValue(DebugChannel.DISTANCES)) {
            player.sendActionBar(sample.distanceLine.asMini())
        }

        // Disposal is checked again on the main thread: sampling takes long enough for a publish
        // or a disconnect to dispose this mode while it runs, and an outline spawned after the
        // despawn is one nothing despawns again.
        Dispatchers.Sync.switchContext { if (!disposed) updateOutline(sample) }
    }

    override suspend fun dispose() {
        disposed = true
        editRegistry.exitMode(player.uniqueId, RegionModeKind.Debug)
        Dispatchers.Sync.switchContext { outline.despawn() }
        super.dispose()
    }

    private fun updateOutline(sample: DebugSample) {
        if (!channels.getValue(DebugChannel.PREVIEW)) {
            outline.despawn()
            return
        }
        val tracker = sample.tracker
        val transform = tracker?.lastTransform
        val world = transform?.let { resolveBukkitWorld(it.world.identifier) }
        if (transform == null || world == null) {
            outline.despawn()
            return
        }
        val anchor = transform.worldOrigin
        outline.update(
            Location(world, anchor.x, anchor.y, anchor.z),
            transform.yawDegrees,
            transform.pitchDegrees,
            tracker.shape,
            sample.color,
            rollDegrees = transform.rollDegrees,
        )
    }

    private fun sample(definition: RegionDefinitionEntry): DebugSample {
        val data = RegionReferenceData(definition.ref())
        val registered = engine.registeredTracker(data, player)
        val tracker = registered ?: engine.query(data, player)
        val color = definition.displayColor(definition.id)
        if (tracker == null) {
            return DebugSample(
                name = definition.name,
                color = color,
                tracker = null,
                transformResolved = false,
                inside = false,
                entered = false,
                enterMissed = false,
                membershipLine = "<red>the region reference does not resolve",
                distanceLine = "<red>The region reference does not resolve to a definition.",
            )
        }

        val snapshot = tracker.debugSnapshot()
        val transform = snapshot.transform
        val hitbox = tracker.hitboxDistance(player)
        val point = tracker.signedDistance(player.position)
        val horizontal = tracker.signedDistance(player.position, DistanceMode.HORIZONTAL)
        val inside = hitbox != null && hitbox <= 0.0
        val entered = tracker.countsAsEntered(player)
        val observed = registered != null && snapshot.enterExitHandlers > 0
        val enterMissed = observed && inside && !entered

        val membership = if (inside) "<green>inside</green>" else "<gray>outside</gray>"
        val events = when {
            !observed -> "<red>no enter/exit observers</red>"
            entered -> "<green>events entered</green>"
            inside -> "<red>enter did not fire</red>"
            else -> "<white>events not entered</white>"
        }

        return DebugSample(
            name = definition.name,
            color = color,
            tracker = tracker,
            transformResolved = transform != null,
            inside = inside,
            entered = entered,
            enterMissed = enterMissed,
            membershipLine = "$membership <gray>· $events",
            distanceLine = "<gray>hitbox <white>${hitbox.formatted()}</white> <gray>· point <white>${point.formatted()}</white>" +
                    " <gray>· xz <white>${horizontal.formatted()}</white> <dark_gray>(negative = inside)",
        )
    }

    private fun toggleItem(
        slot: Int,
        channel: DebugChannel,
        material: Material,
        title: String,
        description: String,
    ): ItemComponent = object : ItemComponent {
        override fun item(player: Player): Pair<Int, IntractableItem> {
            val enabled = channels.getValue(channel)
            val item = ItemStack(material).apply {
                editMeta { meta ->
                    meta.name = if (enabled) "<gold><bold>$title <green>(on)" else "<gray><bold>$title <dark_gray>(off)"
                    meta.loreString = """
                        |
                        |<line> <gray>$description
                        |<line> <gray>Click to turn it ${if (enabled) "off" else "on"}.
                    """.trimMargin()
                    @Suppress("UsePropertyAccessSyntax") // Getter and setter signatures differ in nullability, so property syntax doesn't compile
                    if (enabled) meta.setEnchantmentGlintOverride(true)
                }
            }
            return slot to (item onInteract { interaction ->
                if (!interaction.type.isClick) return@onInteract
                val nowEnabled = !channels.getValue(channel)
                channels[channel] = nowEnabled
                player.playSound(player.location, Sound.BLOCK_LEVER_CLICK, 0.6f, if (nowEnabled) 1.4f else 0.8f)
                player.sendActionBar(
                    "<gray>$title ${if (nowEnabled) "<green>enabled" else "<red>disabled"}".asMini(),
                )
            })
        }
    }

    private fun Double?.formatted(): String = this?.round(2)?.toString() ?: "n/a"

    private data class DebugSample(
        val name: String,
        val color: Color,
        val tracker: RegionTracker?,
        val transformResolved: Boolean,
        val inside: Boolean,
        val entered: Boolean,
        val enterMissed: Boolean,
        val membershipLine: String,
        val distanceLine: String,
    )

    private enum class DebugChannel { OVERVIEW, DISTANCES, PREVIEW }
}
