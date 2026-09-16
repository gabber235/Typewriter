package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.content.components.IntractableItem
import com.typewritermc.engine.paper.content.components.ItemComponent
import com.typewritermc.engine.paper.content.components.ItemInteractionType
import com.typewritermc.engine.paper.content.components.onInteract
import com.typewritermc.engine.paper.utils.loreString
import com.typewritermc.engine.paper.utils.name
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import kotlin.math.abs

internal const val MOVE_STEP = 0.5
internal const val MOVE_STEP_LARGE = 2.0
internal const val MOVE_FINE_STEP = 0.25
internal const val ROTATE_STEP = 15f
internal const val ROTATE_STEP_LARGE = 45f
internal const val ROTATE_FINE_STEP = 5f
internal const val RESIZE_STEP = 0.5
internal const val RESIZE_FINE_STEP = 0.25

// The hotbar layout is fixed so every shape editor puts the same tool in the same slot:
// capture and transform tools on the left, a gap, then teleport and the meta items.
// A shape without a tool leaves its slot empty instead of shifting the others.
internal const val WAND_SLOT = 0
internal const val MOVE_SLOT = 1
internal const val ROTATE_SLOT = 2
internal const val RESIZE_SLOT = 3
internal const val TELEPORT_SLOT = 5
internal const val UNDO_SLOT = 6
internal const val APPLY_SLOT = 7

/** The tool identities the edit history scopes undo by. */
internal object EditTool {
    const val WAND = "wand"
    const val MOVE = "move"
    const val ROTATE = "rotate"
    const val RESIZE = "resize"
}

/** The axis a tool is locked to. [Auto] follows the player's look direction. */
enum class AxisLock(val display: String) {
    Auto("Auto"),
    X("X"),
    Y("Y"),
    Z("Z"),
    ;

    fun next(): AxisLock = entries[(ordinal + 1) % entries.size]
}

/**
 * The outcome of a face move: the action bar feedback and whether anything changed.
 * Unchanged results play a refusal sound instead of the resize click.
 */
data class ResizeResult(val message: String, val changed: Boolean = true)

/**
 * A boundary feature the resize tool can aim at, step, and grab: a cuboid face, a polygon
 * wall, a cone's base, a sphere's surface under the crosshair. Everything is in the
 * shape's local frame. [normal], [uBasis] and [vBasis] form a right handed orthonormal
 * basis; [halfU] and [halfV] span the highlight panel and the hit test area.
 */
data class RegionFace(
    val id: String,
    val label: String,
    val center: Vector,
    val normal: Vector,
    val uBasis: Vector,
    val vBasis: Vector,
    val halfU: Double,
    val halfV: Double,
)

/**
 * How a content mode resizes its shape: which faces exist for the viewer at [localEye],
 * and what moving a face outward by a delta means. [moveFace] is called with the absolute
 * delta from the drag's start state, on top of a freshly restored base state, so it can
 * apply values absolutely.
 */
interface FaceSpec {
    fun faces(localEye: Vector): List<RegionFace>
    fun moveFace(face: RegionFace, delta: Double): ResizeResult
}

/**
 * The face the player is aiming at: the closest face panel the view ray hits, or, when it
 * hits none, the face nearest to the ray among those whose outside the player is on.
 *
 * [preferredId] adds hysteresis: while the previously targeted face is still hit, or still
 * nearly as close as the best fallback candidate, it stays picked. Without it, aiming near
 * an edge flip flops the pick between two faces every tick and the highlight jitters.
 */
internal fun pickFace(
    faces: List<RegionFace>,
    localEye: Vector,
    localDirection: Vector,
    preferredId: String? = null,
): RegionFace? {
    var bestHit: RegionFace? = null
    var bestHitDistance = Double.MAX_VALUE
    var preferredHit: RegionFace? = null
    var bestNear: RegionFace? = null
    var bestNearDistance = Double.MAX_VALUE
    var preferredNear: RegionFace? = null
    var preferredNearDistance = Double.MAX_VALUE

    for (face in faces) {
        val toCenter = face.center - localEye
        val denominator = localDirection.dot(face.normal)
        if (abs(denominator) > 1e-9) {
            val t = toCenter.dot(face.normal) / denominator
            if (t > 0.05) {
                val hit = localEye + localDirection * t
                val offset = hit - face.center
                if (abs(offset.dot(face.uBasis)) <= face.halfU + FACE_HIT_MARGIN &&
                    abs(offset.dot(face.vBasis)) <= face.halfV + FACE_HIT_MARGIN
                ) {
                    if (face.id == preferredId) preferredHit = face
                    if (t < bestHitDistance) {
                        bestHitDistance = t
                        bestHit = face
                    }
                }
            }
        }

        if (face.normal.dot(localEye - face.center) <= 0.0) continue
        val along = toCenter.dot(localDirection)
        if (along <= 0.0) continue
        val closest = localEye + localDirection * along
        val distance = (face.center - closest).length
        if (face.id == preferredId) {
            preferredNear = face
            preferredNearDistance = distance
        }
        if (distance < bestNearDistance) {
            bestNearDistance = distance
            bestNear = face
        }
    }

    if (preferredHit != null) return preferredHit
    if (bestHit != null) return bestHit
    if (preferredNear != null && preferredNearDistance <= bestNearDistance + NEAR_PICK_STICKINESS) return preferredNear
    return bestNear
}

/**
 * How far along the face normal the player is dragging: the parameter of the closest point
 * on the line `center + t * normal` to the view ray. Everything in world space, directions
 * unit length. Zero when the two are (nearly) parallel.
 */
internal fun dragDelta(eye: Vector, direction: Vector, faceCenter: Vector, faceNormal: Vector): Double {
    val w = faceCenter - eye
    val b = faceNormal.dot(direction)
    val denominator = 1.0 - b * b
    if (abs(denominator) < 1e-9) return 0.0
    val d0 = faceNormal.dot(w)
    val e0 = direction.dot(w)
    return (e0 * b - d0) / denominator
}

/**
 * The step sign that moves a face the way the player is looking: `1.0` when the face's
 * [outwardNormal] points along the [view], so an outward step pushes it away, and `-1.0`
 * when the face looks back at the player, so the same push must step it inward instead.
 */
internal fun pushPullSign(view: Vector, outwardNormal: Vector): Double =
    if (view.dot(outwardNormal) >= 0.0) 1.0 else -1.0

private const val FACE_HIT_MARGIN = 0.3
private const val NEAR_PICK_STICKINESS = 0.75

internal data class ToolClick(val grow: Boolean, val large: Boolean)

/**
 * A hotbar tool in the region editor. Right click applies a positive step, left click a
 * negative one, sneak clicking applies the large step. Pressing the swap hands key cycles
 * the tool's mode and dropping the item undoes that tool's changes, when wired.
 */
internal class TransformToolComponent(
    private val slot: Int,
    private val material: Material,
    private val title: () -> String,
    private val loreText: () -> String,
    private val glint: () -> Boolean = { false },
    private val onSwap: (() -> Unit)? = null,
    private val onDrop: (() -> Unit)? = null,
    private val onClick: (ToolClick) -> Unit,
) : ItemComponent {
    override fun item(player: Player): Pair<Int, IntractableItem> {
        val item = ItemStack(material).apply {
            editMeta { meta ->
                meta.name = title()
                meta.loreString = loreText()
                @Suppress("UsePropertyAccessSyntax") // Getter and setter signatures differ in nullability, so property syntax doesn't compile
                if (glint()) meta.setEnchantmentGlintOverride(true)
            }
        }
        return slot to (item onInteract { interaction ->
            when (interaction.type) {
                ItemInteractionType.RIGHT_CLICK -> onClick(ToolClick(grow = true, large = false))
                ItemInteractionType.SHIFT_RIGHT_CLICK -> onClick(ToolClick(grow = true, large = true))
                ItemInteractionType.LEFT_CLICK -> onClick(ToolClick(grow = false, large = false))
                ItemInteractionType.SHIFT_LEFT_CLICK -> onClick(ToolClick(grow = false, large = true))
                ItemInteractionType.SWAP -> onSwap?.invoke()
                ItemInteractionType.DROP -> onDrop?.invoke()
                else -> {}
            }
        })
    }
}

/**
 * The teleport shard. Right click (or an inventory click) brings the editor to the region,
 * sneak right click teleports to the border the player is looking at, left click returns
 * them to where they teleported from. An amethyst shard because it has no vanilla use
 * behavior of its own: throwable or edible items fight the click routing with client side
 * prediction.
 */
internal class TeleportToolComponent(
    private val slot: Int,
    private val onTeleport: () -> Unit,
    private val onTeleportBorder: () -> Unit,
    private val onReturn: () -> Unit,
    private val onDrop: () -> Unit,
) : ItemComponent {
    override fun item(player: Player): Pair<Int, IntractableItem> {
        val item = ItemStack(Material.AMETHYST_SHARD).apply {
            editMeta { meta ->
                meta.name = "<gold><bold>Teleport"
                meta.loreString = """
                    |
                    |<line> <gray>Right-click to teleport to the region.
                    |<line> <gray>Sneak right-click to teleport to the border you are looking at.
                    |<line> <gray>Left-click to go back to where you were.
                    |<line> <gray>Click again to bounce between the two.
                """.trimMargin()
            }
        }
        return slot to (item onInteract { interaction ->
            when (interaction.type) {
                ItemInteractionType.SHIFT_RIGHT_CLICK -> onTeleportBorder()
                ItemInteractionType.RIGHT_CLICK, ItemInteractionType.INVENTORY_CLICK -> onTeleport()
                ItemInteractionType.LEFT_CLICK, ItemInteractionType.SHIFT_LEFT_CLICK -> onReturn()
                ItemInteractionType.DROP -> onDrop()
                else -> {}
            }
        })
    }
}

/**
 * The undo and redo item. Sneak clicking undoes or redoes everything.
 */
internal class UndoItemComponent(
    private val undoCount: () -> Int,
    private val redoCount: () -> Int,
    private val onUndo: (all: Boolean) -> Unit,
    private val onRedo: (all: Boolean) -> Unit,
) : ItemComponent {
    override fun item(player: Player): Pair<Int, IntractableItem> {
        val undos = undoCount()
        val redos = redoCount()
        val item = when {
            undos > 0 -> undoableItem(undos, redos)
            redos > 0 -> redoOnlyItem(redos)
            else -> emptyHistoryItem()
        }
        return UNDO_SLOT to (item onInteract { interaction ->
            when (interaction.type) {
                ItemInteractionType.LEFT_CLICK, ItemInteractionType.DROP -> onUndo(false)
                ItemInteractionType.SHIFT_LEFT_CLICK -> onUndo(true)
                ItemInteractionType.RIGHT_CLICK -> onRedo(false)
                ItemInteractionType.SHIFT_RIGHT_CLICK -> onRedo(true)
                else -> {}
            }
        })
    }

    private fun undoableItem(undos: Int, redos: Int): ItemStack = ItemStack(Material.ARROW).apply {
        amount = undos.coerceIn(1, 64)
        editMeta { meta ->
            meta.name = "<gold><bold>Undo <gray>/ <gold><bold>Redo"
            meta.loreString = """
                |
                |<line> <gray>Left-click to undo <white>($undos)</white>, right-click to redo <white>($redos)</white>.
                |<line> <gray>Sneak-click to undo or redo <white>everything</white>.
                |<line> <gray>Press <white>Q</white> on a tool to undo that tool's last change,
                |<line> <gray>sneak <white>Q</white> to redo it.
            """.trimMargin()
        }
    }

    private fun redoOnlyItem(redos: Int): ItemStack = ItemStack(Material.SPECTRAL_ARROW).apply {
        amount = redos.coerceIn(1, 64)
        editMeta { meta ->
            meta.name = "<gold><bold>Redo <dark_gray>(everything is undone)"
            meta.loreString = """
                |
                |<line> <gray>Right-click to redo <white>($redos)</white>.
                |<line> <gray>Sneak right-click to redo <white>everything</white>.
            """.trimMargin()
        }
    }

    private fun emptyHistoryItem(): ItemStack = ItemStack(Material.FEATHER).apply {
        editMeta { meta ->
            meta.name = "<gray><bold>History <dark_gray>(no changes yet)"
            meta.loreString = """
                |
                |<line> <gray>Changes made with the tools land here.
                |<line> <gray>The feather turns into an undo arrow
                |<line> <gray>as soon as there is something to undo.
            """.trimMargin()
        }
    }
}

/**
 * The world direction a move step nudges toward. A locked axis moves along that world
 * axis, signed toward the player's look. On [AxisLock.Auto] the axis follows the look
 * through [autoMoveDirection]; pass the previously chosen direction to keep it steady.
 */
internal fun moveDirection(player: Player, lock: AxisLock, previousAuto: Vector? = null): Vector {
    val location = player.location
    val direction = location.direction
    return when (lock) {
        AxisLock.X -> Vector(if (direction.x >= 0) 1.0 else -1.0, 0.0, 0.0)
        AxisLock.Y -> Vector(0.0, if (location.pitch < 0) 1.0 else -1.0, 0.0)
        AxisLock.Z -> Vector(0.0, 0.0, if (direction.z >= 0) 1.0 else -1.0)
        AxisLock.Auto -> autoMoveDirection(
            Vector(direction.x, direction.y, direction.z),
            location.pitch,
            previousAuto,
        )
    }
}

// Hysteresis for the auto axis: entering the vertical axis takes a steeper look than
// staying on it, and the other horizontal axis has to clearly dominate before a switch,
// so the axis does not flip the moment the aim brushes a diagonal.
private const val AUTO_VERTICAL_ENTER_DEGREES = 55f
private const val AUTO_VERTICAL_EXIT_DEGREES = 35f
private const val AUTO_HORIZONTAL_SWITCH_RATIO = 1.4

/**
 * The world axis the look direction picks on [AxisLock.Auto], sticky around [previous]:
 * the vertical axis engages past [AUTO_VERTICAL_ENTER_DEGREES] of pitch and holds until
 * the pitch flattens below [AUTO_VERTICAL_EXIT_DEGREES], and a held horizontal axis only
 * gives way when the other one dominates by [AUTO_HORIZONTAL_SWITCH_RATIO].
 */
internal fun autoMoveDirection(direction: Vector, pitch: Float, previous: Vector? = null): Vector {
    val wasVertical = previous != null && abs(previous.y) > 0.5
    val verticalThreshold = if (wasVertical) AUTO_VERTICAL_EXIT_DEGREES else AUTO_VERTICAL_ENTER_DEGREES
    if (abs(pitch) > verticalThreshold) return Vector(0.0, if (pitch < 0) 1.0 else -1.0, 0.0)

    val pickX = when {
        previous != null && abs(previous.x) > 0.5 ->
            abs(direction.z) <= abs(direction.x) * AUTO_HORIZONTAL_SWITCH_RATIO

        previous != null && abs(previous.z) > 0.5 ->
            abs(direction.x) > abs(direction.z) * AUTO_HORIZONTAL_SWITCH_RATIO

        else -> abs(direction.x) >= abs(direction.z)
    }
    if (pickX) return Vector(if (direction.x >= 0) 1.0 else -1.0, 0.0, 0.0)
    return Vector(0.0, 0.0, if (direction.z >= 0) 1.0 else -1.0)
}

/** Normalizes to the (-180, 180] range Minecraft yaw uses. */
internal fun normalizeDegrees(degrees: Float): Float {
    var value = degrees % 360f
    if (value > 180f) value -= 360f
    if (value <= -180f) value += 360f
    return value
}
