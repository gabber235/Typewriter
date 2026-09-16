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
    @Volatile
    protected var primary: CapturedBlock? = null
        private set

    @Volatile
    protected var secondary: CapturedBlock? = null
        private set

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
        primary = block
        if (secondary?.world != block.world) secondary = null
    }

    private fun markSecondary(block: CapturedBlock) = mark(secondaryLabel, 1.15f, block) {
        secondary = block
        if (primary?.world != block.world) primary = null
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
            primary = markedPrimary
            secondary = markedSecondary
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

    protected fun updateOriginFromCapture(world: World, anchor: Vector) {
        resetResizeShift()
        updateWorkingOrigin(originMovedTo(world, anchor.x.round(2), anchor.y.round(2), anchor.z.round(2)))
    }

    final override fun collectState(state: MutableMap<String, Any?>) {
        state[KEY_PRIMARY] = primary
        state[KEY_SECONDARY] = secondary
        collectSizeState(state)
    }

    final override fun restoreStateValue(key: String, value: Any?) {
        when (key) {
            KEY_PRIMARY -> primary = value as? CapturedBlock
            KEY_SECONDARY -> secondary = value as? CapturedBlock
            else -> restoreSizeValue(key, value)
        }
    }

    /** The mode's working size values, captured alongside the marks in undo history. */
    protected open fun collectSizeState(state: MutableMap<String, Any?>) {}

    protected open fun restoreSizeValue(key: String, value: Any?) {}

    private companion object {
        const val KEY_PRIMARY = "marks.primary"
        const val KEY_SECONDARY = "marks.secondary"
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
    private val size by lazy {
        val shape = editedShape<CuboidShape>()
        WorkingSize(shape?.halfX ?: 1.0, shape?.halfY ?: 1.0, shape?.halfZ ?: 1.0)
    }

    override fun workingShape(): Shape = CuboidShape(size.x, size.y, size.z)

    override fun hologramSizeLine(): String = "<#A9B2C3>half <white>${size.x} × ${size.y} × ${size.z}"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> = boxFaces(size.x, size.y, size.z)

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult {
            val (current, field) = when (face.id) {
                "+x", "-x" -> size.x to "halfX"
                "+y", "-y" -> size.y to "halfY"
                else -> size.z to "halfZ"
            }
            val newHalf = (current + delta / 2).coerceAtLeast(MIN_EXTENT).round(2)
            val applied = (newHalf - current) * 2
            if (applied == 0.0) return noResize("The ${face.label}", delta)
            if (!shiftResizeAnchor(face.normal, applied / 2)) {
                return ResizeResult("<red>The origin is bound to a variable, the face cannot move.", changed = false)
            }

            when (face.id) {
                "+x", "-x" -> size.x = newHalf
                "+y", "-y" -> size.y = newHalf
                else -> size.z = newHalf
            }
            restageSizeFields()
            return ResizeResult("<gold>${face.label} <white>half $newHalf")
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val box = BlockBox.spanning(a, b)
        updateOriginFromCapture(a.world, box.center)
        resetWorkingRotation()
        size.x = box.halfX
        size.y = box.halfY
        size.z = box.halfZ
        restageSizeFields()
        return true
    }

    override fun collectSizeState(state: MutableMap<String, Any?>) {
        state["size.halfX"] = size.x
        state["size.halfY"] = size.y
        state["size.halfZ"] = size.z
    }

    override fun restoreSizeValue(key: String, value: Any?) {
        when (key) {
            "size.halfX" -> size.x = value as? Double ?: size.x
            "size.halfY" -> size.y = value as? Double ?: size.y
            "size.halfZ" -> size.z = value as? Double ?: size.z
        }
    }

    override fun restageSizeFields() {
        val shape = editedShape<CuboidShape>()
        restageShapeField("halfX", size.x, shape?.halfX)
        restageShapeField("halfY", size.y, shape?.halfY)
        restageShapeField("halfZ", size.z, shape?.halfZ)
    }
}

/** The player marks the center and a point on the boundary. */
class SphereRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "sphere", "the center", "a boundary point") {
    private val size by lazy {
        WorkingValue(editedShape<SphereShape>()?.radius ?: 1.0)
    }

    override fun workingShape(): Shape = SphereShape(size.value)

    override fun hologramSizeLine(): String = "<#A9B2C3>radius <white>${size.value}"

    override fun supportsRotation(): Boolean = false

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> {
            val direction = localEye.takeIf { it.length > Vector.EPSILON }?.normalize() ?: Vector(1, 0, 0)
            val (uBasis, vBasis) = perpendicularBasis(direction)
            return listOf(
                RegionFace("surface", "surface", direction * size.value, direction, uBasis, vBasis, 0.75, 0.75),
            )
        }

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult {
            val radius = (size.value + delta).coerceAtLeast(MIN_EXTENT).round(2)
            if (radius == size.value && delta != 0.0) return noResize("The sphere", delta)
            size.value = radius
            restageSizeFields()
            return ResizeResult("<gold>Radius <white>$radius")
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        updateOriginFromCapture(a.world, a.center)
        size.value = a.center.distance(b.center).round(2).coerceAtLeast(MIN_EXTENT)
        restageSizeFields()
        return true
    }

    override fun collectSizeState(state: MutableMap<String, Any?>) {
        state["size.radius"] = size.value
    }

    override fun restoreSizeValue(key: String, value: Any?) {
        if (key == "size.radius") size.value = value as? Double ?: size.value
    }

    override fun restageSizeFields() {
        restageShapeField("radius", size.value, editedShape<SphereShape>()?.radius)
    }
}

/** The player marks two corners of a box. The ellipsoid is inscribed in that box. */
class EllipsoidRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "ellipsoid", "corner A", "corner B") {
    private val size by lazy {
        val shape = editedShape<EllipsoidShape>()
        WorkingSize(shape?.radiusX ?: 1.0, shape?.radiusY ?: 1.0, shape?.radiusZ ?: 1.0)
    }

    override fun workingShape(): Shape = EllipsoidShape(size.x, size.y, size.z)

    override fun hologramSizeLine(): String = "<#A9B2C3>radii <white>${size.x} × ${size.y} × ${size.z}"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> = listOf(
            RegionFace(
                "+x",
                "+X cap",
                Vector(size.x, 0.0, 0.0),
                Vector(1, 0, 0),
                Vector(0, 1, 0),
                Vector(0, 0, 1),
                size.y * 0.5,
                size.z * 0.5
            ),
            RegionFace(
                "-x",
                "-X cap",
                Vector(-size.x, 0.0, 0.0),
                Vector(-1, 0, 0),
                Vector(0, 0, 1),
                Vector(0, 1, 0),
                size.z * 0.5,
                size.y * 0.5
            ),
            RegionFace(
                "+y",
                "top cap",
                Vector(0.0, size.y, 0.0),
                Vector(0, 1, 0),
                Vector(0, 0, 1),
                Vector(1, 0, 0),
                size.z * 0.5,
                size.x * 0.5
            ),
            RegionFace(
                "-y",
                "bottom cap",
                Vector(0.0, -size.y, 0.0),
                Vector(0, -1, 0),
                Vector(1, 0, 0),
                Vector(0, 0, 1),
                size.x * 0.5,
                size.z * 0.5
            ),
            RegionFace(
                "+z",
                "+Z cap",
                Vector(0.0, 0.0, size.z),
                Vector(0, 0, 1),
                Vector(1, 0, 0),
                Vector(0, 1, 0),
                size.x * 0.5,
                size.y * 0.5
            ),
            RegionFace(
                "-z",
                "-Z cap",
                Vector(0.0, 0.0, -size.z),
                Vector(0, 0, -1),
                Vector(0, 1, 0),
                Vector(1, 0, 0),
                size.y * 0.5,
                size.x * 0.5
            ),
        )

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult {
            val (current, field) = when (face.id) {
                "+x", "-x" -> size.x to "radiusX"
                "+y", "-y" -> size.y to "radiusY"
                else -> size.z to "radiusZ"
            }
            val newRadius = (current + delta / 2).coerceAtLeast(MIN_EXTENT).round(2)
            val applied = (newRadius - current) * 2
            if (applied == 0.0) return noResize("The ${face.label}", delta)
            if (!shiftResizeAnchor(face.normal, applied / 2)) {
                return ResizeResult("<red>The origin is bound to a variable, the cap cannot move.", changed = false)
            }

            when (face.id) {
                "+x", "-x" -> size.x = newRadius
                "+y", "-y" -> size.y = newRadius
                else -> size.z = newRadius
            }
            restageSizeFields()
            return ResizeResult("<gold>${face.label} <white>radius $newRadius")
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val box = BlockBox.spanning(a, b)
        updateOriginFromCapture(a.world, box.center)
        resetWorkingRotation()
        size.x = box.halfX.coerceAtLeast(MIN_EXTENT)
        size.y = box.halfY.coerceAtLeast(MIN_EXTENT)
        size.z = box.halfZ.coerceAtLeast(MIN_EXTENT)
        restageSizeFields()
        return true
    }

    override fun collectSizeState(state: MutableMap<String, Any?>) {
        state["size.radiusX"] = size.x
        state["size.radiusY"] = size.y
        state["size.radiusZ"] = size.z
    }

    override fun restoreSizeValue(key: String, value: Any?) {
        when (key) {
            "size.radiusX" -> size.x = value as? Double ?: size.x
            "size.radiusY" -> size.y = value as? Double ?: size.y
            "size.radiusZ" -> size.z = value as? Double ?: size.z
        }
    }

    override fun restageSizeFields() {
        val shape = editedShape<EllipsoidShape>()
        restageShapeField("radiusX", size.x, shape?.radiusX)
        restageShapeField("radiusY", size.y, shape?.radiusY)
        restageShapeField("radiusZ", size.z, shape?.radiusZ)
    }
}

/**
 * The player marks two corners of a box. The capsule is inscribed in that box: the radius
 * comes from the wider horizontal half extent and the cylinder half height is the vertical
 * space left after the two hemispheres.
 */
class CapsuleRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "capsule", "corner A", "corner B") {
    private val size by lazy {
        val shape = editedShape<CapsuleShape>()
        WorkingCapsule(shape?.radius ?: 1.0, shape?.halfHeight ?: 1.0)
    }

    override fun workingShape(): Shape = CapsuleShape(size.radius, size.halfHeight)

    override fun hologramSizeLine(): String =
        "<#A9B2C3>radius <white>${size.radius}</white> <#A9B2C3>half height <white>${size.halfHeight}"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> {
            val top = size.halfHeight + size.radius
            val lateral = Vector(localEye.x, 0.0, localEye.z)
            val sideDirection = lateral.takeIf { it.length > Vector.EPSILON }?.normalize() ?: Vector(1, 0, 0)
            val sideCenter =
                sideDirection * size.radius + Vector(0.0, localEye.y.coerceIn(-size.halfHeight, size.halfHeight), 0.0)
            val sideU = Vector(0, 1, 0).cross(sideDirection)
            return listOf(
                RegionFace(
                    "+y",
                    "top cap",
                    Vector(0.0, top, 0.0),
                    Vector(0, 1, 0),
                    Vector(0, 0, 1),
                    Vector(1, 0, 0),
                    size.radius * 0.6,
                    size.radius * 0.6
                ),
                RegionFace(
                    "-y",
                    "bottom cap",
                    Vector(0.0, -top, 0.0),
                    Vector(0, -1, 0),
                    Vector(1, 0, 0),
                    Vector(0, 0, 1),
                    size.radius * 0.6,
                    size.radius * 0.6
                ),
                RegionFace(
                    "side",
                    "side",
                    sideCenter,
                    sideDirection,
                    sideU,
                    Vector(0, 1, 0),
                    size.radius * 0.6,
                    size.halfHeight + size.radius * 0.4
                ),
            )
        }

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult = when (face.id) {
            "side" -> {
                val radius = (size.radius + delta).coerceAtLeast(MIN_EXTENT).round(2)
                if (radius == size.radius && delta != 0.0) {
                    noResize("The capsule", delta)
                } else {
                    size.radius = radius
                    restageSizeFields()
                    ResizeResult("<gold>Radius <white>$radius")
                }
            }

            else -> {
                val current = size.halfHeight
                val newHalf = (current + delta / 2).coerceAtLeast(0.0).round(2)
                val applied = (newHalf - current) * 2
                if (applied == 0.0) {
                    ResizeResult("<red>The ${face.label} cannot move further.", changed = false)
                } else if (!shiftResizeAnchor(face.normal, applied / 2)) {
                    ResizeResult("<red>The origin is bound to a variable, the cap cannot move.", changed = false)
                } else {
                    size.halfHeight = newHalf
                    restageSizeFields()
                    ResizeResult("<gold>${face.label} <white>half height $newHalf")
                }
            }
        }
    }

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val box = BlockBox.spanning(a, b)
        updateOriginFromCapture(a.world, box.center)
        resetWorkingRotation()
        size.radius = max(box.halfX, box.halfZ).coerceAtLeast(MIN_EXTENT).round(2)
        size.halfHeight = (box.halfY - size.radius).coerceAtLeast(0.0).round(2)
        restageSizeFields()
        return true
    }

    override fun collectSizeState(state: MutableMap<String, Any?>) {
        state["size.radius"] = size.radius
        state["size.halfHeight"] = size.halfHeight
    }

    override fun restoreSizeValue(key: String, value: Any?) {
        when (key) {
            "size.radius" -> size.radius = value as? Double ?: size.radius
            "size.halfHeight" -> size.halfHeight = value as? Double ?: size.halfHeight
        }
    }

    override fun restageSizeFields() {
        val shape = editedShape<CapsuleShape>()
        restageShapeField("radius", size.radius, shape?.radius)
        restageShapeField("halfHeight", size.halfHeight, shape?.halfHeight)
    }
}

/**
 * The player marks the apex and a point the cone aims at. The half angle keeps the entry's
 * current value.
 */
class ConeRegionContentMode(context: ContentContext, player: Player) :
    TwoPointRegionContentMode(context, player, "cone", "the apex", "the target") {
    private val size by lazy {
        val shape = editedShape<ConeShape>()
        // Seeded exactly as the entry holds it. Rounding a stored angle into the tool's own range
        // here would show the builder a cone that is not theirs, and save that back the moment
        // they applied anything.
        WorkingCone(shape?.length ?: 8.0, shape?.halfAngleDegrees ?: DEFAULT_HALF_ANGLE)
    }

    override fun workingShape(): Shape = ConeShape(size.length, size.halfAngleDegrees)

    override fun hologramSizeLine(): String =
        "<#A9B2C3>length <white>${size.length}</white> <#A9B2C3>half angle <white>${size.halfAngleDegrees}°"

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> {
            val halfAngle = Math.toRadians(size.halfAngleDegrees)
            val rimRadius = size.length * sin(halfAngle)
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
                    Vector(0.0, 0.0, size.length),
                    Vector(0, 0, 1),
                    Vector(1, 0, 0),
                    Vector(0, 1, 0),
                    rimRadius * 0.7,
                    rimRadius * 0.7
                ),
                RegionFace(
                    "side", "side",
                    lateralDirection * (size.length * 0.6),
                    lateralNormal,
                    lateralU,
                    lateralNormal.cross(lateralU),
                    0.8,
                    size.length * 0.35,
                ),
                RegionFace("apex", "apex", Vector.ZERO, Vector(0, 0, -1), Vector(0, 1, 0), Vector(1, 0, 0), 0.5, 0.5),
            )
        }

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult = when (face.id) {
            "base" -> {
                val length = (size.length + delta).coerceAtLeast(1.0).round(2)
                if (length == size.length && delta != 0.0) {
                    noResize("The cone", delta)
                } else {
                    size.length = length
                    restageSizeFields()
                    ResizeResult("<gold>Length <white>$length")
                }
            }

            "side" -> {
                val halfAngle = (size.halfAngleDegrees + delta * DEGREES_PER_BLOCK).coerceIn(1.0, 89.0).round(2)
                if (halfAngle == size.halfAngleDegrees && delta != 0.0) {
                    ResizeResult("<red>The half angle is at its limit.", changed = false)
                } else {
                    size.halfAngleDegrees = halfAngle
                    restageSizeFields()
                    ResizeResult("<gold>Half angle <white>$halfAngle°")
                }
            }

            else -> {
                val length = (size.length + delta).coerceAtLeast(1.0).round(2)
                val applied = length - size.length
                if (applied == 0.0) {
                    ResizeResult("<red>The apex cannot move further.", changed = false)
                } else if (!shiftResizeAnchor(Vector(0, 0, -1), applied)) {
                    ResizeResult("<red>The origin is bound to a variable, the apex cannot move.", changed = false)
                } else {
                    size.length = length
                    restageSizeFields()
                    ResizeResult("<gold>Apex moved, length <white>$length")
                }
            }
        }
    }

    override val capturesRotation: Boolean = true

    override fun applyCapture(a: CapturedBlock, b: CapturedBlock): Boolean {
        val aim = aim(a, b) ?: return false
        updateOriginFromCapture(a.world, a.center)
        updateWorkingYaw(aim.yawDegrees)
        updateWorkingPitch(aim.pitchDegrees)
        size.length = aim.length
        restageSizeFields()
        return true
    }

    override fun collectSizeState(state: MutableMap<String, Any?>) {
        state["size.length"] = size.length
        state["size.halfAngle"] = size.halfAngleDegrees
    }

    override fun restoreSizeValue(key: String, value: Any?) {
        when (key) {
            "size.length" -> size.length = value as? Double ?: size.length
            "size.halfAngle" -> size.halfAngleDegrees = value as? Double ?: size.halfAngleDegrees
        }
    }

    override fun restageSizeFields() {
        val shape = editedShape<ConeShape>()
        restageShapeField("length", size.length, shape?.length)
        restageShapeField("halfAngleDegrees", size.halfAngleDegrees, shape?.halfAngleDegrees)
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
        val length = sqrt(dx * dx + dy * dy + dz * dz)
        if (length < MIN_EXTENT) return null

        val yaw = Math.toDegrees(atan2(-dx, dz)).toFloat().round(2)
        val pitch = Math.toDegrees(asin(-dy / length)).toFloat().round(2)
        return ConeAim(length.round(2), yaw, pitch)
    }

    private data class ConeAim(val length: Double, val yawDegrees: Float, val pitchDegrees: Float)

    companion object {
        private const val DEFAULT_HALF_ANGLE = 30.0
        private const val DEGREES_PER_BLOCK = 5.0
    }
}

/** An orthonormal pair perpendicular to [normal], right handed so `u × v = normal`. */
internal fun perpendicularBasis(normal: Vector): Pair<Vector, Vector> {
    val reference = if (abs(normal.y) < 0.9) Vector(0, 1, 0) else Vector(1, 0, 0)
    val u = reference.cross(normal).normalize()
    val v = normal.cross(u)
    return u to v
}

private class WorkingSize(var x: Double, var y: Double, var z: Double)

private class WorkingValue(var value: Double)

private class WorkingCapsule(var radius: Double, var halfHeight: Double)

private class WorkingCone(var length: Double, var halfAngleDegrees: Double)
