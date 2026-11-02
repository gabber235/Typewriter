package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.components.ItemComponent
import com.typewritermc.engine.paper.content.components.ItemInteractionType
import com.typewritermc.engine.paper.utils.round
import com.typewritermc.region.shape.*
import org.bukkit.Location
import org.bukkit.Particle
import org.bukkit.entity.Player
import kotlin.math.*

private const val MIN_EXTENT = 0.5

/**
 * The refusal for a resize step that changed nothing: either the shape is at its minimum and
 * the step tried to shrink it, or the step was smaller than the rounding. Only the sign of
 * the step separates the two, and reporting "cannot shrink" for a growing step reads as a
 * bug in the tool.
 */
private fun noResize(what: String, delta: Double): ResizeResult = ResizeResult(
    if (delta < 0.0) "<red>$what cannot shrink further."
    else "<red>$what did not move, the step is too small.",
    changed = false,
)

/**
 * Capture based on two marked blocks. Left click marks the primary point and right click
 * marks the secondary point. The moment both are set, the marks derive the placement and
 * size straight into the working model, so marking again one point reshapes the live preview
 * and the transform tools keep working on the result.
 */
abstract class TwoPointRegionContentMode(
    context: ContentContext,
    player: Player,
    private val shapeName: String,
    private val primaryLabel: String,
    private val secondaryLabel: String,
) : RegionContentMode(context, player) {
    protected val primary: CapturedBlock? get() = read(PRIMARY)

    protected val secondary: CapturedBlock? get() = read(SECONDARY)

    final override fun wandComponent(): ItemComponent = RegionWandComponent(
        title = "<gold><bold>Region Wand",
        loreText = """
            |
            |<line> <gray>Left-click a block to mark $primaryLabel.
            |<line> <gray>Right-click a block to mark $secondaryLabel.
            |<line> <gray>Press <white>Q</white> to undo a mark, sneak <white>Q</white> to redo.
        """.trimMargin(),
        onDrop = ::undoOrRedoHeldTool,
    ) { interaction, block ->
        when (interaction.type) {
            ItemInteractionType.LEFT_CLICK, ItemInteractionType.SHIFT_LEFT_CLICK -> markPrimary(block)
            ItemInteractionType.RIGHT_CLICK, ItemInteractionType.SHIFT_RIGHT_CLICK -> markSecondary(block)
            else -> return@RegionWandComponent
        }
    }

    private fun markPrimary(block: CapturedBlock) = mark(primaryLabel, 0.9f, block) {
        write(PRIMARY, block)
        if (secondary?.world != block.world) write(SECONDARY, null)
    }

    private fun markSecondary(block: CapturedBlock) = mark(secondaryLabel, 1.15f, block) {
        write(SECONDARY, block)
        if (primary?.world != block.world) write(PRIMARY, null)
    }

    /**
     * Ghost captures fill the marks in order, and once both are set they mark again whichever
     * point sits closer to the marked block, so a spectator can nudge either corner without
     * leaving the wall they are hovering in.
     */
    final override fun spectatorMark(block: CapturedBlock) {
        val first = primary
        val second = secondary
        when {
            first == null -> markPrimary(block)
            second == null -> markSecondary(block)
            blockDistanceSquared(first, block) <= blockDistanceSquared(second, block) -> markPrimary(block)
            else -> markSecondary(block)
        }
    }

    private fun blockDistanceSquared(a: CapturedBlock, b: CapturedBlock): Double {
        if (a.world != b.world) return Double.MAX_VALUE
        return (a.center - b.center).lengthSquared
    }

    private fun mark(label: String, pitch: Float, block: CapturedBlock, assign: () -> Unit) {
        if (!placementWritable(rotation = capturesRotation)) return

        val markedPrimary = primary
        val markedSecondary = secondary
        var derived = true
        // A refused capture is not a step in the history either. Recording it would leave an undo
        // that changes nothing and a redo that puts the refused mark back, without the geometry
        // that mark was refused for.
        val allowed = recorded(EditTool.WAND, "Marked $label") {
            assign()
            derived = deriveFromMarks()
            derived
        }
        if (!allowed) return

        // A refused capture takes its mark back. Keeping it leaves the editor believing it holds
        // a captured region, so the boss bar invites the builder to adjust geometry that is still
        // the entry's own, and the refusal that just said why is the only sign otherwise.
        if (!derived) {
            write(PRIMARY, markedPrimary)
            write(SECONDARY, markedSecondary)
            return
        }
        captureFeedback("<gold>Marked $label <white>(${block.x}, ${block.y}, ${block.z})", pitch)
    }

    /** `false` when both points are marked but describe no region, which [applyCapture] refuses. */
    private fun deriveFromMarks(): Boolean {
        val a = primary ?: return true
        val b = secondary ?: return true
        if (a.world != b.world) return true
        if (applyCapture(a, b)) return true
        refuse("<red>The two marked points are too close together.")
        return false
    }

    final override fun hasCapturedGeometry(): Boolean = primary != null && secondary != null

    final override fun instruction(): String = when {
        primary == null && secondary == null ->
            "Mark the $shapeName: <red>left-click</red> for $primaryLabel, <green>right-click</green> for $secondaryLabel"

        primary == null -> "<red>Left-click</red> a block to mark $primaryLabel"
        secondary == null -> "<green>Right-click</green> a block to mark $secondaryLabel"
        else -> "Adjust with the tools, re-mark a point, or click <yellow>Apply</yellow>"
    }

    override fun renderMarkers(eye: Location) {
        primary?.let { emitMarker(it, Particle.FLAME, eye) }
        secondary?.let { emitMarker(it, Particle.HAPPY_VILLAGER, eye) }
    }

    /**
     * Derives the placement and size from the two marks into the working model. Returns
     * `false` when the marks cannot describe the shape, like a cone with no length.
     */
    protected abstract fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean

    /** Whether [applyCapture] writes yaw and pitch as well as the origin. */
    protected open val capturesRotation: Boolean = false

    private companion object {
        val PRIMARY = EditField<CapturedBlock?>("marks.primary", null)
        val SECONDARY = EditField<CapturedBlock?>("marks.secondary", null)
    }
}

/** Builds the six axis faces of a box like shape, half extents given per axis. */
private fun boxFaces(halfX: Double, halfY: Double, halfZ: Double): List<RegionFace> = listOf(
    RegionFace(
        "+x",
        "+X face",
        Vector(halfX, 0.0, 0.0),
        Vector(1, 0, 0),
        Vector(0, 1, 0),
        Vector(0, 0, 1),
        halfY,
        halfZ
    ),
    RegionFace(
        "-x",
        "-X face",
        Vector(-halfX, 0.0, 0.0),
        Vector(-1, 0, 0),
        Vector(0, 0, 1),
        Vector(0, 1, 0),
        halfZ,
        halfY
    ),
    RegionFace(
        "+y",
        "top face",
        Vector(0.0, halfY, 0.0),
        Vector(0, 1, 0),
        Vector(0, 0, 1),
        Vector(1, 0, 0),
        halfZ,
        halfX
    ),
    RegionFace(
        "-y",
        "bottom face",
        Vector(0.0, -halfY, 0.0),
        Vector(0, -1, 0),
        Vector(1, 0, 0),
        Vector(0, 0, 1),
        halfX,
        halfZ
    ),
    RegionFace(
        "+z",
        "+Z face",
        Vector(0.0, 0.0, halfZ),
        Vector(0, 0, 1),
        Vector(1, 0, 0),
        Vector(0, 1, 0),
        halfX,
        halfY
    ),
    RegionFace(
        "-z",
        "-Z face",
        Vector(0.0, 0.0, -halfZ),
        Vector(0, 0, -1),
        Vector(0, 1, 0),
        Vector(1, 0, 0),
        halfY,
        halfX
    ),
)

/** The player marks two opposite corners of the box. */
class CuboidRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "box", "corner A", "corner B") {
    private val halfX: Double get() = read(HALF_X)
    private val halfY: Double get() = read(HALF_Y)
    private val halfZ: Double get() = read(HALF_Z)

    override fun seedModeState(state: EditorState): EditorState {
        val shape = editedShape<CuboidShape>()
        return state
            .with(HALF_X, shape?.halfX ?: 1.0)
            .with(HALF_Y, shape?.halfY ?: 1.0)
            .with(HALF_Z, shape?.halfZ ?: 1.0)
    }

    override fun workingShape(): Shape = CuboidShape(halfX, halfY, halfZ)

    override fun hologramSizeLine(): String = "<#A9B2C3>half <white>$halfX × $halfY × $halfZ"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> = boxFaces(halfX, halfY, halfZ)

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult {
            val field = axisField(face.id, HALF_X, HALF_Y, HALF_Z)
            val current = read(field)
            val newHalf = (current + delta / 2).coerceAtLeast(MIN_EXTENT).round(2)
            val applied = (newHalf - current) * 2
            if (applied == 0.0) return noResize("The ${face.label}", delta)
            if (!shiftResizeAnchor(face.normal, applied / 2)) {
                return ResizeResult("<red>The origin is bound to a variable, the face cannot move.", changed = false)
            }

            write(field, newHalf)
            return ResizeResult("<gold>${face.label} <white>half $newHalf")
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val box = BlockBox.spanning(a, b)
        resetWorkingRotation()
        placeCapturedAnchor(a.world, box.center)
        write(HALF_X, box.halfX)
        write(HALF_Y, box.halfY)
        write(HALF_Z, box.halfZ)
        return true
    }

    override fun restageSizeFields() {
        val shape = editedShape<CuboidShape>()
        restageShapeField("halfX", halfX, shape?.halfX)
        restageShapeField("halfY", halfY, shape?.halfY)
        restageShapeField("halfZ", halfZ, shape?.halfZ)
    }

    private companion object {
        val HALF_X = EditField("size.halfX", 1.0, readout = "halfX")
        val HALF_Y = EditField("size.halfY", 1.0, readout = "halfY")
        val HALF_Z = EditField("size.halfZ", 1.0, readout = "halfZ")
    }
}

/** The player marks the center and a point on the boundary. */
class SphereRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "sphere", "the center", "a boundary point") {
    private val radius: Double get() = read(RADIUS)

    override fun seedModeState(state: EditorState): EditorState =
        state.with(RADIUS, editedShape<SphereShape>()?.radius ?: 1.0)

    override fun workingShape(): Shape = SphereShape(radius)

    override fun hologramSizeLine(): String = "<#A9B2C3>radius <white>$radius"

    override fun supportsRotation(): Boolean = false

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> {
            val direction = localEye.takeIf { it.length > Vector.EPSILON }?.normalize() ?: Vector(1, 0, 0)
            val (uBasis, vBasis) = perpendicularBasis(direction)
            return listOf(
                RegionFace("surface", "surface", direction * radius, direction, uBasis, vBasis, 0.75, 0.75),
            )
        }

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult {
            val resized = (radius + delta).coerceAtLeast(MIN_EXTENT).round(2)
            if (resized == radius && delta != 0.0) return noResize("The sphere", delta)
            write(RADIUS, resized)
            return ResizeResult("<gold>Radius <white>$resized")
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        placeCapturedAnchor(a.world, a.center)
        write(RADIUS, a.center.distance(b.center).round(2).coerceAtLeast(MIN_EXTENT))
        return true
    }

    override fun restageSizeFields() {
        restageShapeField("radius", radius, editedShape<SphereShape>()?.radius)
    }

    private companion object {
        val RADIUS = EditField("size.radius", 1.0, readout = "radius")
    }
}

/** The player marks two corners of a box. The ellipsoid is inscribed in that box. */
class EllipsoidRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "ellipsoid", "corner A", "corner B") {
    private val radiusX: Double get() = read(RADIUS_X)
    private val radiusY: Double get() = read(RADIUS_Y)
    private val radiusZ: Double get() = read(RADIUS_Z)

    override fun seedModeState(state: EditorState): EditorState {
        val shape = editedShape<EllipsoidShape>()
        return state
            .with(RADIUS_X, shape?.radiusX ?: 1.0)
            .with(RADIUS_Y, shape?.radiusY ?: 1.0)
            .with(RADIUS_Z, shape?.radiusZ ?: 1.0)
    }

    override fun workingShape(): Shape = EllipsoidShape(radiusX, radiusY, radiusZ)

    override fun hologramSizeLine(): String = "<#A9B2C3>radii <white>$radiusX × $radiusY × $radiusZ"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> = listOf(
            RegionFace(
                "+x",
                "+X cap",
                Vector(radiusX, 0.0, 0.0),
                Vector(1, 0, 0),
                Vector(0, 1, 0),
                Vector(0, 0, 1),
                radiusY * 0.5,
                radiusZ * 0.5
            ),
            RegionFace(
                "-x",
                "-X cap",
                Vector(-radiusX, 0.0, 0.0),
                Vector(-1, 0, 0),
                Vector(0, 0, 1),
                Vector(0, 1, 0),
                radiusZ * 0.5,
                radiusY * 0.5
            ),
            RegionFace(
                "+y",
                "top cap",
                Vector(0.0, radiusY, 0.0),
                Vector(0, 1, 0),
                Vector(0, 0, 1),
                Vector(1, 0, 0),
                radiusZ * 0.5,
                radiusX * 0.5
            ),
            RegionFace(
                "-y",
                "bottom cap",
                Vector(0.0, -radiusY, 0.0),
                Vector(0, -1, 0),
                Vector(1, 0, 0),
                Vector(0, 0, 1),
                radiusX * 0.5,
                radiusZ * 0.5
            ),
            RegionFace(
                "+z",
                "+Z cap",
                Vector(0.0, 0.0, radiusZ),
                Vector(0, 0, 1),
                Vector(1, 0, 0),
                Vector(0, 1, 0),
                radiusX * 0.5,
                radiusY * 0.5
            ),
            RegionFace(
                "-z",
                "-Z cap",
                Vector(0.0, 0.0, -radiusZ),
                Vector(0, 0, -1),
                Vector(0, 1, 0),
                Vector(1, 0, 0),
                radiusY * 0.5,
                radiusX * 0.5
            ),
        )

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult {
            val field = axisField(face.id, RADIUS_X, RADIUS_Y, RADIUS_Z)
            val current = read(field)
            val newRadius = (current + delta / 2).coerceAtLeast(MIN_EXTENT).round(2)
            val applied = (newRadius - current) * 2
            if (applied == 0.0) return noResize("The ${face.label}", delta)
            if (!shiftResizeAnchor(face.normal, applied / 2)) {
                return ResizeResult("<red>The origin is bound to a variable, the cap cannot move.", changed = false)
            }

            write(field, newRadius)
            return ResizeResult("<gold>${face.label} <white>radius $newRadius")
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val box = BlockBox.spanning(a, b)
        resetWorkingRotation()
        placeCapturedAnchor(a.world, box.center)
        write(RADIUS_X, box.halfX.coerceAtLeast(MIN_EXTENT))
        write(RADIUS_Y, box.halfY.coerceAtLeast(MIN_EXTENT))
        write(RADIUS_Z, box.halfZ.coerceAtLeast(MIN_EXTENT))
        return true
    }

    override fun restageSizeFields() {
        val shape = editedShape<EllipsoidShape>()
        restageShapeField("radiusX", radiusX, shape?.radiusX)
        restageShapeField("radiusY", radiusY, shape?.radiusY)
        restageShapeField("radiusZ", radiusZ, shape?.radiusZ)
    }

    private companion object {
        val RADIUS_X = EditField("size.radiusX", 1.0, readout = "radiusX")
        val RADIUS_Y = EditField("size.radiusY", 1.0, readout = "radiusY")
        val RADIUS_Z = EditField("size.radiusZ", 1.0, readout = "radiusZ")
    }
}

/**
 * The player marks two corners of a box. The capsule is inscribed in that box: the radius
 * comes from the wider horizontal half extent and the cylinder half height is the vertical
 * space left after the two hemispheres.
 */
class CapsuleRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "capsule", "corner A", "corner B") {
    private val radius: Double get() = read(RADIUS)
    private val halfHeight: Double get() = read(HALF_HEIGHT)

    override fun seedModeState(state: EditorState): EditorState {
        val shape = editedShape<CapsuleShape>()
        return state
            .with(RADIUS, shape?.radius ?: 1.0)
            .with(HALF_HEIGHT, shape?.halfHeight ?: 1.0)
    }

    override fun workingShape(): Shape = CapsuleShape(radius, halfHeight)

    override fun hologramSizeLine(): String =
        "<#A9B2C3>radius <white>$radius</white> <#A9B2C3>half height <white>$halfHeight"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> {
            val top = halfHeight + radius
            val lateral = Vector(localEye.x, 0.0, localEye.z)
            val sideDirection = lateral.takeIf { it.length > Vector.EPSILON }?.normalize() ?: Vector(1, 0, 0)
            val sideCenter =
                sideDirection * radius + Vector(0.0, localEye.y.coerceIn(-halfHeight, halfHeight), 0.0)
            val sideU = Vector(0, 1, 0).cross(sideDirection)
            return listOf(
                RegionFace(
                    "+y",
                    "top cap",
                    Vector(0.0, top, 0.0),
                    Vector(0, 1, 0),
                    Vector(0, 0, 1),
                    Vector(1, 0, 0),
                    radius * 0.6,
                    radius * 0.6
                ),
                RegionFace(
                    "-y",
                    "bottom cap",
                    Vector(0.0, -top, 0.0),
                    Vector(0, -1, 0),
                    Vector(1, 0, 0),
                    Vector(0, 0, 1),
                    radius * 0.6,
                    radius * 0.6
                ),
                RegionFace(
                    "side",
                    "side",
                    sideCenter,
                    sideDirection,
                    sideU,
                    Vector(0, 1, 0),
                    radius * 0.6,
                    halfHeight + radius * 0.4
                ),
            )
        }

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult = when (face.id) {
            "side" -> {
                val resized = (radius + delta).coerceAtLeast(MIN_EXTENT).round(2)
                if (resized == radius && delta != 0.0) {
                    noResize("The capsule", delta)
                } else {
                    write(RADIUS, resized)
                    ResizeResult("<gold>Radius <white>$resized")
                }
            }

            else -> {
                val current = halfHeight
                val newHalf = (current + delta / 2).coerceAtLeast(0.0).round(2)
                val applied = (newHalf - current) * 2
                if (applied == 0.0) {
                    ResizeResult("<red>The ${face.label} cannot move further.", changed = false)
                } else if (!shiftResizeAnchor(face.normal, applied / 2)) {
                    ResizeResult("<red>The origin is bound to a variable, the cap cannot move.", changed = false)
                } else {
                    write(HALF_HEIGHT, newHalf)
                    ResizeResult("<gold>${face.label} <white>half height $newHalf")
                }
            }
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val box = BlockBox.spanning(a, b)
        resetWorkingRotation()
        placeCapturedAnchor(a.world, box.center)
        val capturedRadius = max(box.halfX, box.halfZ).coerceAtLeast(MIN_EXTENT).round(2)
        write(RADIUS, capturedRadius)
        write(HALF_HEIGHT, (box.halfY - capturedRadius).coerceAtLeast(0.0).round(2))
        return true
    }

    override fun restageSizeFields() {
        val shape = editedShape<CapsuleShape>()
        restageShapeField("radius", radius, shape?.radius)
        restageShapeField("halfHeight", halfHeight, shape?.halfHeight)
    }

    private companion object {
        val RADIUS = EditField("size.radius", 1.0, readout = "radius")
        val HALF_HEIGHT = EditField("size.halfHeight", 1.0, readout = "halfHeight")
    }
}

/**
 * The player marks the apex and a point the cone aims at. The half angle keeps the entry's
 * current value.
 */
class ConeRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "cone", "the apex", "the target") {
    private val length: Double get() = read(LENGTH)
    private val halfAngleDegrees: Double get() = read(HALF_ANGLE)

    override fun seedModeState(state: EditorState): EditorState {
        val shape = editedShape<ConeShape>()
        // Seeded exactly as the entry holds it. Rounding a stored angle into the tool's own range
        // here would show the builder a cone that is not theirs, and save that back the moment
        // they applied anything.
        return state
            .with(LENGTH, shape?.length ?: DEFAULT_LENGTH)
            .with(HALF_ANGLE, shape?.halfAngleDegrees ?: DEFAULT_HALF_ANGLE)
    }

    override fun workingShape(): Shape = ConeShape(length, halfAngleDegrees)

    override fun hologramSizeLine(): String =
        "<#A9B2C3>length <white>$length</white> <#A9B2C3>half angle <white>$halfAngleDegrees°"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> {
            val halfAngle = Math.toRadians(halfAngleDegrees)
            val rimRadius = length * sin(halfAngle)
            val azimuth = atan2(localEye.y, localEye.x).takeIf { !it.isNaN() } ?: 0.0
            val lateralDirection = Vector(
                sin(halfAngle) * cos(azimuth),
                sin(halfAngle) * sin(azimuth),
                cos(halfAngle),
            )
            val lateralNormal = Vector(
                cos(halfAngle) * cos(azimuth),
                cos(halfAngle) * sin(azimuth),
                -sin(halfAngle),
            )
            val lateralU = Vector(-sin(azimuth), cos(azimuth), 0.0)
            return listOf(
                RegionFace(
                    "base",
                    "base",
                    Vector(0.0, 0.0, length),
                    Vector(0, 0, 1),
                    Vector(1, 0, 0),
                    Vector(0, 1, 0),
                    rimRadius * 0.7,
                    rimRadius * 0.7
                ),
                RegionFace(
                    "side", "side",
                    lateralDirection * (length * 0.6),
                    lateralNormal,
                    lateralU,
                    lateralNormal.cross(lateralU),
                    0.8,
                    length * 0.35,
                ),
                RegionFace("apex", "apex", Vector.ZERO, Vector(0, 0, -1), Vector(0, 1, 0), Vector(1, 0, 0), 0.5, 0.5),
            )
        }

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult = when (face.id) {
            "base" -> {
                val resized = (length + delta).coerceAtLeast(1.0).round(2)
                if (resized == length && delta != 0.0) {
                    noResize("The cone", delta)
                } else {
                    write(LENGTH, resized)
                    ResizeResult("<gold>Length <white>$resized")
                }
            }

            "side" -> {
                val halfAngle = (halfAngleDegrees + delta * DEGREES_PER_BLOCK).coerceIn(1.0, 89.0).round(2)
                if (halfAngle == halfAngleDegrees && delta != 0.0) {
                    ResizeResult("<red>The half angle is at its limit.", changed = false)
                } else {
                    write(HALF_ANGLE, halfAngle)
                    ResizeResult("<gold>Half angle <white>$halfAngle°")
                }
            }

            else -> {
                val resized = (length + delta).coerceAtLeast(1.0).round(2)
                val applied = resized - length
                if (applied == 0.0) {
                    ResizeResult("<red>The apex cannot move further.", changed = false)
                } else if (!shiftResizeAnchor(Vector(0, 0, -1), applied)) {
                    ResizeResult("<red>The origin is bound to a variable, the apex cannot move.", changed = false)
                } else {
                    write(LENGTH, resized)
                    ResizeResult("<gold>Apex moved, length <white>$resized")
                }
            }
        }
    }

    override val capturesRotation: Boolean = true

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val aim = aim(a, b) ?: return false
        updateWorkingYaw(aim.yawDegrees)
        updateWorkingPitch(aim.pitchDegrees)
        placeCapturedAnchor(a.world, a.center)
        write(LENGTH, aim.length)
        return true
    }

    override fun restageSizeFields() {
        val shape = editedShape<ConeShape>()
        restageShapeField("length", length, shape?.length)
        restageShapeField("halfAngleDegrees", halfAngleDegrees, shape?.halfAngleDegrees)
    }

    /**
     * Solves the yaw and pitch for which [com.typewritermc.region.data.ResolvedTransform.rotateLocalToWorld]
     * maps the local +Z cone axis onto the direction from [a] to [b]. That mapping follows
     * Minecraft's yaw/pitch convention, sending +Z to
     * `(-sinYaw * cosPitch, -sinPitch, cosYaw * cosPitch)`.
     */
    private fun aim(a: CapturedBlock, b: CapturedBlock): ConeAim? {
        val dx = b.center.x - a.center.x
        val dy = b.center.y - a.center.y
        val dz = b.center.z - a.center.z
        val distance = sqrt(dx * dx + dy * dy + dz * dz)
        if (distance < MIN_EXTENT) return null

        val yaw = Math.toDegrees(atan2(-dx, dz)).toFloat().round(2)
        val pitch = Math.toDegrees(asin(-dy / distance)).toFloat().round(2)
        return ConeAim(distance.round(2), yaw, pitch)
    }

    private data class ConeAim(val length: Double, val yawDegrees: Float, val pitchDegrees: Float)

    private companion object {
        const val DEFAULT_LENGTH = 8.0
        const val DEFAULT_HALF_ANGLE = 30.0
        const val DEGREES_PER_BLOCK = 5.0
        val LENGTH = EditField("size.length", DEFAULT_LENGTH, readout = "length")
        val HALF_ANGLE = EditField("size.halfAngle", DEFAULT_HALF_ANGLE, readout = "halfAngle")
    }
}

/** The size field a box face moves: [x] for the X faces, [y] for top and bottom, [z] otherwise. */
private fun axisField(
    faceId: String,
    x: EditField<Double>,
    y: EditField<Double>,
    z: EditField<Double>,
): EditField<Double> = when (faceId) {
    "+x", "-x" -> x
    "+y", "-y" -> y
    else -> z
}

/** An orthonormal pair perpendicular to [normal], right handed so `u × v = normal`. */
internal fun perpendicularBasis(normal: Vector): Pair<Vector, Vector> {
    val reference = if (abs(normal.y) < 0.9) Vector(0, 1, 0) else Vector(1, 0, 0)
    val u = reference.cross(normal).normalize()
    val v = normal.cross(u)
    return u to v
}
