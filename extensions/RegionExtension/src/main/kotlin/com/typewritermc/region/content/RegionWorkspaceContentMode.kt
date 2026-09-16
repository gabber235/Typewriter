package com.typewritermc.region.content

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.ok
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.ContentModeTrigger
import com.typewritermc.engine.paper.content.components.*
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.stagedEntry
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.region.content.RegionWorkspaceContentMode.Companion.PULSE_STEP_TICKS
import com.typewritermc.region.data.RegionDefinition
import com.typewritermc.region.data.buildShapeOrNull
import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.data.displayColor
import com.typewritermc.region.data.hasConstPlacement
import com.typewritermc.region.shape.Shape
import kotlinx.coroutines.Dispatchers
import net.kyori.adventure.bossbar.BossBar
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.Sound
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.koin.java.KoinJavaComponent
import java.time.Duration
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.PI
import kotlin.math.cos

/**
 * The multi region workspace: every statically placed region near the player renders at
 * once, each outlined in its own color with a floating name tag, so a whole hub of
 * triggers is visible in one glance. Aim at a region (or cycle with the compass) and
 * right click to open its full editor as a sub mode; applying or leaving the editor drops
 * back into the workspace to pick the next region.
 *
 * Two toggles filter the listing: the book shows or hides the region definition entries,
 * the item frame shows or hides inline definitions living inside consumer entries. Inline
 * regions open the same shape editors through their entry's field paths.
 *
 * Dynamic regions (variable bound placement) resolve per player and have no fixed home in
 * the world, so they are not listed.
 */
class RegionWorkspaceContentMode(context: ContentContext, player: Player) : ContentMode(context, player) {
    private val editRegistry: RegionEditRegistry by KoinJavaComponent.inject(RegionEditRegistry::class.java)
    /**
     * Replaced wholesale rather than cleared and refilled. The refresh runs on the tick thread
     * while the compass reads this on the main one, and an empty window between the two is a
     * division by zero in [cycleLock].
     */
    @Volatile
    private var nearby: List<WorkspaceRegion> = emptyList()
    private val outlines = mutableMapOf<String, RegionOutline>()
    private val holograms = mutableMapOf<String, EditorHologram>()

    @Volatile
    private var targetedId: String? = null

    @Volatile
    private var lockedId: String? = null

    @Volatile
    private var inRangeCount = 0

    @Volatile
    private var showDefinitions = true

    @Volatile
    private var showInline = false
    @Volatile
    private var refreshTicks = REFRESH_INTERVAL_TICKS
    private var pulseTicks = 0L

    @Volatile
    private var disposed = false

    override suspend fun setup(): Result<Unit> {
        bossBar {
            val target = targeted()
            val capped = if (inRangeCount > nearby.size && nearby.isNotEmpty()) {
                " <gray>(showing the ${nearby.size} closest)</gray>"
            } else ""
            title = when {
                nearby.isEmpty() && !showDefinitions && !showInline ->
                    "<gray>Everything is hidden. Toggle the book or the item frame."

                nearby.isEmpty() -> "<gray>No ${listedKinds()} within $RANGE blocks."
                target == null ->
                    "<white><bold>$inRangeCount</bold> region${if (inRangeCount == 1) "" else "s"} nearby$capped " +
                            "<gray>· aim at one to select it"

                else -> "<white><bold>$inRangeCount</bold> nearby$capped <gray>· selected " +
                        "<white>${target.name}</white>${if (lockedId != null) " <yellow>(locked)" else ""}" +
                        (target.editorName?.let { " <yellow>· ✎ $it is editing" } ?: "") +
                        (if (target.unpublished) " <gold>· unpublished" else "") +
                        " · <white>right-click</white> the compass to edit"
            }
            color = if (target == null) BossBar.Color.WHITE else BossBar.Color.GREEN
        }
        // No double shift exit: the teleport tool's border jump is a sneak gesture, and two
        // quick shifts around it would silently close the workspace.
        exit()
        +selectorItem()
        +TeleportToolComponent(1, ::teleportToTarget, ::teleportToTargetBorder, ::teleportBack) {}
        +toggleItem(
            slot = 3,
            material = Material.BOOK,
            name = "Region Entries",
            description = "the regions defined by their own entry",
            shown = { showDefinitions },
        ) { showDefinitions = it }
        +toggleItem(
            slot = 4,
            material = Material.ITEM_FRAME,
            name = "Inline Regions",
            description = "the regions defined inside another entry's field",
            shown = { showInline },
        ) { showInline = it }
        return ok(Unit)
    }

    private fun listedKinds(): String = when {
        showDefinitions && showInline -> "statically placed regions"
        showDefinitions -> "statically placed region entries"
        else -> "statically placed inline regions"
    }

    override suspend fun initialize() {
        // Armed again here as well as set in dispose: popping an editor opened from the workspace
        // initializes this mode again, and left set it would render nothing ever after.
        disposed = false
        editRegistry.enterMode(player.uniqueId, RegionModeKind.Workspace)
        // Rerun when an editor sub mode is popped, which is exactly when the listing is stale:
        // it still holds the region as it looked before the edit was applied.
        refreshTicks = REFRESH_INTERVAL_TICKS
        super.initialize()
    }

    override suspend fun tick(deltaTime: Duration) {
        super.tick(deltaTime)
        refreshTicks++
        if (refreshTicks >= REFRESH_INTERVAL_TICKS) {
            refreshTicks = 0
            refreshNearby()
        }
        updateTargeting()
        // Disposal is checked again on the main thread: the sweep above takes long enough for a
        // publish or a disconnect to dispose this mode while it runs, and a render landing after
        // the despawn spawns outlines and name tags into a map nothing despawns again.
        Dispatchers.Sync.switchContext { if (!disposed) renderRegions() }
    }

    override suspend fun dispose() {
        disposed = true
        editRegistry.exitMode(player.uniqueId, RegionModeKind.Workspace)
        Dispatchers.Sync.switchContext {
            outlines.values.forEach(RegionOutline::despawn)
            outlines.clear()
            holograms.values.forEach(EditorHologram::despawn)
            holograms.clear()
        }
        super.dispose()
    }

    private fun refreshNearby() {
        val playerPosition = Vector(player.location.x, player.location.y, player.location.z)
        val worldId = player.world.uid.toString()
        val regions = buildList {
            if (showDefinitions) {
                Query.find<RegionDefinitionEntry>()
                    .mapNotNullTo(this) { published -> workspaceRegion(published, worldId, playerPosition) }
            }
            if (showInline) addAll(inlineRegions(worldId, playerPosition))
        }.sortedBy { it.distance }

        inRangeCount = regions.size
        val visible = regions.take(MAX_REGIONS)
        nearby = visible
        if (lockedId != null && visible.none { it.id == lockedId }) lockedId = null
    }

    private fun inlineRegions(worldId: String, playerPosition: Vector): List<WorkspaceRegion> =
        Query.find<Entry>().flatMap { entry ->
            entry.inlineRegionFields().mapNotNull { (field, data) ->
                inlineWorkspaceRegion(entry, field, data, worldId, playerPosition)
            }
        }.toList()

    /**
     * An inline definition as the workspace lists it, gated and staged exactly like
     * [workspaceRegion]: the published placement filters first, then the staged copy of
     * the owning entry supplies the drawn geometry.
     */
    private fun inlineWorkspaceRegion(
        entry: Entry,
        field: String,
        published: RegionDefinitionData,
        worldId: String,
        playerPosition: Vector,
    ): WorkspaceRegion? {
        if (!published.hasConstPlacement) return null
        val publishedPlacement = resolvePlacement(published) ?: return null
        if (publishedPlacement.transform.world.identifier != worldId) return null
        if (boundaryDistance(publishedPlacement, playerPosition) > RANGE + STAGED_DRIFT_SLACK) return null

        val staged = Ref(entry.id, Entry::class).stagedEntry()
            ?.inlineRegionFields()?.firstOrNull { it.first == field }?.second
            ?.takeIf { it.hasConstPlacement }
        val definition = staged ?: published
        val placement = (if (definition === published) publishedPlacement else resolvePlacement(definition))
            ?: return null
        if (placement.transform.world.identifier != worldId) return null
        val distance = boundaryDistance(placement, playerPosition)
        if (distance > RANGE) return null

        val id = "${entry.id}#$field"
        return WorkspaceRegion(
            id = id,
            entryId = entry.id,
            inlineField = field,
            name = "${entry.name} (${field})",
            color = definition.displayColor(id),
            definitionEntry = null,
            transform = placement.transform,
            shape = placement.shape,
            topOffset = placement.shape.localBounds
                .rotated(
                    placement.transform.yawDegrees,
                    placement.transform.pitchDegrees,
                    placement.transform.rollDegrees,
                )
                .maxY,
            distance = distance,
            unpublished = hasUnpublishedRegionChanges(RegionEditTarget(entry.id, field)),
            editorName = editRegistry.sessionOf(entry.id)
                ?.takeIf { it.editorId != player.uniqueId }
                ?.editorName,
        )
    }

    /**
     * The region as the workspace lists it. The workspace is an editing surface, so it
     * draws the STAGED geometry when one exists: after an in game Apply or a web edit, the
     * outline follows the saved values instead of the still published ones. The staged copy
     * is a gson parse away, so the published placement gates first, with enough slack that
     * an unpublished nudge cannot push a region out of its own listing.
     */
    private fun workspaceRegion(
        published: RegionDefinitionEntry,
        worldId: String,
        playerPosition: Vector,
    ): WorkspaceRegion? {
        if (!published.hasConstPlacement) return null
        val publishedPlacement = resolvePlacement(published) ?: return null
        if (publishedPlacement.transform.world.identifier != worldId) return null
        if (boundaryDistance(publishedPlacement, playerPosition) > RANGE + STAGED_DRIFT_SLACK) return null

        val definition = Ref(published.id, RegionDefinitionEntry::class).stagedEntry()
            ?.takeIf { it.hasConstPlacement } ?: published
        val placement = (if (definition === published) publishedPlacement else resolvePlacement(definition))
            ?: return null
        if (placement.transform.world.identifier != worldId) return null
        val distance = boundaryDistance(placement, playerPosition)
        if (distance > RANGE) return null

        return WorkspaceRegion(
            id = definition.id,
            entryId = definition.id,
            inlineField = null,
            name = definition.name,
            color = definition.displayColor(definition.id),
            definitionEntry = definition,
            transform = placement.transform,
            shape = placement.shape,
            topOffset = placement.shape.localBounds
                .rotated(
                    placement.transform.yawDegrees,
                    placement.transform.pitchDegrees,
                    placement.transform.rollDegrees,
                )
                .maxY,
            distance = distance,
            unpublished = hasUnpublishedRegionChanges(definition.id),
            editorName = editRegistry.sessionOf(definition.id)
                ?.takeIf { it.editorId != player.uniqueId }
                ?.editorName,
        )
    }

    private fun resolvePlacement(definition: RegionDefinition): ResolvedPlacement? {
        val origin = (definition.origin as? ConstVar)?.value ?: return null
        val offset = (definition.offset as? ConstVar)?.value ?: Vector.ZERO
        val yaw = (definition.yaw as? ConstVar)?.value ?: 0f
        val pitch = (definition.pitch as? ConstVar)?.value ?: 0f
        val roll = (definition.roll as? ConstVar)?.value ?: 0f
        val shape = definition.buildShapeOrNull() ?: return null
        return ResolvedPlacement(ResolvedTransform.fromOriginAndOffset(origin, offset, yaw, pitch, roll), shape)
    }

    /** Distance from [position] to the region's boundary; zero anywhere inside it. */
    private fun boundaryDistance(placement: ResolvedPlacement, position: Vector): Double =
        placement.shape.signedDistance(placement.transform.toLocal(position)).coerceAtLeast(0.0)

    /**
     * The region under the crosshair, picked by [pickTargetedRegion]: the nearest boundary
     * the view ray enters, so a big region selects from anywhere on its silhouette, and
     * regions containing the player only win through the wall the aim leaves through.
     */
    private fun updateTargeting() {
        lockedId?.let {
            targetedId = it
            return
        }
        val eye = player.eyeLocation
        val direction = eye.direction
        targetedId = pickTargetedRegion(
            nearby.map { TargetCandidate(it.id, it.transform, it.shape) },
            Vector(eye.x, eye.y, eye.z),
            Vector(direction.x, direction.y, direction.z),
            RANGE,
        )
    }

    private fun targeted(): WorkspaceRegion? = nearby.firstOrNull { it.id == targetedId }

    /**
     * Where the selection pulse is in its cycle, eased with a cosine so the motion slows
     * into both extremes. Sampled in [PULSE_STEP_TICKS] keyframes; the
     * display interpolation fills in between, so the curve stays smooth without resending
     * every tick.
     */
    private fun pulseFactor(): Float {
        val step = (pulseTicks / PULSE_STEP_TICKS) * PULSE_STEP_TICKS
        val phase = (step % PULSE_PERIOD_TICKS).toDouble() / PULSE_PERIOD_TICKS
        return (0.5 - 0.5 * cos(2.0 * PI * phase)).toFloat()
    }

    /**
     * Main thread only: keeps one outline and one name tag per nearby region. The selected
     * region's outline pulses on a short cycle, so the aim is readable without walking
     * closer.
     */
    private fun renderRegions() {
        pulseTicks++
        val pulse = pulseFactor()
        val active = nearby.associateBy { it.id }

        val staleOutlines = outlines.keys - active.keys
        for (id in staleOutlines) outlines.remove(id)?.despawn()
        val staleHolograms = holograms.keys - active.keys
        for (id in staleHolograms) holograms.remove(id)?.despawn()

        for (region in active.values) {
            val id = region.id
            // While another player's live edit preview of this region is shown to us, the
            // spectate outline and tag are the truth; rendering the published state on top
            // would draw two conflicting boundaries.
            if (editRegistry.hasLiveView(player.uniqueId, region.entryId)) {
                outlines.remove(id)?.despawn()
                holograms.remove(id)?.despawn()
                continue
            }
            val selected = id == targetedId
            val anchor = region.transform.worldOrigin
            // The region's own world, not the viewer's: the listing is up to a second stale, so
            // a player who just changed world would otherwise have its outline spawned beside
            // them in the wrong one.
            val world = resolveBukkitWorld(region.transform.world.identifier) ?: continue
            val location = Location(world, anchor.x, anchor.y, anchor.z)
            outlines.getOrPut(id) { RegionOutline(player) }.update(
                location,
                region.transform.yawDegrees,
                region.transform.pitchDegrees,
                region.shape,
                region.color,
                emphasis = if (selected) 1f + (PULSE_EMPHASIS - 1f) * pulse else 1f,
                emphasisTicks = PULSE_STEP_TICKS,
                scale = if (selected) 1f + (PULSE_SCALE - 1f) * pulse else 1f,
                rollDegrees = region.transform.rollDegrees,
            )
            val color = region.color
            val hex = String.format("#%02X%02X%02X", color.red, color.green, color.blue)
            val marker = if (selected) "<yellow>»</yellow> " else ""
            val suffix = if (selected) " <yellow>«</yellow>" else ""
            val lines =
                mutableListOf("$marker<$hex>■</$hex> <white><bold>${region.name}</bold></white> <$hex>■</$hex>$suffix")
            if (region.inlineField != null) lines += "<#A9B2C3>inline definition"
            region.editorName?.let { lines += "<yellow>✎ $it is editing" }
            if (region.unpublished) lines += "<gold>● unpublished changes"
            holograms.getOrPut(id) { EditorHologram(player) }.update(
                Location(world, anchor.x, anchor.y + region.topOffset + NAME_LIFT, anchor.z),
                lines.joinToString("\n"),
            )
        }
    }

    private fun selectorItem(): ItemComponent = object : ItemComponent {
        override fun item(player: Player): Pair<Int, IntractableItem> {
            val target = targeted()
            val item = ItemStack(Material.RECOVERY_COMPASS).apply {
                editMeta { meta ->
                    meta.name = target?.let { "<gold><bold>Edit Region</bold> <yellow>[${it.name}]" }
                        ?: "<gold><bold>Edit Region"
                    meta.loreString = """
                        |
                        |<line> <gray>Aim at a region to select it.
                        |<line> <gray>Right-click to open its editor.
                        |<line> <gray>Left-click to cycle and lock the selection,
                        |<line> <gray>press <white>F</white> to unlock.
                    """.trimMargin()
                    @Suppress("UsePropertyAccessSyntax") // Getter and setter signatures differ in nullability, so property syntax doesn't compile
                    if (lockedId != null) meta.setEnchantmentGlintOverride(true)
                }
            }
            return 0 to (item onInteract { interaction ->
                when (interaction.type) {
                    ItemInteractionType.RIGHT_CLICK, ItemInteractionType.SHIFT_RIGHT_CLICK,
                    ItemInteractionType.INVENTORY_CLICK,
                        -> openTargetEditor()

                    ItemInteractionType.LEFT_CLICK, ItemInteractionType.SHIFT_LEFT_CLICK -> cycleLock()
                    ItemInteractionType.SWAP -> {
                        lockedId = null
                        player.sendActionBar("<gray>Selection follows your aim again.".asMini())
                    }

                    else -> {}
                }
            })
        }
    }

    private fun cycleLock() {
        val candidates = nearby
        if (candidates.isEmpty()) {
            refuse("<red>No regions nearby to select.")
            return
        }
        val currentIndex = candidates.indexOfFirst { it.id == (lockedId ?: targetedId) }
        val next = candidates[(currentIndex + 1) % candidates.size]
        lockedId = next.id
        targetedId = next.id
        player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.4f, 1.3f)
        player.sendActionBar("<gold>Selected <white>${next.name}</white>. <gray>Right-click to edit it.".asMini())
    }

    private fun openTargetEditor() {
        val target = targeted() ?: run {
            refuse("<red>Aim at a region first, or left-click to cycle.")
            return
        }
        val session = editRegistry.sessionOf(target.entryId)
        if (session != null && session.editorId != player.uniqueId) {
            refuse("<red>${session.editorName} is editing ${target.name} right now.")
            return
        }
        val (editorContext, mode) = when {
            target.inlineField != null -> {
                // Rechecked against the entry as it stands now. The listing is up to a second
                // stale, and a failed push tears down the whole content interaction, which would
                // drop the player out of the workspace instead of refusing.
                if (!inlineStillEditable(target.entryId, target.inlineField)) {
                    refuse("<red>${target.name} no longer holds a region that can be edited here.")
                    return
                }
                val context = inlineRegionEditorContext(target.entryId, target.inlineField)
                context to InlineRegionContentMode(context, player)
            }

            target.definitionEntry != null -> {
                // Resolved again for the same reason as the inline branch above: the listing is up
                // to a second stale, and pushing an editor for an entry that a publish deleted
                // fails its setup, which ends the whole interaction instead of refusing here.
                val definition = Ref(target.entryId, RegionDefinitionEntry::class).get() ?: run {
                    refuse("<red>${target.name} no longer exists.")
                    return
                }
                val context = regionEditorContext(definition)
                val editor = regionEditorMode(definition, context, player) ?: run {
                    refuse("<red>${target.name} has no in-game editor.")
                    return
                }
                context to editor
            }

            else -> return
        }
        player.playSound(player.location, Sound.UI_LOOM_SELECT_PATTERN, 0.6f, 1.2f)
        ContentModeTrigger(editorContext, mode).triggerFor(player, context())
    }

    /** Whether [field] on [entryId] still holds an inline region with a usable shape. */
    private fun inlineStillEditable(entryId: String, field: String): Boolean {
        val ref = Ref(entryId, Entry::class)
        val entry = ref.stagedEntry() ?: ref.get() ?: return false
        val data = entry.inlineRegionFields().firstOrNull { it.first == field }?.second ?: return false
        return data.buildShapeOrNull() != null
    }

    private fun teleportToTarget() {
        val target = targeted() ?: run {
            refuse("<red>Aim at a region first, or left-click the compass to cycle.")
            return
        }
        val anchor = target.transform.worldOrigin
        val world = resolveBukkitWorld(target.transform.world.identifier) ?: run {
            refuse("<red>That region's world is not loaded.")
            return
        }
        returnLocation = player.location
        player.teleport(
            Location(
                world,
                anchor.x,
                anchor.y,
                anchor.z,
                player.location.yaw,
                player.location.pitch
            )
        )
        player.playSound(player.location, Sound.ENTITY_ENDERMAN_TELEPORT, 0.7f, 1f)
        player.sendActionBar("<gold>Teleported to <white>${target.name}</white>. <gray>Left-click to go back.".asMini())
    }

    /**
     * Teleports to the boundary of the targeted region the player is looking at. A ray that
     * never crosses the boundary falls back to the nearest point on it.
     */
    private fun teleportToTargetBorder() {
        val target = targeted() ?: run {
            refuse("<red>Aim at a region first, or left-click the compass to cycle.")
            return
        }

        val world = resolveBukkitWorld(target.transform.world.identifier) ?: run {
            refuse("<red>That region's world is not loaded.")
            return
        }
        val result = borderTeleport(world, target.transform, target.shape, player.eyeLocation) ?: run {
            refuse("<red>Could not find a border to teleport to.")
            return
        }

        returnLocation = player.location
        player.teleport(result.destination)
        player.playSound(result.destination, Sound.ENTITY_ENDERMAN_TELEPORT, 0.7f, 1.2f)
        val hint = if (result.usedFallback) " <gray>Nothing in your aim, so this is the nearest edge." else ""
        player.sendActionBar(
            "<gold>Teleported to the border of <white>${target.name}</white>.$hint <gray>Left-click to go back.".asMini(),
        )
    }

    private var returnLocation: Location? = null

    private fun teleportBack() {
        val back = returnLocation ?: run {
            refuse("<red>No previous spot to return to yet.")
            return
        }
        returnLocation = player.location
        player.teleport(back)
        player.playSound(back, Sound.ENTITY_ENDERMAN_TELEPORT, 0.7f, 0.8f)
    }

    private fun refuse(message: String) {
        player.sendActionBar(message.asMini())
        player.playSound(player.location, Sound.ENTITY_VILLAGER_NO, 0.6f, 1f)
    }

    /**
     * A workspace hotbar toggle. The glint mirrors the shown state, and flipping it forces
     * the next tick's refresh so the listing reacts immediately.
     */
    private fun toggleItem(
        slot: Int,
        material: Material,
        name: String,
        description: String,
        shown: () -> Boolean,
        toggle: (Boolean) -> Unit,
    ): ItemComponent = object : ItemComponent {
        override fun item(player: Player): Pair<Int, IntractableItem> {
            val state = shown()
            val item = ItemStack(material).apply {
                editMeta { meta ->
                    meta.name = "<gold><bold>$name</bold> ${if (state) "<green>[shown]" else "<gray>[hidden]"}"
                    meta.loreString = """
                        |
                        |<line> <gray>Click to ${if (state) "hide" else "show"} $description.
                    """.trimMargin()
                    @Suppress("UsePropertyAccessSyntax") // Getter and setter signatures differ in nullability, so property syntax doesn't compile
                    if (state) meta.setEnchantmentGlintOverride(true)
                }
            }
            return slot to (item onInteract { interaction ->
                if (!interaction.type.isActivation) return@onInteract
                val shownNow = !shown()
                toggle(shownNow)
                refreshTicks = REFRESH_INTERVAL_TICKS
                player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.4f, if (shownNow) 1.4f else 0.9f)
                player.sendActionBar(
                    "<gold>$name <gray>are now ${if (shownNow) "<green>shown</green>" else "hidden"}.".asMini(),
                )
            })
        }
    }

    private data class ResolvedPlacement(val transform: ResolvedTransform, val shape: Shape)

    private data class WorkspaceRegion(
        val id: String,
        val entryId: String,
        val inlineField: String?,
        val name: String,
        val color: Color,
        val definitionEntry: RegionDefinitionEntry?,
        val transform: ResolvedTransform,
        val shape: Shape,
        val topOffset: Double,
        val distance: Double,
        val unpublished: Boolean,
        val editorName: String?,
    )

    companion object {
        private const val RANGE = 64.0
        private const val STAGED_DRIFT_SLACK = 64.0
        private const val MAX_REGIONS = 6
        private const val REFRESH_INTERVAL_TICKS = 20
        private const val NAME_LIFT = 1.0
        private const val PULSE_PERIOD_TICKS = 16L
        private const val PULSE_STEP_TICKS = 2
        private const val PULSE_EMPHASIS = 2.2f
        private const val PULSE_SCALE = 1.08f
    }
}
