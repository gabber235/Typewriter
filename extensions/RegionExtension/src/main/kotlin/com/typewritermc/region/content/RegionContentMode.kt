package com.typewritermc.region.content

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.content.*
import com.typewritermc.engine.paper.content.components.*
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.writeFieldValue
import com.typewritermc.engine.paper.entry.stagedEntry
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionDefinition
import com.typewritermc.region.data.buildShapeOrNull
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.data.displayColor
import com.typewritermc.region.data.tiltDegrees
import com.typewritermc.region.shape.LocalBounds
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.nearestBoundaryPoint
import kotlinx.coroutines.Dispatchers
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import net.kyori.adventure.bossbar.BossBar
import org.bukkit.*
import org.bukkit.Sound
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.koin.java.KoinJavaComponent
import java.lang.reflect.Type
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.*

/** A block a player marked with the region wand. */
data class CapturedBlock(val world: World, val x: Int, val y: Int, val z: Int) {
    val center: Vector get() = Vector(x + 0.5, y + 0.5, z + 0.5)
}

/**
 * The region the working model currently describes. The preview renders it with the same
 * [Shape] math the runtime uses.
 */
data class PendingRegion(val transform: ResolvedTransform, val shape: Shape)

/**
 * The block aligned box spanned by two marked blocks. The upper bounds are exclusive so
 * both blocks are fully covered.
 */
data class BlockBox(
    val minX: Double, val minY: Double, val minZ: Double,
    val maxX: Double, val maxY: Double, val maxZ: Double,
) {
    val center: Vector get() = Vector((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
    val halfX: Double get() = (maxX - minX) / 2
    val halfY: Double get() = (maxY - minY) / 2
    val halfZ: Double get() = (maxZ - minZ) / 2

    companion object {
        fun spanning(a: CapturedBlock, b: CapturedBlock): BlockBox = BlockBox(
            minX = min(a.x, b.x).toDouble(),
            minY = min(a.y, b.y).toDouble(),
            minZ = min(a.z, b.z).toDouble(),
            maxX = max(a.x, b.x) + 1.0,
            maxY = max(a.y, b.y) + 1.0,
            maxZ = max(a.z, b.z) + 1.0,
        )
    }
}

/**
 * Base for the in game region capture editors. Everything edits one working model: wand
 * captures derive placement and size into it the moment they complete, the transform tools
 * nudge it, and the preview always renders it. Nothing touches the entry until the player
 * clicks Apply; leaving discards the session.
 *
 * The shape renders as glowing display entity edge lines in the region's color, with dust
 * on the surface between them, so the silhouette reads through terrain. A text display
 * above the region reads out the live placement, size and unsaved change count.
 *
 * Every change lands in a tool aware undo history: the drop key undoes the held tool's
 * last change (sneaking redoes it), the arrow item walks the whole session, and
 * sneak clicking the arrow undoes or redoes everything.
 *
 * The move tool can pick the region up and carry it on the crosshair. The resize tool aims
 * at faces: click to step the face, or grab it and drag it along its normal by looking.
 */
abstract class RegionContentMode(context: ContentContext, player: Player) : ContentMode(context, player) {
    private val editRegistry: RegionEditRegistry by KoinJavaComponent.inject(RegionEditRegistry::class.java)
    private var entryRef: Ref<Entry>? = null
    private var target: RegionEditTarget? = null

    private var stagedEntryResolved = false
    private var stagedEntry: Entry? = null

    private var placementSeeded = false
    private var entryHadPlacement = false

    @Volatile
    private var disposed = false

    @Volatile
    private var workingOrigin: Position? = null

    @Volatile
    private var workingOffset: Vector = Vector.ZERO

    @Volatile
    private var workingYaw: Float? = null

    @Volatile
    private var workingPitch: Float? = null

    @Volatile
    private var workingRoll: Float? = null

    @Volatile
    private var resizeShift: Vector = Vector.ZERO

    private val stagedWrites = ConcurrentHashMap<String, StagedWrite>()
    private val history = EditHistory()
    private val hologram = EditorHologram(player)
    private val outline = RegionOutline(player)
    private val guide = GuideDisplay(player)
    private val ghostMarker = GuideDisplay(player)
    private var scrollListener: ScrollListener? = null
    private var displacementListener: DisplacementListener? = null
    private var spectatorListener: SpectatorInputListener? = null

    @Volatile
    private var spectatorLock: SpectatorLockState? = null

    private var restoreEpoch = 0
    private var renderedRestoreEpoch = 0

    @Volatile
    private var moveAxisLock = AxisLock.Auto

    @Volatile
    private var autoMoveMemory: Vector? = null

    @Volatile
    private var rotatePitchMode = false

    @Volatile
    private var carrying = false

    @Volatile
    private var carryDistance = 8.0
    private var carryBaseState: Map<String, Any?>? = null

    @Volatile
    private var targetedFace: RegionFace? = null

    @Volatile
    private var pinnedFaceId: String? = null

    @Volatile
    private var grabbedFace: RegionFace? = null
    private var dragBaseState: Map<String, Any?>? = null
    private var dragTransform: ResolvedTransform? = null
    private var dragLocalEye: Vector? = null
    private var lastDragDelta = 0.0

    private var returnLocation: Location? = null

    private var session: RegionEditSession? = null
    private var awaitingPublish = false

    private var rotateSlot = -1
    private var resizeSlot = -1

    final override suspend fun setup(): Result<Unit> {
        val entryId = context.entryId
            ?: return failure("No entryId found for ${this::class.simpleName}. This is a bug. Please report it.")
        val fieldPath = context.fieldPath
            ?: return failure("No fieldPath found for ${this::class.simpleName}. This is a bug. Please report it.")
        val ref = Ref(entryId, Entry::class)
        val entry = ref.stagedEntry() ?: ref.get()
            ?: return failure("Could not find the entry $entryId to edit.")
        entryRef = ref
        stagedEntry = entry
        stagedEntryResolved = true
        target = regionEditTarget(entry, fieldPath)
            ?: return failure("$fieldPath on $entryId holds no region to edit. This is a bug. Please report it.")

        rotateSlot = if (supportsRotation()) ROTATE_SLOT else -1
        resizeSlot = if (faceSpec() != null) RESIZE_SLOT else -1

        bossBar {
            title = bossBarTitle()
            color = when {
                carrying || grabbedFace != null || modeGestureActive() -> BossBar.Color.BLUE
                canApply() -> BossBar.Color.GREEN
                else -> BossBar.Color.YELLOW
            }
        }
        // No double shift exit: sneaking is a core editor input (large steps, fine scrolls,
        // border teleport), so two quick shifts must never throw the player out of the mode.
        exit { canApply() }
        +wandComponent()
        +moveTool()
        if (rotateSlot >= 0) +rotateTool()
        if (resizeSlot >= 0) +resizeTool()
        +TeleportToolComponent(TELEPORT_SLOT, ::teleportToRegion, ::teleportToBorder, ::teleportBack, ::undoOrRedoHeldTool)
        +UndoItemComponent(
            { history.undoCount },
            { history.redoCount },
            { all -> if (all) undoEverything() else undoLastChange() },
            { all -> if (all) redoEverything() else redoLastChange() },
        )
        +ApplyItemComponent(::canApply, { stagedWrites.size }, ::applyIfReady)

        return ok(Unit)
    }

    override suspend fun initialize() {
        // The engine initializes the mode underneath again whenever a mode pushed on top of it is
        // popped, so the flag has to be armed again here. Left set, the returning editor keeps
        // its tools and its boss bar and renders nothing at all.
        disposed = false
        val entryId = entryRef?.id
        if (entryId != null) {
            session = editRegistry.tryStartEditing(player.uniqueId, player.name, entryId)
            if (session == null) {
                val holder = editRegistry.sessionOf(entryId)?.editorName ?: "Another player"
                Dispatchers.Sync.switchContext { refuse("<red>$holder is editing this region right now.") }
                ContentPopTrigger.triggerFor(player, context())
                return
            }
            awaitingPublish = target?.let(::hasUnpublishedRegionChanges) == true
        }
        editRegistry.enterMode(player.uniqueId, RegionModeKind.Editor)
        seedWorkingPlacement()
        // A mode pushed on top of this one disposed it, which discarded the staged writes, but the
        // working model and the whole edit history survived in memory and are about to be drawn
        // again. Staging them back matches what the builder sees; leaving it would show an edited
        // region that Apply refuses to save and that exiting throws away without asking.
        restageWorkingFields()
        val listener = ScrollListener(player, ::onScroll)
        scrollListener = listener
        plugin.registerEvents(listener)
        val inputListener = SpectatorInputListener(
            player,
            anchor = { spectatorLock?.anchor },
            onLockChord = ::toggleSpectatorLock,
            onSecondaryChord = ::markSpectatorSecondary,
            onKey = ::onSpectatorKey,
            onForcedRelease = ::releaseSpectatorLock,
        )
        spectatorListener = inputListener
        plugin.registerEvents(inputListener)
        val displacementListener = DisplacementListener(
            player,
            anchor = { spectatorLock?.anchor },
            onDisplaced = ::releaseGestures,
        )
        this.displacementListener = displacementListener
        plugin.registerEvents(displacementListener)
        super.initialize()
    }

    override suspend fun dispose() {
        disposed = true
        carrying = false
        carryBaseState = null
        grabbedFace = null
        dragBaseState = null
        dragTransform = null
        dragLocalEye = null
        scrollListener?.unregister()
        scrollListener = null
        spectatorListener?.unregister()
        spectatorListener = null
        displacementListener?.unregister()
        displacementListener = null
        try {
            Dispatchers.Sync.switchContext {
                releaseSpectatorLock(quiet = true)
                hologram.despawn()
                outline.despawn()
                guide.despawn()
                ghostMarker.despawn()
            }
        } finally {
            // The lock goes back whatever the despawns did. Nothing else ever reclaims it: there is
            // no quit handler on the registry, so a throw on the way out would leave the region
            // unopenable by anyone until the server restarts.
            session?.let { editRegistry.stopEditing(player.uniqueId, it.entryId) }
            session = null
            editRegistry.exitMode(player.uniqueId, RegionModeKind.Editor)
        }
        if (stagedWrites.isNotEmpty()) {
            stagedWrites.clear()
            player.sendActionBar("<gray>Discarded the unsaved region changes.".asMini())
        }
        super.dispose()
    }

    /** Boss bar text for the current capture state, shown while holding the wand. */
    protected abstract fun instruction(): String

    protected abstract fun wandComponent(): ItemComponent

    /** Whether the rotate tool makes sense for this shape. A sphere has nothing to rotate. */
    protected open fun supportsRotation(): Boolean = true

    /** The faces the resize tool can aim at, or `null` when the shape has no size fields. */
    protected open fun faceSpec(): FaceSpec? = null

    /** Called every tick to render markers for the captured points. */
    protected open fun renderMarkers(eye: Location) {}

    /** Called every tick on the main thread, for mode owned displays beyond the shared ones. */
    protected open fun updateModeOverlays() {}

    /**
     * Scroll input while the wand is held. Return `true` to consume the notches. Runs
     * before the sneak gate, so a wand gesture can consume plain scrolls the way the
     * region carry does.
     */
    protected open fun onWandScroll(steps: Int): Boolean = false

    /** Whether a mode owned gesture, like the polygon's point carry, is in progress. */
    protected open fun modeGestureActive(): Boolean = false

    /** Puts a mode owned gesture back without keeping it. */
    protected open fun cancelModeGesture() {}

    /** Confirms a mode owned gesture, recording it, like placing a carried region. */
    protected open fun finishModeGesture() {}

    /** The refusal shown while a mode owned gesture blocks other tools. */
    protected open fun modeGestureRefusal(): String = "<red>Finish the current gesture first."

    /** The spectate label while a mode owned gesture runs, like "is moving a point". */
    protected open fun modeGestureActivity(): String? = null

    /** Called every tick on the main thread before the outline update, for mode gestures. */
    protected open fun tickModeGesture() {}

    /** The boss bar instruction while the player is a free flying spectator. */
    protected open fun spectatorHint(): String =
        "fly to the spot and press <white>jump + sneak</white> to lock in"

    /** The tool the spectator drives: the held slot froze when the hotbar keys stopped reaching the server. */
    private fun spectatorToolName(): String = when (player.inventory.heldItemSlot) {
        WAND_SLOT -> "Wand"
        MOVE_SLOT -> "Move"
        rotateSlot -> "Rotate"
        resizeSlot -> "Resize"
        else -> "Capture"
    }

    /** The boss bar instruction while the spectator lock drives the wand. */
    protected open fun lockedWandHint(): String =
        "<white>WASD</white>, <white>space</white> and <white>shift</white> move the cube, " +
                "<white>ctrl</white> marks it, <white>jump + sneak</white> releases"

    private fun lockedSpectatorHint(): String = when (player.inventory.heldItemSlot) {
        WAND_SLOT -> lockedWandHint()

        MOVE_SLOT ->
            "<white>WASD</white>, <white>space</white> and <white>shift</white> nudge the region $MOVE_STEP, " +
                    "<white>jump + sneak</white> releases"

        rotateSlot ->
            "<white>A/D</white> turn the yaw, <white>W/S</white> tilt it away or toward you $ROTATE_STEP°, " +
                    "<white>jump + sneak</white> releases"

        resizeSlot ->
            if (pinnedFaceId != null) {
                "<white>${targetedFace?.label ?: "face"}</white> pinned: <white>W/S</white> keep driving it, " +
                        "<white>space</white> releases it, <white>jump + sneak</white> unlocks"
            } else {
                "aim at a face: <white>W</white> pushes it away, <white>S</white> pulls it toward you, " +
                        "<white>space</white> pins the face, <white>jump + sneak</white> releases"
            }

        else -> "no ghost controls on this slot, <white>jump + sneak</white> releases"
    }

    /**
     * The entry as the editor should see it: the staged copy when the page has unpublished
     * edits, so reopening the editor after an Apply shows the applied values instead of the
     * still published ones. Falls back to the published runtime entry. Resolved once, since a
     * session's own Apply closes the mode and nothing else changes this entry mid session.
     */
    @PublishedApi
    internal fun editedEntryRaw(): Entry? {
        if (!stagedEntryResolved) {
            val ref = entryRef
            stagedEntry = ref?.stagedEntry() ?: ref?.get()
            stagedEntryResolved = true
        }
        return stagedEntry
    }

    /**
     * The region being edited: the entry itself when it is a definition entry, or the inline
     * definition the entry holds.
     */
    @PublishedApi
    internal fun definition(): RegionDefinition? = editedEntryRaw()?.let { target?.definitionOf(it) }

    /**
     * The shape the entry currently holds, when it is the shape this editor edits. Reading
     * the size through the shape rather than the entry's own fields lets one editor serve
     * both a definition entry and an inline definition: the field names are the same,
     * only the path to them differs.
     */
    protected inline fun <reified S : Shape> editedShape(): S? = definition()?.buildShapeOrNull() as? S

    private fun stageWrite(path: String, value: Any, type: Type) {
        stagedWrites[path] = StagedWrite(value, type)
    }

    private fun placementPath(): String = target?.placementPath ?: ""

    private fun shapePath(): String = target?.shapePath ?: ""

    /**
     * The placement the entry's origin field would receive: the working origin plus the
     * accumulated single sided resize shift.
     */
    private fun effectiveOrigin(): Position? {
        val origin = workingOrigin ?: return null
        val shift = resizeShift
        if (shift == Vector.ZERO) return origin
        return Position(
            origin.world,
            origin.x + shift.x,
            origin.y + shift.y,
            origin.z + shift.z,
            origin.yaw,
            origin.pitch
        )
    }

    /**
     * The placement fields this mode may write. A field bound to a variable on the panel has
     * no working value, and staging a raw one in its place replaces the binding with a
     * constant that the builder cannot restore from in game.
     */
    protected fun placementWritable(rotation: Boolean = false): Boolean {
        if (workingOrigin == null) {
            notifyVariableBound("origin")
            return false
        }
        if (rotation && (workingYaw == null || workingPitch == null)) {
            notifyVariableBound("rotation")
            return false
        }
        return true
    }

    protected fun updateWorkingOrigin(position: Position) {
        workingOrigin = position
        restageWorkingFields()
    }

    /**
     * An origin at [x], [y], [z] in [world], facing nowhere.
     *
     * A capture describes where the region sits in the world, and the marks already carry its
     * whole orientation. A region with `Rotate With Origin` set adds the origin's own facing on
     * top of that, so a facing left over from wherever the origin was captured before would turn
     * the published region away from the blocks that were just marked. Nothing else reads a
     * constant origin's facing, so clearing it here costs nothing.
     */
    protected fun originMovedTo(world: World, x: Double, y: Double, z: Double): Position =
        Position(world, x, y, z, 0f, 0f)

    protected fun updateWorkingYaw(yaw: Float) {
        workingYaw = yaw
        restageWorkingFields()
    }

    /** Rotates the working pitch and stages it. */
    protected fun updateWorkingPitch(pitch: Float) {
        workingPitch = pitch
        restageWorkingFields()
    }

    /** Rotates the working roll and stages it. */
    protected fun updateWorkingRoll(roll: Float) {
        workingRoll = roll
        restageWorkingFields()
    }

    /**
     * Stages an axis aligned rotation when the working model is rotated. Box based
     * captures call it, since their marks describe a world aligned shape. Variable bound
     * rotations are left alone.
     */
    protected fun resetWorkingRotation() {
        workingYaw?.takeIf { it != 0f }?.let { updateWorkingYaw(0f) }
        workingPitch?.takeIf { it != 0f }?.let { updateWorkingPitch(0f) }
        workingRoll?.takeIf { it != 0f }?.let { updateWorkingRoll(0f) }
    }

    /**
     * Accumulates a placement shift along a local frame direction, rotated by the working
     * yaw and pitch. Single sided face moves use this to keep the opposite face in place.
     * The shift lives next to the size values instead of in the working origin, so the
     * resize tool and the move tool never write the same undo history key and tool scoped
     * undo cannot conflict between them. Returns `false` when the origin is variable bound.
     */
    protected fun shiftResizeAnchor(localDirection: Vector, distance: Double): Boolean {
        val origin = workingOrigin ?: return false
        val rotated = ResolvedTransform(origin.world, Vector.ZERO, workingYaw ?: 0f, workingPitch ?: 0f, workingRoll ?: 0f)
            .rotateLocalToWorld(localDirection)
        resizeShift = Vector(
            (resizeShift.x + rotated.x * distance).round(3),
            (resizeShift.y + rotated.y * distance).round(3),
            (resizeShift.z + rotated.z * distance).round(3),
        )
        restageWorkingFields()
        return true
    }

    /**
     * Folds the resize shift away for a fresh placement. Wand captures call this before
     * setting the origin, so the captured anchor is exactly where the marks put it.
     */
    protected fun resetResizeShift() {
        resizeShift = Vector.ZERO
    }

    /** Extra state a subclass wants captured in undo history, like marked points. */
    protected open fun collectState(state: MutableMap<String, Any?>) {}

    /** Restores one subclass state value captured by [collectState]. */
    protected open fun restoreStateValue(key: String, value: Any?) {}

    /**
     * Stages the subclass's size fields from the working model again after a history restore,
     * through [restageField]. Staged writes are derived state: they follow the working
     * values instead of living in the undo history themselves.
     */
    protected open fun restageSizeFields() {}

    /**
     * Stages [working] for a placement [field], or drops the staged write when it matches
     * what the entry already holds, so a fully undone editor reads as having nothing to save.
     */
    protected fun restageField(field: String, working: Any?, entryValue: Any?, type: Type? = null) {
        restage(placementPath() + field, working, entryValue, type)
    }

    /** [restageField] for one of the shape's own fields. */
    protected fun restageShapeField(field: String, working: Any?, entryValue: Any?, type: Type? = null) {
        restage(shapePath() + field, working, entryValue, type)
    }

    private fun restage(path: String, working: Any?, entryValue: Any?, type: Type?) {
        if (working == null) return
        if (working == entryValue) {
            stagedWrites.remove(path)
            return
        }
        stageWrite(path, working, type ?: working.javaClass)
    }

    private fun editorState(): Map<String, Any?> {
        val state = mutableMapOf(
            KEY_ORIGIN to workingOrigin,
            KEY_OFFSET to workingOffset,
            KEY_YAW to workingYaw,
            KEY_PITCH to workingPitch,
            KEY_ROLL to workingRoll,
            KEY_RESIZE_SHIFT to resizeShift,
        )
        collectState(state)
        return state
    }

    private fun applyValues(values: Map<String, Any?>) {
        for ((key, value) in values) {
            when (key) {
                KEY_ORIGIN -> workingOrigin = value as? Position
                KEY_OFFSET -> workingOffset = value as? Vector ?: Vector.ZERO
                KEY_YAW -> workingYaw = value as? Float
                KEY_PITCH -> workingPitch = value as? Float
                KEY_ROLL -> workingRoll = value as? Float
                KEY_RESIZE_SHIFT -> resizeShift = value as? Vector ?: Vector.ZERO
                else -> restoreStateValue(key, value)
            }
        }
        restageWorkingFields()
    }

    private fun restageWorkingFields() {
        val definition = definition() ?: return
        restageField(ORIGIN_FIELD, effectiveOrigin(), (definition.origin as? ConstVar)?.value, Position::class.java)
        restageField("yaw", workingYaw, (definition.yaw as? ConstVar)?.value)
        restageField("pitch", workingPitch, (definition.pitch as? ConstVar)?.value)
        restageField("roll", workingRoll, (definition.roll as? ConstVar)?.value)
        restageSizeFields()
    }

    /**
     * Applies a history restore. The restore is a discrete jump, so the next outline
     * update snaps into place instead of interpolating across it. The rotate readout
     * follows the axis the restore touched, so undoing a pitch change does not read as
     * nothing happening while the boss bar is still showing yaw.
     */
    private fun restoreValues(values: Map<String, Any?>) {
        applyValues(values)
        restoreEpoch++
        when {
            values.containsKey(KEY_ROLL) -> rotatePitchMode = true
            values.containsKey(KEY_PITCH) && !values.containsKey(KEY_YAW) -> rotatePitchMode = true
            values.containsKey(KEY_YAW) -> rotatePitchMode = false
        }
    }

    /** A short readout of the fields a restore moved, for the undo and redo feedback. */
    private fun describeRestore(values: Map<String, Any?>): String? {
        val parts = mutableListOf<String>()
        (values[KEY_ORIGIN] as? Position)?.let {
            parts += "origin ${it.x.round(2)}, ${it.y.round(2)}, ${it.z.round(2)}"
        }
        (values[KEY_YAW] as? Float)?.let { parts += "yaw ${it.toDouble().round(1)}°" }
        (values[KEY_PITCH] as? Float)?.let { parts += "pitch ${it.toDouble().round(1)}°" }
        (values[KEY_ROLL] as? Float)?.let { parts += "roll ${it.toDouble().round(1)}°" }
        for ((key, value) in values) {
            if (!key.startsWith("size.") || key == KEY_RESIZE_SHIFT) continue
            val shown = (value as? Double)?.round(2) ?: value ?: continue
            parts += "${key.removePrefix("size.")} $shown"
        }
        return parts.takeIf { it.isNotEmpty() }?.joinToString(", ")
    }

    /**
     * Runs [change] and records the state difference under [tool] when it reports
     * something actually changed. Bursts with the same [label] within [coalesceMillis]
     * collapse into one undo step.
     *
     * While a face is grabbed, and for every tool but rotate while the region is carried,
     * the gesture is refused and `false` comes back: a change recorded in the middle of a
     * gesture would capture a base state the gesture's own entry also spans, and undoing
     * one would silently revert the other. Rotation is safe mid carry because the carry
     * entry only ever holds the origin. A mode owned gesture refuses every tool, rotation
     * included: the base cannot know which keys the gesture's entry will span, so no tool
     * is provably safe to interleave.
     */
    protected fun recorded(tool: String, label: String, coalesceMillis: Long = 0, change: () -> Boolean): Boolean {
        if (grabbedFace != null) {
            refuse("<red>Keep or put back the grabbed face first.")
            return false
        }
        if (carrying && tool != EditTool.ROTATE) {
            refuse("<red>Place the region down first.")
            return false
        }
        if (modeGestureActive()) {
            refuse(modeGestureRefusal())
            return false
        }
        val before = editorState()
        if (!change()) return true
        history.record(tool, label, before, editorState(), coalesceMillis)
        return true
    }

    /**
     * The drop key on a tool: undoes the held tool's last gesture, or redoes the last
     * undone one while sneaking. Puts a carried region or a grabbed face back first.
     */
    protected fun undoOrRedoHeldTool() {
        if (modeGestureActive()) {
            cancelModeGesture()
            return
        }
        if (carrying) {
            cancelCarry()
            return
        }
        if (grabbedFace != null) {
            cancelFaceDrag()
            return
        }
        val redo = player.isSneaking
        val tool = toolForSlot(player.inventory.heldItemSlot) ?: run {
            // A non editing slot like the teleport shard: its drop key owns no history, so it
            // stays quiet instead of reaching for a global undo the way the arrow item does.
            nothingLeftForTool(null, redo)
            return
        }
        applyToolResult(tool, if (redo) history.redoTool(tool) else history.undoTool(tool), redo)
    }

    /** Restores a moved entry's values with feedback, or explains the quiet refusal. */
    private fun applyToolResult(tool: String, result: ToolHistoryResult, redo: Boolean) {
        when (result) {
            is ToolHistoryResult.Restored -> {
                restoreValues(result.change.values)
                undoFeedback(
                    if (redo) "Redid" else "Undid",
                    result.change.label,
                    result.change.values,
                    pitch = if (redo) 1.3f else 0.7f,
                )
            }

            is ToolHistoryResult.Entangled -> entangledHint(result.blockingTool, redo)
            ToolHistoryResult.NothingLeft -> nothingLeftForTool(tool, redo)
        }
    }

    /**
     * The held tool has nothing of its own left to undo or redo. An empty stack is a
     * normal resting state, not an error, so this is deliberately quiet: a soft hint and
     * no sound, never the page turn that reads as success or the refusal buzz of a failure.
     */
    private fun nothingLeftForTool(tool: String?, redo: Boolean) {
        val what = tool?.let { "the ${it.replaceFirstChar(Char::uppercase)} tool" } ?: "this tool"
        player.sendActionBar("<dark_gray>Nothing left to ${if (redo) "redo" else "undo"} for $what.".asMini())
    }

    /**
     * A newer change by another tool overlaps the keys this undo or redo would move, so
     * moving it out of order would corrupt that change. The history stays intact and the
     * arrow can unwind it in order. A soft hint, no refusal buzz: nothing went wrong.
     */
    private fun entangledHint(blockingTool: String, redo: Boolean) {
        val blocker = blockingTool.replaceFirstChar(Char::uppercase)
        player.sendActionBar(
            "<gray>Later $blocker changes overlap this. <white>Use the arrow</white> to ${if (redo) "redo" else "undo"} in order.".asMini(),
        )
    }

    /** The arrow item's global undo or redo with an empty stack. Quiet, like [nothingLeftForTool]. */
    private fun nothingLeft(redo: Boolean) {
        player.sendActionBar("<dark_gray>Nothing left to ${if (redo) "redo" else "undo"}.".asMini())
    }

    private fun toolForSlot(slot: Int): String? = when (slot) {
        WAND_SLOT -> EditTool.WAND
        MOVE_SLOT -> EditTool.MOVE
        rotateSlot -> EditTool.ROTATE
        resizeSlot -> EditTool.RESIZE
        else -> null
    }

    private fun undoLastChange() {
        if (modeGestureActive()) {
            cancelModeGesture()
            return
        }
        if (carrying) {
            cancelCarry()
            return
        }
        if (grabbedFace != null) {
            cancelFaceDrag()
            return
        }
        val restored = history.undoLast() ?: run {
            nothingLeft(redo = false)
            return
        }
        restoreValues(restored.values)
        undoFeedback("Undid", restored.label, restored.values)
    }

    private fun redoLastChange() {
        // The gesture is cancelled, not committed, the same way undo does it. Committing records the
        // gesture, and recording clears the redo stack, so the redo the builder asked for would be
        // gone by the time it was looked up and they would be told there was nothing to redo.
        if (modeGestureActive()) cancelModeGesture()
        if (carrying) cancelCarry()
        if (grabbedFace != null) cancelFaceDrag()
        val restored = history.redoLast() ?: run {
            nothingLeft(redo = true)
            return
        }
        restoreValues(restored.values)
        undoFeedback("Redid", restored.label, restored.values, pitch = 1.3f)
    }

    private fun undoEverything() {
        if (modeGestureActive()) cancelModeGesture()
        if (carrying) cancelCarry()
        if (grabbedFace != null) cancelFaceDrag()
        val restored = history.undoAll() ?: run {
            nothingLeft(redo = false)
            return
        }
        restoreValues(restored.values)
        undoFeedback("Undid", restored.label, emptyMap())
    }

    private fun redoEverything() {
        if (modeGestureActive()) cancelModeGesture()
        if (carrying) cancelCarry()
        if (grabbedFace != null) cancelFaceDrag()
        val restored = history.redoAll() ?: run {
            nothingLeft(redo = true)
            return
        }
        restoreValues(restored.values)
        undoFeedback("Redid", restored.label, emptyMap(), pitch = 1.3f)
    }

    private fun undoFeedback(verb: String, label: String, values: Map<String, Any?>, pitch: Float = 0.7f) {
        val detail = describeRestore(values)?.let { " <gray>→ <white>$it</white>" } ?: ""
        player.playSound(player.location, Sound.ITEM_BOOK_PAGE_TURN, 0.7f, pitch)
        player.sendActionBar(
            "<gray>$verb <white>$label</white>$detail <gray>(${history.undoCount} undo, ${history.redoCount} redo left).".asMini(),
        )
    }

    private fun canApply(): Boolean =
        carrying || grabbedFace != null || modeGestureActive() || stagedWrites.isNotEmpty()

    private fun applyIfReady() {
        if (modeGestureActive()) finishModeGesture()
        if (carrying) placeCarry()
        if (grabbedFace != null) confirmFaceDrag()
        if (stagedWrites.isEmpty()) {
            refuse("<red>Nothing to apply yet. Capture the region or nudge it with the tools first.")
            return
        }

        val ref = entryRef
        if (ref == null) {
            refuse("<red>This region is not attached to an entry, so there is nothing to save it to.")
            return
        }

        val count = stagedWrites.size
        // The writes are kept when one fails, so a builder can fix the cause (usually the entry
        // moved page or was deleted on the web) and apply again without redoing the edit.
        val failure = stagedWrites.entries.firstNotNullOfOrNull { (path, write) ->
            ref.writeFieldValue(path, write.value, write.type).exceptionOrNull()?.let { path to it }
        }
        if (failure != null) {
            val (path, cause) = failure
            refuse("<red>Could not save <white>$path</white>: ${cause.message ?: "the entry could not be written"}")
            return
        }

        stagedWrites.clear()
        stagedEntryResolved = false

        player.playSound(player.location, Sound.ENTITY_PLAYER_LEVELUP, 0.5f, 1.6f)
        player.sendActionBar(
            "<green>Saved <white>$count</white> field${if (count == 1) "" else "s"}. <gray>Publish on the web to go live.".asMini(),
        )
        ContentPopTrigger.triggerFor(player, context())
    }

    final override suspend fun tick(deltaTime: Duration) {
        super.tick(deltaTime)
        Dispatchers.Sync.switchContext {
            // The hop is already queued when the session is torn down, and the scheduler runs it
            // anyway. Without this it respawns the outline and the hologram into a mode nobody
            // holds any more, leaving displays only a chunk unload can clear.
            if (disposed) return@switchContext
            tickCarry()
            tickFaceDrag()
            tickModeGesture()
            updateOutline()
            updateToolGuides()
            updateGhostMarker()
            updateModeOverlays()
            hologram.update(hologramAnchor(), hologramText())
        }
        if (disposed) return
        renderMarkers(player.location)
        visibleRegion()?.let { renderSurfacePreview(player, it.transform, it.shape, editColor()) }
        session?.let { it.preview = visibleRegion()?.let(::sessionPreview) }
    }

    /** The live snapshot the spectator renderer draws for other players near the region. */
    private fun sessionPreview(region: PendingRegion): SessionPreview = SessionPreview(
        regionName = editedEntryRaw()?.name ?: "Region",
        transform = region.transform,
        shape = region.shape,
        color = editColor(),
        activity = when {
            carrying -> "is carrying the region"
            grabbedFace != null -> "is dragging the ${grabbedFace?.label}"
            modeGestureActive() -> modeGestureActivity() ?: "is editing"
            else -> "is editing"
        },
    )

    protected fun emitMarker(block: CapturedBlock, particle: Particle, eye: Location) {
        if (block.world.identifier != player.world.uid.toString()) return

        val marker = Vector(block.x + 0.5, block.y + 1.2, block.z + 0.5)
        if (!withinPreviewDistance(marker, eye)) return
        emitPreviewParticle(player, marker, particle)
    }

    /** The color this region draws with, from the definition's color property. */
    protected fun editColor(): Color = definition()?.displayColor(entryRef?.id ?: "") ?: Color.WHITE

    /**
     * The shape the working model currently describes. Modes with a resize tool track the
     * sizes themselves, because staged writes are not visible through the entry.
     */
    protected open fun workingShape(): Shape? = definition()?.buildShapeOrNull()

    /** An extra hologram line describing the working size, like `half 5.0 × 3.0 × 5.0`. */
    protected open fun hologramSizeLine(): String? = null

    /**
     * The live preview of the working model. `null` when the origin is variable bound,
     * since it cannot resolve at edit time. Regions using `rotateWithOrigin` preview with
     * the raw yaw and pitch.
     */
    private fun workingRegion(): PendingRegion? {
        val transform = workingTransform() ?: return null
        val shape = workingShape() ?: return null
        return PendingRegion(transform, shape)
    }

    protected fun workingTransform(): ResolvedTransform? {
        val origin = effectiveOrigin() ?: return null
        return ResolvedTransform.fromOriginAndOffset(
            origin,
            workingOffset,
            workingYaw ?: 0f,
            workingPitch ?: 0f,
            workingRoll ?: 0f,
        )
    }

    protected fun isCarryingRegion(): Boolean = carrying

    /** Whether the resize tool holds a grabbed face. */
    protected fun isFaceGrabbed(): Boolean = grabbedFace != null

    /** Records a grab to place gesture as one history entry, like the region carry. */
    protected fun recordGestureEntry(
        tool: String,
        label: String,
        before: Map<String, Any?>,
        after: Map<String, Any?>,
    ): Boolean = history.record(tool, label, before, after)

    /** Applies a gesture's base state back, snapping the next render. */
    protected fun restoreGestureBase(values: Map<String, Any?>) = restoreValues(values)

    /** Whether the spectator lock currently freezes the player for key driven editing. */
    protected fun isSpectatorLocked(): Boolean = spectatorLock != null

    /**
     * Copies the constant placement fields out of the entry, once. Staged tool writes are
     * not visible through the entry, so this working copy is the editing truth until the
     * mode closes. Variable bound fields stay `null` and their tools refuse with a hint.
     */
    private fun seedWorkingPlacement() {
        if (placementSeeded) return
        placementSeeded = true

        val definition = definition() ?: return
        (definition.origin as? ConstVar)?.let { workingOrigin = it.value }
        (definition.offset as? ConstVar)?.let { workingOffset = it.value }
        (definition.yaw as? ConstVar)?.let { workingYaw = it.value }
        (definition.pitch as? ConstVar)?.let { workingPitch = it.value }
        (definition.roll as? ConstVar)?.let { workingRoll = it.value }
        entryHadPlacement = workingOrigin?.world?.identifier?.isNotBlank() == true
    }

    /**
     * Whether the session itself captured enough geometry to describe the region. Modes
     * with a capture flow override this; a fresh region shows no outline, hologram or tool
     * guides until either the entry already had a placement or the capture completes.
     */
    protected open fun hasCapturedGeometry(): Boolean = true

    private fun regionDefined(): Boolean {
        val origin = workingOrigin ?: return false
        if (origin.world.identifier.isBlank()) return false
        return entryHadPlacement || hasCapturedGeometry()
    }

    /** The working region, but only once it is actually defined enough to visualize. */
    private fun visibleRegion(): PendingRegion? = if (regionDefined()) workingRegion() else null

    private fun bossBarTitle(): String {
        val staged = stagedWrites.size
        val suffix = if (staged > 0) " <gray>· <yellow>$staged</yellow> unsaved" else ""
        if (player.gameMode == GameMode.SPECTATOR) {
            val toolName = spectatorToolName()
            if (spectatorLock == null) {
                return "<gold><bold>Ghost $toolName</bold> <gray>${spectatorHint()}$suffix"
            }
            return "<gold><bold>Ghost $toolName <yellow>[locked]</yellow></bold> <gray>${lockedSpectatorHint()}$suffix"
        }
        if (modeGestureActive()) {
            return instruction() + suffix
        }
        if (carrying) {
            return "<gold><bold>Carrying</bold> <gray>scroll to push or pull, <white>right-click</white> places, <white>left-click</white> puts back"
        }
        grabbedFace?.let {
            return "<gold><bold>Dragging ${it.label}</bold> <gray>aim to move it, <white>right-click</white> keeps, <white>left-click</white> cancels"
        }
        return when (player.inventory.heldItemSlot) {
            MOVE_SLOT ->
                "<gold><bold>Move</bold> <gray><white>right-click</white> carries, <white>left-click</white> nudges, " +
                        "<white>F</white> axis <yellow>[${moveAxisLock.display}]</yellow>$suffix"

            rotateSlot -> {
                val shown = if (rotatePitchMode) {
                    val pitch = workingPitch
                    val roll = workingRoll
                    if (pitch == null || roll == null) "variable" else "${tiltDegrees(pitch, roll).round(1)}°"
                } else {
                    workingYaw?.let { "${it.toDouble().round(1)}°" } ?: "variable"
                }
                "<gold><bold>Rotate ${if (rotatePitchMode) "Tilt" else "Yaw"}</bold> <gray>now <white>$shown</white>, " +
                        "clicks step, <white>F</white> switches axis$suffix"
            }

            resizeSlot -> {
                val face = targetedFace
                if (face == null) {
                    "<gold><bold>Resize</bold> <gray>aim at a face of the region$suffix"
                } else {
                    "<gold><bold>Resize</bold> <gray>aiming at <white>${face.label}</white>: <white>right-click</white> grabs, " +
                            "<white>left-click</white> pushes away, sneak pulls toward you$suffix"
                }
            }

            TELEPORT_SLOT ->
                "<gold><bold>Teleport</bold> <gray><white>right-click</white> region, " +
                        "<white>sneak right-click</white> border, <white>left-click</white> back$suffix"
            UNDO_SLOT ->
                "<gold><bold>History</bold> <gray><white>${history.undoCount}</white> to undo, <white>${history.redoCount}</white> to redo, " +
                        "sneak-click for all$suffix"

            APPLY_SLOT ->
                if (canApply()) "<green><bold>Apply</bold> <gray>saves to the entry; publish on the web to go live$suffix"
                else "<gray><bold>Apply</bold> nothing to save yet"

            else -> instruction() + suffix
        }
    }

    private fun moveTool(): ItemComponent = TransformToolComponent(
        slot = MOVE_SLOT,
        material = Material.PISTON,
        title = {
            when {
                carrying -> "<gold><bold>Move Region</bold> <yellow>(carrying)"
                moveAxisLock != AxisLock.Auto -> "<gold><bold>Move Region</bold> <yellow>[${moveAxisLock.display}]"
                else -> "<gold><bold>Move Region"
            }
        },
        loreText = {
            if (carrying) {
                """
                    |
                    |<line> <gray>The region follows your crosshair.
                    |<line> <gray>Scroll to push or pull, sneak for free placement.
                    |<line> <gray>Right-click to place it, left-click to put it back.
                """.trimMargin()
            } else {
                """
                    |
                    |<line> <gray>Right-click to pick the region up and carry it.
                    |<line> <gray>Left-click to nudge $MOVE_STEP the way you look (sneak: $MOVE_STEP_LARGE).
                    |<line> <gray>Sneak and scroll to slide in $MOVE_FINE_STEP steps.
                    |<line> <gray><white>F</white> locks the axis, <white>Q</white> undoes, sneak <white>Q</white> redoes.
                """.trimMargin()
            }
        },
        glint = { carrying },
        onSwap = ::cycleMoveAxis,
        onDrop = ::undoOrRedoHeldTool,
    ) { click ->
        if (click.grow) {
            if (carrying) placeCarry() else grabRegion()
            return@TransformToolComponent
        }
        if (carrying) {
            cancelCarry()
            return@TransformToolComponent
        }
        nudgeOrigin(
            currentMoveDirection(),
            if (click.large) MOVE_STEP_LARGE else MOVE_STEP,
            "Origin nudge",
        )
    }

    private fun rotateTool(): ItemComponent = TransformToolComponent(
        slot = rotateSlot,
        material = Material.CLOCK,
        title = { "<gold><bold>Rotate Region</bold> <yellow>[${if (rotatePitchMode) "Tilt" else "Yaw"}]" },
        loreText = {
            """
                |
                |<line> <gray>Yaw: right-click and left-click turn it either way.
                |<line> <gray>Tilt: left-click tips the top away from you,
                |<line> <gray>right-click pulls it back, a clean pitch or roll.
                |<line> <gray>Steps of $ROTATE_STEP°, sneak-click for $ROTATE_STEP_LARGE°.
                |<line> <gray>Sneak and scroll for $ROTATE_FINE_STEP° steps.
                |<line> <gray><white>F</white> switches yaw and tilt, <white>Q</white> undoes, sneak <white>Q</white> redoes.
            """.trimMargin()
        },
        onSwap = ::toggleRotateMode,
        onDrop = ::undoOrRedoHeldTool,
    ) { click ->
        val step = if (click.large) ROTATE_STEP_LARGE else ROTATE_STEP
        // In tilt mode left click applies the positive, tipping away step, matching how
        // left click pushes faces and corners on the other tools.
        val positive = if (rotatePitchMode) !click.grow else click.grow
        applyRotation(if (positive) step else -step, coalesce = false)
    }

    private fun resizeTool(): ItemComponent = TransformToolComponent(
        slot = resizeSlot,
        material = Material.SLIME_BLOCK,
        title = {
            when {
                grabbedFace != null -> "<gold><bold>Resize Region</bold> <yellow>(dragging ${grabbedFace?.label})"
                targetedFace != null -> "<gold><bold>Resize Region</bold> <yellow>[${targetedFace?.label}]"
                else -> "<gold><bold>Resize Region"
            }
        },
        loreText = {
            if (grabbedFace != null) {
                """
                    |
                    |<line> <gray>The face follows where you look, along its normal.
                    |<line> <gray>Sneak to snap to $RESIZE_FINE_STEP steps.
                    |<line> <gray>Right-click to keep it, left-click to put it back.
                """.trimMargin()
            } else {
                """
                    |
                    |<line> <gray>Aim at a face; the glowing panel shows the pick.
                    |<line> <gray>Right-click to grab it and drag it by looking.
                    |<line> <gray>Left-click pushes it away from you $RESIZE_STEP,
                    |<line> <gray>sneak-click pulls it toward you.
                    |<line> <gray>Sneak and scroll for $RESIZE_FINE_STEP steps.
                    |<line> <gray><white>Q</white> undoes, sneak <white>Q</white> redoes.
                """.trimMargin()
            }
        },
        glint = { grabbedFace != null },
        onDrop = ::undoOrRedoHeldTool,
    ) { click ->
        if (grabbedFace != null) {
            if (click.grow) confirmFaceDrag() else cancelFaceDrag()
            return@TransformToolComponent
        }
        if (click.grow) {
            grabFace()
            return@TransformToolComponent
        }
        // The click follows the view: pushing moves the aimed face the way the player
        // looks, whichever side of the region they stand on, and sneaking pulls it back.
        val along = viewFollowSign()
        stepTargetedFace((if (click.large) -RESIZE_STEP else RESIZE_STEP) * along, coalesce = false)
    }

    private fun onScroll(heldSlot: Int, steps: Int): Boolean {
        if (carrying) {
            if (heldSlot != MOVE_SLOT) return false
            carryDistance = (carryDistance + steps * CARRY_SCROLL_STEP)
                .coerceIn(CARRY_MIN_DISTANCE, CARRY_MAX_DISTANCE)
            return true
        }
        if (heldSlot == WAND_SLOT && onWandScroll(steps)) return true
        if (grabbedFace != null && heldSlot == resizeSlot) return true
        if (!player.isSneaking) return false
        return when (heldSlot) {
            MOVE_SLOT -> {
                nudgeOrigin(
                    currentMoveDirection(),
                    steps * MOVE_FINE_STEP,
                    "Origin slide",
                    coalesce = true
                )
                true
            }

            rotateSlot -> {
                applyRotation(steps * ROTATE_FINE_STEP, coalesce = true)
                true
            }

            resizeSlot -> {
                stepTargetedFace(steps * RESIZE_FINE_STEP, coalesce = true)
                true
            }

            else -> false
        }
    }

    private fun nudgeOrigin(direction: Vector, distance: Double, label: String, coalesce: Boolean = false) {
        val origin = workingOrigin ?: run {
            notifyVariableBound("origin")
            return
        }
        recorded(EditTool.MOVE, label, if (coalesce) SCROLL_COALESCE_MILLIS else 0) {
            val moved = Position(
                origin.world,
                (origin.x + direction.x * distance).round(2),
                (origin.y + direction.y * distance).round(2),
                (origin.z + direction.z * distance).round(2),
                origin.yaw,
                origin.pitch,
            )
            updateWorkingOrigin(moved)
            val shown = effectiveOrigin() ?: moved
            toolFeedback(
                "<gold>Origin <white>${shown.x.round(2)}, ${shown.y.round(2)}, ${shown.z.round(2)}",
                distance >= 0
            )
            true
        }
    }

    private fun applyRotation(delta: Float, coalesce: Boolean) {
        val window = if (coalesce) SCROLL_COALESCE_MILLIS else 0L
        if (rotatePitchMode) {
            val yaw = workingYaw
            val pitch = workingPitch
            val roll = workingRoll
            if (yaw == null || pitch == null || roll == null) {
                notifyVariableBound("rotation")
                return
            }
            recorded(EditTool.ROTATE, "Tilt", window) {
                val (newPitch, newRoll) = steppedTilt(pitch, roll, tiltFacing(), yaw, delta)
                updateWorkingPitch(newPitch)
                updateWorkingRoll(newRoll)
                toolFeedback("<gold>Tilt <white>${tiltDegrees(newPitch, newRoll).round(1)}°", delta >= 0)
                true
            }
            return
        }

        val yaw = workingYaw ?: run {
            notifyVariableBound("yaw")
            return
        }
        recorded(EditTool.ROTATE, "Yaw", window) {
            val rotated = normalizeDegrees(yaw + delta)
            updateWorkingYaw(rotated)
            toolFeedback("<gold>Yaw <white>${rotated.toDouble().round(1)}°", delta >= 0)
            true
        }
    }

    /**
     * The quantized direction from the viewer toward the region's visual center, the same
     * one the displayed tilt dial uses, so the tilt gesture rotates exactly the way the
     * dial says: a clean pitch or roll, whichever side the player looks from.
     */
    private fun tiltFacing(): Vector {
        val transform = workingTransform() ?: return Vector(0.0, 0.0, 1.0)
        val anchor = transform.worldOrigin
        val center = boundsCenter(guideBounds(transform))
        val eye = eyeVector()
        return quantizedTiltFacing(
            anchor.x + center.x - eye.x,
            anchor.z + center.z - eye.z,
            transform.yawDegrees,
        )
    }

    private fun stepTargetedFace(delta: Double, coalesce: Boolean) {
        val spec = faceSpec() ?: return
        val face = targetedFace ?: run {
            refuse("<red>Aim at a face of the region first.")
            return
        }
        recorded(EditTool.RESIZE, face.label, if (coalesce) SCROLL_COALESCE_MILLIS else 0) {
            val result = spec.moveFace(face, delta)
            if (result.changed) toolFeedback(result.message, delta >= 0) else refuse(result.message)
            result.changed
        }
    }

    private fun grabFace() {
        faceSpec() ?: return
        if (modeGestureActive()) {
            refuse(modeGestureRefusal())
            return
        }
        val face = targetedFace ?: run {
            refuse("<red>Aim at a face of the region first.")
            return
        }
        val transform = workingTransform() ?: run {
            notifyVariableBound("origin")
            return
        }

        val eye = player.eyeLocation
        dragBaseState = editorState()
        dragTransform = transform
        // The eye position at grab time, in the region's local frame. View dependent faces
        // (a sphere's surface, a capsule's side) rebuild their bases from the eye; frozen at
        // the grab, the highlight panel keeps its orientation for the whole drag.
        dragLocalEye = transform.toLocal(Vector(eye.x, eye.y, eye.z))
        grabbedFace = face
        lastDragDelta = 0.0
        player.playSound(player.location, Sound.BLOCK_PISTON_EXTEND, 0.5f, 1.4f)
        player.sendActionBar(
            "<gold>Grabbed ${face.label}. <gray>Look to drag it, right-click to keep it, left-click to put it back.".asMini(),
        )
    }

    /**
     * While a face is grabbed it tracks the view ray: the drag distance is where the ray
     * passes closest to the face's normal line. The base state is restored before every
     * application, so the drag is absolute from the grab and never accumulates error.
     */
    private fun tickFaceDrag() {
        val face = grabbedFace ?: return
        val spec = faceSpec() ?: return
        val base = dragTransform ?: return
        // The drag is a view ray measured against the face, so a player who left the world is
        // measuring against coordinates that mean nothing here. It would keep resizing the
        // region from the far side of a portal, out of sight of the outline.
        if (base.world.identifier != player.world.uid.toString()) {
            cancelFaceDrag()
            return
        }

        val eye = player.eyeLocation
        val eyeVec = Vector(eye.x, eye.y, eye.z)
        val direction = eye.direction
        val directionVec = Vector(direction.x, direction.y, direction.z)
        val center = base.toWorld(face.center)
        val normal = base.rotateLocalToWorld(face.normal)

        var delta = dragDelta(eyeVec, directionVec, center, normal)
        delta = delta.coerceIn(-MAX_FACE_DRAG, MAX_FACE_DRAG)
        delta = if (player.isSneaking) snapToQuarterGrid(delta) else delta.round(2)
        if (delta == lastDragDelta) return
        lastDragDelta = delta

        dragBaseState?.let(::applyValues)
        val result = spec.moveFace(face, delta)
        if (result.changed) {
            player.sendActionBar("${result.message} <gray>(${if (delta >= 0) "+" else ""}${delta.round(2)})".asMini())
        }
    }

    private fun confirmFaceDrag() {
        val face = grabbedFace ?: return
        grabbedFace = null
        dragTransform = null
        dragLocalEye = null
        val base = dragBaseState ?: return
        dragBaseState = null

        if (!history.record(EditTool.RESIZE, face.label, base, editorState())) {
            player.sendActionBar("<gray>The ${face.label} ended up where it started.".asMini())
            return
        }
        player.playSound(player.location, Sound.BLOCK_PISTON_CONTRACT, 0.5f, 1.1f)
        player.sendActionBar("<gold>Kept the ${face.label}.".asMini())
        flashHeldItem()
    }

    private fun cancelFaceDrag() {
        if (grabbedFace == null) return
        grabbedFace = null
        dragTransform = null
        dragLocalEye = null
        dragBaseState?.let(::restoreValues)
        dragBaseState = null
        player.playSound(player.location, Sound.BLOCK_PISTON_CONTRACT, 0.5f, 0.8f)
        player.sendActionBar("<gray>Put the face back where it was.".asMini())
    }

    private fun grabRegion() {
        if (grabbedFace != null) {
            refuse("<red>Keep or put back the grabbed face first.")
            return
        }
        if (modeGestureActive()) {
            refuse(modeGestureRefusal())
            return
        }
        val origin = workingOrigin ?: run {
            notifyVariableBound("origin")
            return
        }
        if (origin.world.identifier != player.world.uid.toString()) {
            refuse("<red>The region is in another world. Teleport to it first.")
            return
        }

        // The carry only ever moves the origin, so its base state holds only the origin:
        // a rotation dialed in mid carry stays its own history entry, and neither placing
        // nor cancelling the carry touches it.
        carryBaseState = mapOf(KEY_ORIGIN to workingOrigin)
        carrying = true
        val anchor = workingTransform()?.worldOrigin ?: Vector(origin.x, origin.y, origin.z)
        carryDistance = player.eyeLocation.distance(Location(player.world, anchor.x, anchor.y, anchor.z))
            .coerceIn(CARRY_MIN_DISTANCE, CARRY_MAX_DISTANCE)
        player.playSound(player.location, Sound.ENTITY_ITEM_FRAME_REMOVE_ITEM, 0.8f, 1.1f)
        player.sendActionBar(
            "<gold>Carrying the region. <gray>Scroll to push or pull, right-click to place, left-click to put it back.".asMini(),
        )
    }

    private fun placeCarry() {
        if (!carrying) return
        carrying = false
        val origin = workingOrigin ?: return
        val placed = Position(
            origin.world,
            origin.x.round(3),
            origin.y.round(3),
            origin.z.round(3),
            origin.yaw,
            origin.pitch,
        )
        updateWorkingOrigin(placed)
        carryBaseState?.let { history.record(EditTool.MOVE, "Region carry", it, mapOf(KEY_ORIGIN to workingOrigin)) }
        carryBaseState = null
        player.playSound(player.location, Sound.ENTITY_ITEM_FRAME_ADD_ITEM, 0.8f, 1.0f)
        player.sendActionBar("<gold>Placed at <white>${placed.x}, ${placed.y}, ${placed.z}</white>.".asMini())
        flashHeldItem()
    }

    /**
     * Puts back whatever the player is holding, wherever they ended up.
     *
     * Every one of these gestures is measured from the eye, so a player moved by anything other
     * than walking takes the region, the face or the corner with them. The editor refuses its own
     * teleport tool mid gesture; this covers the ways out it does not own, like a command, a
     * portal, or dying.
     */
    private fun releaseGestures() {
        cancelModeGesture()
        cancelCarry()
        cancelFaceDrag()
    }

    private fun cancelCarry() {
        if (!carrying) return
        carrying = false
        carryBaseState?.let(::restoreValues)
        carryBaseState = null
        player.playSound(player.location, Sound.ENTITY_ITEM_FRAME_ROTATE_ITEM, 0.8f, 0.8f)
        player.sendActionBar("<gray>Put the region back where it was.".asMini())
    }

    /**
     * While carried, the region hangs on the player's crosshair: on the first block the
     * view ray hits, or floating at the carry distance. Runs on the main thread because
     * the ray trace reads world state.
     */
    private fun tickCarry() {
        if (!carrying) return
        val origin = workingOrigin ?: run {
            carrying = false
            return
        }
        if (origin.world.identifier != player.world.uid.toString()) {
            cancelCarry()
            return
        }

        val eye = player.eyeLocation
        val direction = eye.direction
        val hit = player.world
            .rayTraceBlocks(eye, direction, carryDistance, FluidCollisionMode.NEVER, true)
            ?.hitPosition
        val target = Vector(
            hit?.x ?: (eye.x + direction.x * carryDistance),
            hit?.y ?: (eye.y + direction.y * carryDistance),
            hit?.z ?: (eye.z + direction.z * carryDistance),
        )
        // The crosshair carries the effective anchor, so the resize shift is subtracted
        // back out of the raw working origin.
        val shift = resizeShift
        val snap = !player.isSneaking
        fun settle(value: Double): Double = if (snap) snapToHalfGrid(value) else value.round(2)
        workingOrigin = Position(
            origin.world,
            settle(target.x) - shift.x,
            settle(target.y) - shift.y,
            settle(target.z) - shift.z,
            origin.yaw,
            origin.pitch,
        )
    }

    /**
     * Keeps the display entity outline, the face highlight and the face targeting in sync
     * with the working model. Main thread only.
     */
    private fun updateOutline() {
        val region = visibleRegion()
        if (region == null || region.transform.world.identifier != player.world.uid.toString()) {
            targetedFace = null
            outline.despawn()
            return
        }

        val snap = restoreEpoch != renderedRestoreEpoch
        renderedRestoreEpoch = restoreEpoch
        val anchor = region.transform.worldOrigin
        val color = editColor()
        outline.update(
            Location(player.world, anchor.x, anchor.y, anchor.z),
            region.transform.yawDegrees,
            region.transform.pitchDegrees,
            region.shape,
            color,
            snap = snap,
            rollDegrees = region.transform.rollDegrees,
        )

        val spec = faceSpec()
        if (spec == null || player.inventory.heldItemSlot != resizeSlot || carrying || modeGestureActive()) {
            targetedFace = null
            pinnedFaceId = null
            outline.updateHighlight(null, color)
            return
        }

        val eye = player.eyeLocation
        val eyeVec = Vector(eye.x, eye.y, eye.z)
        val localEye = region.transform.toLocal(eyeVec)
        val grabbed = grabbedFace
        val face = if (grabbed == null) {
            val pinned = pinnedFaceId?.let { id -> spec.faces(localEye).firstOrNull { it.id == id } }
            if (pinnedFaceId != null && pinned == null) pinnedFaceId = null
            if (pinned != null) {
                targetedFace = pinned
                pinned
            } else {
                val direction = eye.direction
                val ahead = Vector(eye.x + direction.x, eye.y + direction.y, eye.z + direction.z)
                val localDirection = (region.transform.toLocal(ahead) - localEye).normalize()
                pickFace(spec.faces(localEye), localEye, localDirection, targetedFace?.id).also { targetedFace = it }
            }
        } else {
            spec.faces(dragLocalEye ?: localEye).firstOrNull { it.id == grabbed.id } ?: grabbed
        }

        val held = grabbed != null || pinnedFaceId != null
        val rotation = RegionOutline.regionRotation(
            region.transform.yawDegrees,
            region.transform.pitchDegrees,
            region.transform.rollDegrees,
        )
        outline.updateHighlight(
            face?.let {
                RegionOutline.panelTransformation(
                    rotation,
                    it.center,
                    it.uBasis,
                    it.vBasis,
                    it.normal,
                    it.halfU,
                    it.halfV
                )
            },
            if (held) Color(0xFFFFD54A.toInt()) else color,
            // The restore epoch and the held state join the key: a history restore snaps
            // the panel, and so does grabbing, pinning or releasing a face, where the
            // panel switches its basis or must apply the held color again.
            face?.let { "${it.id}#$restoreEpoch#$held" },
        )
    }

    private fun teleportToRegion() {
        // The hotbar is frozen mid gesture, but the shard is still reachable through the
        // inventory screen, and teleporting away with the region on the crosshair drags it to
        // wherever the builder lands.
        if (carrying || grabbedFace != null || modeGestureActive()) {
            refuse("<red>Finish what you are holding before teleporting.")
            return
        }
        val transform = workingTransform() ?: run {
            refuse("<red>The origin is bound to a variable, there is nowhere to teleport.")
            return
        }
        val world = resolveBukkitWorld(transform.world.identifier) ?: run {
            refuse("<red>The region's world is not loaded.")
            return
        }

        val anchor = transform.worldOrigin
        val target =
            liftToPassable(Location(world, anchor.x, anchor.y, anchor.z, player.location.yaw, player.location.pitch))
        returnLocation = player.location
        player.teleport(target)
        player.playSound(target, Sound.ENTITY_ENDERMAN_TELEPORT, 0.7f, 1f)
        player.sendActionBar("<gold>Teleported to the region. <gray>Left-click to go back.".asMini())
    }

    /**
     * Teleports to the boundary the player is looking at. Aiming works from inside the region
     * too: the view ray still leaves through the stretch of border the player faces, which is
     * the case this exists for, since a region too big to see the outline of is exactly the one
     * whose border is hard to reach. A ray that never crosses the boundary falls back to the
     * nearest point on it.
     */
    private fun teleportToBorder() {
        if (carrying || grabbedFace != null || modeGestureActive()) {
            refuse("<red>Finish what you are holding before teleporting.")
            return
        }
        if (!regionDefined()) {
            refuse("<red>The region has no shape yet. Capture it with the wand first.")
            return
        }
        val region = workingRegion() ?: run {
            refuse("<red>The origin is bound to a variable, there is nowhere to teleport.")
            return
        }
        val world = resolveBukkitWorld(region.transform.world.identifier) ?: run {
            refuse("<red>The region's world is not loaded.")
            return
        }

        val result = borderTeleport(world, region.transform, region.shape, player.eyeLocation) ?: run {
            refuse("<red>Could not find a border to teleport to.")
            return
        }

        returnLocation = player.location
        player.teleport(result.destination)
        player.playSound(result.destination, Sound.ENTITY_ENDERMAN_TELEPORT, 0.7f, 1.2f)
        val hint = if (result.usedFallback) " <gray>Nothing in your aim, so this is the nearest edge." else ""
        player.sendActionBar("<gold>Teleported to the border.$hint <gray>Left-click to go back.".asMini())
    }

    private fun teleportBack() {
        val back = returnLocation ?: run {
            refuse("<red>No previous spot to return to yet.")
            return
        }
        returnLocation = player.location
        player.teleport(back)
        player.playSound(back, Sound.ENTITY_ENDERMAN_TELEPORT, 0.7f, 0.8f)
        player.sendActionBar("<gold>Teleported back. <gray>Left-click again to bounce between the two.".asMini())
    }

    private fun cycleMoveAxis() {
        moveAxisLock = moveAxisLock.next()
        autoMoveMemory = null
        modeFeedback("<gold>Move axis <white>${moveAxisLock.display}")
    }

    /** [moveDirection] with the auto axis kept steady across ticks by its hysteresis. */
    private fun currentMoveDirection(): Vector {
        val direction = moveDirection(player, moveAxisLock, autoMoveMemory)
        autoMoveMemory = if (moveAxisLock == AxisLock.Auto) direction else null
        return direction
    }

    private fun toggleRotateMode() {
        rotatePitchMode = !rotatePitchMode
        modeFeedback("<gold>Rotating <white>${if (rotatePitchMode) "tilt" else "yaw"}")
    }

    private fun modeFeedback(message: String) {
        player.sendActionBar(message.asMini())
        player.playSound(player.location, Sound.BLOCK_LEVER_CLICK, 0.6f, 1.3f)
    }

    /** Action bar value readout, a click sound pitched up when growing, and an item flash. */
    protected fun toolFeedback(message: String, grow: Boolean) {
        player.sendActionBar(message.asMini())
        player.playSound(player.location, Sound.BLOCK_NOTE_BLOCK_HAT, 0.5f, if (grow) 1.25f else 0.75f)
        flashHeldItem()
    }

    protected fun captureFeedback(message: String, pitch: Float = 1f) {
        player.sendActionBar(message.asMini())
        player.playSound(player.location, Sound.ENTITY_EXPERIENCE_ORB_PICKUP, 0.5f, pitch)
        flashHeldItem()
    }

    protected fun refuse(message: String) {
        player.sendActionBar(message.asMini())
        player.playSound(player.location, Sound.ENTITY_VILLAGER_NO, 0.6f, 1f)
    }

    /**
     * The vanilla cooldown sweep over the held item, as visual confirmation the click
     * registered. Only safe on the main thread, where all interaction handlers run.
     */
    private fun flashHeldItem() {
        val held = player.inventory.itemInMainHand
        if (!held.isEmpty) player.setCooldown(held.type, FLASH_TICKS)
    }

    protected fun notifyVariableBound(field: String) {
        refuse("<red>The $field is bound to a variable and cannot be changed here.")
    }

    private fun hologramAnchor(): Location? {
        val region = visibleRegion() ?: return null
        if (region.transform.world.identifier != player.world.uid.toString()) return null

        val bounds = region.shape.localBounds.rotated(
            region.transform.yawDegrees,
            region.transform.pitchDegrees,
            region.transform.rollDegrees,
        )
        val anchor = region.transform.worldOrigin
        return Location(player.world, anchor.x, anchor.y + bounds.maxY + HOLOGRAM_LIFT, anchor.z)
    }

    private fun hologramText(): String {
        val color = editColor()
        val hex = String.format("#%02X%02X%02X", color.red, color.green, color.blue)
        val lines = mutableListOf<String>()
        editedEntryRaw()?.name?.let { lines += "<$hex>■</$hex> <white><bold>$it</bold></white> <$hex>■</$hex>" }
        effectiveOrigin()?.let { origin ->
            lines += "<#A9B2C3>origin <white>${origin.x.round(2)}, ${origin.y.round(2)}, ${origin.z.round(2)}"
        }

        val rotationParts = mutableListOf<String>()
        workingYaw?.let { rotationParts += "yaw <white>${it.toDouble().round(1)}°</white>" }
        val pitch = workingPitch
        val roll = workingRoll
        if (pitch != null && roll != null && (pitch != 0f || roll != 0f)) {
            rotationParts += "tilt <white>${tiltDegrees(pitch, roll).round(1)}°</white>"
        }
        if (rotationParts.isNotEmpty()) lines += "<#A9B2C3>${rotationParts.joinToString(" ")}"

        hologramSizeLine()?.let { lines += it }

        val staged = stagedWrites.size
        lines += when {
            carrying -> "<gold>carrying"
            grabbedFace != null -> "<gold>dragging ${grabbedFace?.label}"
            staged > 0 -> "<yellow>$staged unsaved change${if (staged == 1) "" else "s"}"
            awaitingPublish -> "<yellow>saved, awaiting publish on the web"
            else -> "<#7E8695>no unsaved changes"
        }
        return lines.joinToString("\n")
    }

    /**
     * While the player holds the move or rotate tool, a glowing guide line shows what a
     * click would do: the move direction colored per world axis (X red, Y green, Z blue),
     * or a gold ring in the rotation plane. The resize tool highlights faces instead.
     *
     * When the region origin is farther than [GUIDE_NEAR_RANGE], the guides come to the
     * player instead: the move arrow anchors on the stretch of boundary nearest to them,
     * and the rotation ring widens to pass through where they stand, drawing only the
     * nearby arc. Main thread only.
     */
    private fun updateToolGuides() {
        val transform = if (carrying || grabbedFace != null || modeGestureActive()) null else workingTransform()
        if (transform == null || !regionDefined() || transform.world.identifier != player.world.uid.toString()) {
            guide.despawn()
            return
        }
        // The held slot froze when the player entered spectator, which makes it exactly
        // the active ghost tool, so the guides render for spectators too.
        when (player.inventory.heldItemSlot) {
            MOVE_SLOT -> updateMoveGuide(transform)
            rotateSlot -> updateRotateGuide(transform)
            else -> guide.despawn()
        }
    }

    private fun eyeVector(): Vector {
        val eye = player.eyeLocation
        return Vector(eye.x, eye.y, eye.z)
    }

    /**
     * Where a guide hangs: the region origin while the player is near it, otherwise the
     * boundary point nearest to the player, so the guide stays in view on a huge region.
     */
    private fun guideAnchor(transform: ResolvedTransform): Pair<Vector, Boolean> {
        val anchor = transform.worldOrigin
        val eye = eyeVector()
        if ((anchor - eye).lengthSquared <= GUIDE_NEAR_RANGE * GUIDE_NEAR_RANGE) return anchor to true
        val boundary = workingShape()?.nearestBoundaryPoint(transform.toLocal(eye)) ?: return anchor to true
        return transform.toWorld(boundary) to false
    }

    /** The offset from the anchor to the boundary point nearest the player, in world axes. */
    private fun nearestBoundaryOffset(transform: ResolvedTransform, eye: Vector): Vector? {
        val local = workingShape()?.nearestBoundaryPoint(transform.toLocal(eye)) ?: return null
        return transform.toWorld(local) - transform.worldOrigin
    }

    private fun updateMoveGuide(transform: ResolvedTransform) {
        val direction = currentMoveDirection()
        val (material, glow) = axisAppearance(direction)
        val (anchor, nearOrigin) = guideAnchor(transform)
        val bounds = guideBounds(transform)
        val length = if (nearOrigin) moveAxisLength(bounds, direction) else FAR_ANCHOR_AXIS_LENGTH
        val view = (anchor + direction * length - eyeVector()).takeIf { it.length > Vector.EPSILON }
            ?.normalize() ?: direction
        guide.update(
            Location(player.world, anchor.x, anchor.y, anchor.z),
            moveGuideSegments(bounds, direction, view, length),
            material,
            glow,
        )
    }

    private fun updateRotateGuide(transform: ResolvedTransform) {
        val anchor = transform.worldOrigin
        val eye = eyeVector()
        val nearOrigin = (anchor - eye).lengthSquared <= GUIDE_NEAR_RANGE * GUIDE_NEAR_RANGE
        val bounds = guideBounds(transform)
        // The rings hang on the bounds center, not the anchor: a polygon's outline is not
        // symmetric around its origin, and vertex edits drift the two further apart.
        val center = boundsCenter(bounds)

        // Far from the origin, the guide hangs on the boundary point nearest the player:
        // it sits on the region the way the far move arrow does, instead of floating
        // around the player.
        val boundary = if (nearOrigin) null else nearestBoundaryOffset(transform, eye)

        val segments = if (rotatePitchMode) {
            // The tilt dial stands face on to the viewer's quantized side. The rotation
            // axis is the level line through its middle: the region tips toward or away
            // through the dial, as a clean pitch or roll of the region.
            val facing = quantizedTiltFacing(
                anchor.x + center.x - eye.x,
                anchor.z + center.z - eye.z,
                transform.yawDegrees,
            )
            val side = Vector(facing.z, 0.0, -facing.x)
            val radius = rotationRingRadius(bounds, pitchPlane = true)
            if (boundary == null) {
                ringSegments(radius, center, Vector(0.0, 1.0, 0.0), side)
            } else {
                val offset = Vector(boundary.x.round(1), boundary.y.round(1), boundary.z.round(1))
                ringSegments(radius, offset, Vector(0.0, 1.0, 0.0), side)
            }
        } else {
            if (boundary == null) {
                val radius = rotationRingRadius(bounds, pitchPlane = false)
                ringSegments(radius, center, Vector(1.0, 0.0, 0.0), Vector(0.0, 0.0, 1.0))
            } else {
                val radius = farRingRadius(
                    bounds,
                    sqrt(boundary.x * boundary.x + boundary.z * boundary.z).round(1),
                    pitchPlane = false,
                )
                ringSegments(radius, Vector(0.0, boundary.y.round(1), 0.0), Vector(1.0, 0.0, 0.0), Vector(0.0, 0.0, 1.0))
            }
        }
        val visible = if (boundary == null) segments else cullSegmentsNear(segments, eye - anchor)

        guide.update(
            Location(player.world, anchor.x, anchor.y, anchor.z),
            visible,
            Material.YELLOW_CONCRETE,
            org.bukkit.Color.fromRGB(255, 200, 0),
        )
    }

    /**
     * A spectator flies through walls, so the wand works on the wireframe cube instead of
     * a clicked block: the occupied block while flying, the key nudged selection while
     * locked. Main thread only.
     */
    private fun updateGhostMarker() {
        if (player.gameMode != GameMode.SPECTATOR) {
            ghostMarker.despawn()
            return
        }
        val lock = spectatorLock
        val cube = when {
            lock == null -> occupiedBlock()
            player.inventory.heldItemSlot == WAND_SLOT && usesSelectionCube() -> lock.cube
            else -> null
        }
        if (cube == null) {
            ghostMarker.despawn()
            return
        }
        ghostMarker.update(
            Location(player.world, cube.x.toDouble(), cube.y.toDouble(), cube.z.toDouble()),
            BLOCK_OUTLINE_SEGMENTS,
            Material.YELLOW_CONCRETE,
            org.bukkit.Color.fromRGB(255, 200, 0),
            GHOST_MARKER_THICKNESS,
        )
    }

    private fun markSpectatorSecondary() {
        spectatorSecondary(occupiedBlock())
    }

    private fun occupiedBlock(): CapturedBlock {
        val block = player.location.block
        return CapturedBlock(World(block.world.uid.toString()), block.x, block.y, block.z)
    }

    /**
     * The wand's left click from the locked spectator state, fired on the selection cube.
     * Capture modes override this with their marking behavior.
     */
    protected open fun spectatorMark(block: CapturedBlock) {}

    /**
     * The free flight secondary gesture, sprint and sneak pressed together. Modes with a
     * wand right click behavior override this with it.
     */
    protected open fun spectatorSecondary(block: CapturedBlock) {}

    /**
     * Whether the locked wand drives the ghost selection cube. Corner based modes return
     * `false` and target by aim instead, the way the resize tool targets faces.
     */
    protected open fun usesSelectionCube(): Boolean = true

    /** Called when the spectator lock releases, so modes can drop lock scoped state. */
    protected open fun onSpectatorLockReleased() {}

    /**
     * Locks the spectator in place for key driven editing, or releases them. The camera
     * stays free so the player can still aim; only movement freezes, by zeroing the fly
     * speed, with the listener's move pin guarding the client side scroll speed override.
     */
    private fun toggleSpectatorLock() {
        val lock = spectatorLock
        if (lock != null) {
            releaseSpectatorLock()
            return
        }
        spectatorLock = SpectatorLockState(player.location.clone(), occupiedBlock(), player.flySpeed)
        player.flySpeed = 0f
        player.playSound(player.location, Sound.BLOCK_BEACON_ACTIVATE, 0.4f, 1.6f)
        player.sendActionBar("<gold>Locked in place. <gray>The keys now drive the tool; <white>jump + sneak</white> releases.".asMini())
    }

    private fun releaseSpectatorLock() = releaseSpectatorLock(quiet = false)

    private fun releaseSpectatorLock(quiet: Boolean) {
        val lock = spectatorLock ?: return
        spectatorLock = null
        pinnedFaceId = null
        onSpectatorLockReleased()
        player.flySpeed = lock.previousFlySpeed
        if (quiet) return
        player.playSound(player.location, Sound.BLOCK_BEACON_DEACTIVATE, 0.4f, 1.6f)
        player.sendActionBar("<gray>Released. Fly freely again.".asMini())
    }

    private fun onSpectatorKey(key: SpectatorKey) {
        if (spectatorLock == null) return
        when (player.inventory.heldItemSlot) {
            WAND_SLOT -> wandSpectatorKey(key)
            MOVE_SLOT -> moveSpectatorKey(key)
            rotateSlot -> rotateSpectatorKey(key)
            resizeSlot -> resizeSpectatorKey(key)
            else -> player.sendActionBar(
                "<gray>No ghost controls on this slot. Hold a tool before entering spectator.".asMini(),
            )
        }
    }

    /** The locked wand keys: the base nudges and marks the ghost selection cube. */
    internal open fun wandSpectatorKey(key: SpectatorKey) {
        val lock = spectatorLock ?: return
        if (key == SpectatorKey.MARK) {
            spectatorMark(lock.cube)
            return
        }
        val direction = spectatorKeyDirection(key, player.location.yaw) ?: return
        val cube = lock.cube
        lock.cube = CapturedBlock(
            cube.world,
            cube.x + direction.x.roundToInt(),
            cube.y + direction.y.roundToInt(),
            cube.z + direction.z.roundToInt(),
        )
        player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.2f, 1.8f)
        player.sendActionBar(
            "<gray>Selection at <white>${lock.cube.x}, ${lock.cube.y}, ${lock.cube.z}</white>. <white>Ctrl</white> marks it.".asMini(),
        )
    }

    private fun moveSpectatorKey(key: SpectatorKey) {
        val direction = spectatorKeyDirection(key, player.location.yaw) ?: run {
            player.sendActionBar("<gray>WASD, space and shift nudge the region.".asMini())
            return
        }
        nudgeOrigin(direction, MOVE_STEP, "Origin nudge")
    }

    private fun rotateSpectatorKey(key: SpectatorKey) {
        when (key) {
            SpectatorKey.LEFT, SpectatorKey.RIGHT -> {
                rotatePitchMode = false
                applyRotation(if (key == SpectatorKey.RIGHT) ROTATE_STEP else -ROTATE_STEP, coalesce = false)
            }

            SpectatorKey.FORWARD, SpectatorKey.BACKWARD -> {
                rotatePitchMode = true
                // W tips the region's top away from the player, S pulls it back, matching
                // how W pushes and S pulls on the resize tool.
                applyRotation(if (key == SpectatorKey.FORWARD) ROTATE_STEP else -ROTATE_STEP, coalesce = false)
            }

            else -> player.sendActionBar("<gray>A/D turn the yaw, W/S tilt it away or toward you.".asMini())
        }
    }

    private fun resizeSpectatorKey(key: SpectatorKey) {
        when (key) {
            SpectatorKey.FORWARD -> stepTargetedFace(RESIZE_STEP * viewFollowSign(), coalesce = false)
            SpectatorKey.BACKWARD -> stepTargetedFace(-RESIZE_STEP * viewFollowSign(), coalesce = false)
            SpectatorKey.UP -> toggleFacePin()
            else -> player.sendActionBar(
                "<gray>Aim at a face; W pushes it away, S pulls it toward you, <white>space</white> pins it.".asMini(),
            )
        }
    }

    /**
     * Pins the aimed face for the locked spectator, so the keys keep driving it even when
     * another face of the region slides in front of the view, which pushing a face far
     * enough does all by itself.
     */
    private fun toggleFacePin() {
        if (pinnedFaceId != null) {
            pinnedFaceId = null
            player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.3f, 1.2f)
            player.sendActionBar("<gray>Face released. The aim picks faces again.".asMini())
            return
        }
        val face = targetedFace ?: run {
            refuse("<red>Aim at a face to pin it first.")
            return
        }
        pinnedFaceId = face.id
        player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.3f, 1.6f)
        player.sendActionBar(
            "<gold>Pinned the ${face.label}. <gray>W and S keep driving it; <white>space</white> releases.".asMini(),
        )
    }

    /**
     * Whether stepping the aimed face outward moves it away from the player: `1.0` when
     * its outward normal points along the view, `-1.0` when the face looks back at the
     * player, so pushing always moves the face the way the player is looking.
     */
    private fun viewFollowSign(): Double {
        val face = targetedFace ?: return 1.0
        val transform = workingTransform() ?: return 1.0
        val direction = player.eyeLocation.direction
        val normal = transform.rotateLocalToWorld(face.normal)
        return pushPullSign(Vector(direction.x, direction.y, direction.z), normal)
    }

    private class SpectatorLockState(val anchor: Location, var cube: CapturedBlock, val previousFlySpeed: Float)

    /** The region's world aligned extents, which the tool guides size themselves from. */
    private fun guideBounds(transform: ResolvedTransform): LocalBounds =
        workingShape()?.localBounds?.rotated(transform.yawDegrees, transform.pitchDegrees, transform.rollDegrees)
            ?: LocalBounds(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    protected fun axisAppearance(direction: Vector): Pair<Material, org.bukkit.Color> = when {
        abs(direction.y) > abs(direction.x) && abs(direction.y) > abs(direction.z) ->
            Material.LIME_CONCRETE to org.bukkit.Color.fromRGB(85, 255, 85)

        abs(direction.x) >= abs(direction.z) ->
            Material.RED_CONCRETE to org.bukkit.Color.fromRGB(255, 85, 85)

        else -> Material.LIGHT_BLUE_CONCRETE to org.bukkit.Color.fromRGB(85, 170, 255)
    }

    protected data class StagedWrite(val value: Any, val type: Type)

    companion object {
        internal const val ORIGIN_FIELD = "origin"

        private const val KEY_ORIGIN = "work.origin"
        private const val KEY_OFFSET = "work.offset"
        private const val KEY_YAW = "work.yaw"
        private const val KEY_PITCH = "work.pitch"
        private const val KEY_ROLL = "work.roll"
        private const val KEY_RESIZE_SHIFT = "size.shift"

        internal const val CARRY_SCROLL_STEP = 1.0
        internal const val CARRY_MIN_DISTANCE = 2.0
        internal const val CARRY_MAX_DISTANCE = 48.0
        private const val MAX_FACE_DRAG = 64.0
        internal const val SCROLL_COALESCE_MILLIS = 1200L

        private const val HOLOGRAM_LIFT = 1.0
        private const val FLASH_TICKS = 5
        private const val GHOST_MARKER_THICKNESS = 0.08f
    }
}

/** The wand item. A click in the air marks the block the player stands on. */
internal class RegionWandComponent(
    private val title: String,
    private val loreText: String,
    private val onDrop: () -> Unit,
    private val onSwap: (() -> Unit)? = null,
    private val onSelect: (ItemInteraction, CapturedBlock) -> Unit,
) : ItemComponent {
    override fun item(player: Player): Pair<Int, IntractableItem> {
        val item = ItemStack(Material.GOLDEN_AXE).apply {
            editMeta { meta ->
                meta.name = title
                meta.loreString = loreText
            }
        }
        return WAND_SLOT to (item onInteract { interaction ->
            if (interaction.type == ItemInteractionType.DROP) {
                onDrop()
                return@onInteract
            }
            if (interaction.type == ItemInteractionType.SWAP) {
                onSwap?.invoke()
                return@onInteract
            }
            if (!interaction.type.isClick) return@onInteract
            val block = interaction.clickedBlock ?: player.location.block
            onSelect(interaction, CapturedBlock(World(block.world.uid.toString()), block.x, block.y, block.z))
        })
    }
}

/**
 * The apply item. The content mode sends the inventory again every tick, so the dye swaps
 * color as soon as there is something to save.
 */
internal class ApplyItemComponent(
    private val ready: () -> Boolean,
    private val stagedCount: () -> Int,
    private val onApply: () -> Unit,
) : ItemComponent {
    override fun item(player: Player): Pair<Int, IntractableItem> {
        val item = if (ready()) readyItem() else notReadyItem()
        return APPLY_SLOT to (item onInteract { interaction ->
            if (!interaction.type.isActivation) return@onInteract
            onApply()
        })
    }

    private fun readyItem(): ItemStack = ItemStack(Material.LIME_DYE).apply {
        val staged = stagedCount()
        editMeta { meta ->
            meta.name = "<green><bold>Apply"
            meta.loreString = """
                |
                |<line> <gray>Click to save the region to its entry.
                |<line> <gray>Leaving without applying discards the changes.
                |<line> <gray>Publish on the web afterwards to make it live.
                |${if (staged > 0) "<line> <yellow>$staged</yellow> <gray>staged change${if (staged == 1) "" else "s"} waiting." else ""}
            """.trimMargin()
        }
    }

    private fun notReadyItem(): ItemStack = ItemStack(Material.GRAY_DYE).apply {
        editMeta { meta ->
            meta.name = "<gray><bold>Apply <dark_gray>(nothing to save)"
            meta.loreString = """
                |
                |<line> <gray>Capture the region with the wand or nudge it
                |<line> <gray>with the tools, then click here to save.
            """.trimMargin()
        }
    }
}

/**
 * `true` when the interaction is a way of pressing the item like a button: a click in the world or
 * a click on it in the inventory, which is how a builder with the inventory open reaches it.
 *
 * Dropping and swapping are excluded. Both would otherwise activate whatever the item does, and a
 * stray Q over the Apply dye would save and end the session on the builder's behalf.
 */
internal val ItemInteractionType.isActivation: Boolean
    get() = isClick || this == ItemInteractionType.INVENTORY_CLICK
