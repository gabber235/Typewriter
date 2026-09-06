package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.nearestBoundaryPoint
import com.typewritermc.region.shape.raycastBoundary
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.entity.BlockDisplay
import org.bukkit.entity.Display
import org.bukkit.entity.Player
import org.bukkit.util.Transformation
import org.joml.Matrix3f
import org.joml.Quaternionf
import org.joml.Vector3f
import java.util.*
import kotlin.math.abs
import kotlin.math.floor

/**
 * The Bukkit world a region's world identifier resolves to. Identifiers are usually world
 * UIDs, but panel authored positions may carry a world name instead.
 */
internal fun resolveBukkitWorld(identifier: String): org.bukkit.World? {
    val byId = runCatching { UUID.fromString(identifier) }.getOrNull()?.let { server.getWorld(it) }
    return byId ?: server.getWorld(identifier)
}

private const val SAFE_LIFT_ATTEMPTS = 8

/**
 * Scans upward from [location], up to [SAFE_LIFT_ATTEMPTS] blocks, for a spot where the feet
 * and head blocks are both passable. Falls back to [location] itself when none is found, so a
 * boundary teleport never lands the player inside a solid wall the region happens to share.
 */
internal fun liftToPassable(location: Location): Location {
    val candidate = location.clone()
    repeat(SAFE_LIFT_ATTEMPTS) {
        val feet = candidate.block
        val head = candidate.clone().add(0.0, 1.0, 0.0).block
        if (feet.isPassable && head.isPassable) return candidate
        candidate.add(0.0, 1.0, 0.0)
    }
    return location
}

/** Where a border teleport should land, and whether [Shape.raycastBoundary] found nothing to aim at. */
internal data class BorderTeleport(val destination: Location, val usedFallback: Boolean)

/**
 * The resize tool's face panel: where its entity stands relative to the outline anchor, and the
 * pose it draws from there.
 */
internal data class FaceHighlight(val anchorOffset: Vector3f, val transformation: Transformation)

/**
 * The point on [shape]'s boundary [eye] is looking at, safely lifted for a teleport. Aiming
 * works from inside the shape too: the view ray still leaves through the stretch of border
 * the eye faces. A ray that never crosses the boundary falls back to the nearest point on
 * it, reported through [BorderTeleport.usedFallback] so a caller can hint at it. `null` when
 * [shape] has no boundary point to fall back to either.
 */
internal fun borderTeleport(world: org.bukkit.World, transform: ResolvedTransform, shape: Shape, eye: Location): BorderTeleport? {
    val localEye = transform.toLocal(Vector(eye.x, eye.y, eye.z))
    val direction = eye.direction
    val ahead = Vector(eye.x + direction.x, eye.y + direction.y, eye.z + direction.z)
    val localDirection = (transform.toLocal(ahead) - localEye).normalize()

    val aimed = shape.raycastBoundary(localEye, localDirection)
    val local = aimed ?: shape.nearestBoundaryPoint(localEye) ?: return null

    val border = transform.toWorld(local)
    val destination = liftToPassable(Location(world, border.x, border.y, border.z, eye.yaw, eye.pitch))
    return BorderTeleport(destination, usedFallback = aimed == null)
}

internal val outlineRenderDistance by snippet(
    "region.outline.render_distance",
    64.0,
    "Max distance in blocks from the player at which a region outline's lines render. Only applies to regions too large to draw whole.",
)

/** A glowing full bright line display visible only to [player], for outline lines, guide lines and handle cubes. */
private fun spawnLineDisplay(player: Player, location: Location, material: Material, teleportTicks: Int): BlockDisplay =
    location.world.spawn(location, BlockDisplay::class.java) { display ->
        display.isPersistent = false
        display.isVisibleByDefault = false
        display.block = material.createBlockData()
        display.brightness = Display.Brightness(15, 15)
        display.isGlowing = true
        display.teleportDuration = teleportTicks
        player.showEntity(plugin, display)
    }

/**
 * Solid line rendering of a region's characteristic edges, built from glowing full bright
 * [BlockDisplay] entities visible only to the editing player. The glow makes the shape
 * readable through terrain, and display interpolation glides the lines along while the
 * region is carried.
 *
 * The outline is cut into [OutlinePiece]s, each anchored where it is drawn. Once the piece
 * count outgrows [MAX_LINE_DISPLAYS], only the pieces near the player are spawned, nearest
 * first.
 *
 * Every method must run on the server main thread.
 */
internal class RegionOutline(private val player: Player) {
    private val lines = HashMap<Int, BlockDisplay>()
    private var pieces: List<OutlinePiece> = emptyList()
    private var placementKey: Int? = null
    private var renderKey: Int? = null
    private var builtScale: Float? = null
    private var anchor: Location? = null
    private var viewer: Location? = null
    private var awaitingChunks = false
    private var glided = false
    private var highlight: BlockDisplay? = null
    private var highlightKey: Any? = null

    /**
     * [emphasis] scales the line thickness and [scale] the whole outline about the anchor;
     * alternating them between two values on a timer pulses the outline, interpolated over
     * [emphasisTicks]. The workspace pulses the aimed at region this way.
     * Neither field moves a piece's display entity: only [shape], [yawDegrees] and
     * [pitchDegrees] do, so a pulse rewrites transformations in place without teleporting.
     *
     * [snap] applies the update without interpolating. Editor history restores are
     * discrete jumps, and lines gliding across them look like a rendering fault.
     */
    fun update(
        anchorLocation: Location,
        yawDegrees: Float,
        pitchDegrees: Float,
        shape: Shape,
        color: Color,
        emphasis: Float = 1f,
        emphasisTicks: Int = INTERPOLATION_TICKS,
        scale: Float = 1f,
        snap: Boolean = false,
        rollDegrees: Float = 0f,
    ) {
        if (anchorLocation.world != player.world) {
            despawn()
            return
        }

        val nextPlacementKey = Objects.hash(shape, yawDegrees, pitchDegrees, rollDegrees)
        val nextRenderKey = Objects.hash(nextPlacementKey, color.color, emphasis, scale)
        val placementChanged = nextPlacementKey != placementKey
        val renderChanged = nextRenderKey != renderKey
        // The pieces depend on the geometry and the scale, not on the color or the emphasis.
        // Rebuilding on those too would cut the whole outline again ten times a second for the region the
        // workspace is pulsing, which is the one with the most pieces to cut.
        val geometryChanged = placementChanged || scale != builtScale
        if (geometryChanged) {
            pieces = buildOutlinePieces(shape, yawDegrees, pitchDegrees, rollDegrees, scale, adaptiveCircleSegments(shape))
            builtScale = scale
        }
        if (renderChanged) {
            placementKey = nextPlacementKey
            renderKey = nextRenderKey
        }

        val eye = player.location
        val previousAnchor = anchor
        val anchorMoved = previousAnchor == null || previousAnchor.world != anchorLocation.world ||
                previousAnchor.distanceSquared(anchorLocation) > MOVE_EPSILON_SQUARED
        val previousViewer = viewer
        val viewerMoved = previousViewer == null || previousViewer.world != eye.world ||
                previousViewer.distanceSquared(eye) > VIEWER_MOVE_EPSILON_SQUARED
        // Line displays are not persistent, so an unloading chunk removes them, and pieces whose
        // chunk was unloaded were skipped. Either way the outline is missing a piece it should
        // have, and nothing else about it will change while the player and the region stand still.
        val incomplete = awaitingChunks || lines.values.any { !it.isValid }
        if (!renderChanged && !anchorMoved && !viewerMoved && !snap && !incomplete) return

        val anchorVector = Vector(anchorLocation.x, anchorLocation.y, anchorLocation.z)
        val visible = visibleOutlinePieces(
            pieces,
            anchorVector,
            Vector(eye.x, eye.y, eye.z),
            outlineRenderDistance,
            MAX_LINE_DISPLAYS,
        )

        val active = visible.mapTo(HashSet()) { it.index }
        val iterator = lines.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (entry.key in active) continue
            entry.value.remove()
            iterator.remove()
        }

        // A placement change or the anchor moving teleports a surviving piece; a render only
        // change (color, emphasis, scale) rewrites its transformation in place without moving
        // the entity, and a player walking past just adds and drops pieces at the window's edge.
        val repositioned = placementChanged || anchorMoved
        val needsUpdate = renderChanged || repositioned || snap
        // A placement change reshuffles which stretch of outline each display index maps to,
        // so interpolating across it visibly rotates every reused line toward an unrelated
        // segment. Those updates snap; only the pulse and the carry glide keep interpolating.
        val discontinuous = placementChanged || snap
        val material = nearestConcrete(color)
        val glow = org.bukkit.Color.fromRGB(color.red, color.green, color.blue)
        val rotation = regionRotation(yawDegrees, pitchDegrees, rollDegrees)
        awaitingChunks = false
        for ((index, piece) in visible) {
            val location = anchorLocation.clone()
                .add(piece.anchorOffset.x, piece.anchorOffset.y, piece.anchorOffset.z)
            // world.spawn force loads its chunk, so a piece whose chunk is unloaded (and
            // thus invisible anyway) is skipped instead of respawned, or it would reload
            // that chunk every tick. It is picked back up once the chunk loads again.
            if (!location.world.isChunkLoaded(location.blockX shr 4, location.blockZ shr 4)) {
                lines.remove(index)?.remove()
                awaitingChunks = true
                continue
            }
            var existing = lines[index]?.takeIf { it.isValid }
            if (existing != null && !needsUpdate) continue
            // The teleport duration is entity metadata and flushes separately from the
            // teleport itself, so an entity that glided last update may apply one more
            // glide to a teleport that must snap. Respawning it at the target is the only
            // ordering proof snap.
            if (existing != null && discontinuous && glided) {
                existing.remove()
                lines.remove(index)
                existing = null
            }
            val line = existing ?: spawnDisplay(location, material).also { lines[index] = it }
            if (existing != null && (repositioned || snap)) {
                line.teleportDuration = if (discontinuous) 0 else INTERPOLATION_TICKS
                line.teleport(location)
            }
            line.block = material.createBlockData()
            line.glowColorOverride = glow
            line.interpolationDelay = 0
            line.interpolationDuration = if (discontinuous || existing == null) 0 else emphasisTicks
            line.transformation =
                lineTransformation(rotation, piece.from, piece.to, LINE_THICKNESS * emphasis)
        }

        if (repositioned || snap) glided = !discontinuous

        if (anchorMoved) {
            // The panel is not moved here: it stands at the face, and the highlight update that
            // follows this one every tick places it against the anchor recorded just below.
            anchor = anchorLocation.clone()
        }
        viewer = eye.clone()
    }

    /**
     * A translucent glowing panel marking the face the resize tool is aiming at. `null`
     * removes the panel. When [snapKey] differs from the previous call's, the panel snaps
     * into place without interpolating, so switching between faces never shows the panel
     * spinning across the region.
     *
     * The entity stands at the face, not at the region's anchor, for the same reason the
     * lines do: a client is only sent a display entity near the entity itself, and on a
     * region wider than the tracking range a panel left on the anchor never arrives.
     *
     * Sub perceptible pose changes are dropped: view dependent faces recompute from the
     * live eye every tick, and restarting the interpolation for float noise makes the panel
     * jitter in place.
     */
    fun updateHighlight(highlight: FaceHighlight?, color: Color, snapKey: Any? = null) {
        if (highlight == null) {
            despawnHighlight()
            return
        }
        val base = anchor ?: return
        val location = base.clone().add(
            highlight.anchorOffset.x.toDouble(),
            highlight.anchorOffset.y.toDouble(),
            highlight.anchorOffset.z.toDouble(),
        )
        // As with the lines: spawning force loads the chunk, and a panel in an unloaded chunk
        // is not visible anyway, so it waits for the chunk instead of dragging it back in.
        if (!location.world.isChunkLoaded(location.blockX shr 4, location.blockZ shr 4)) {
            despawnHighlight()
            return
        }

        val existing = this.highlight?.takeIf { it.isValid }
        val panel = existing ?: spawnHighlight(location).also { this.highlight = it }
        val snap = existing == null || snapKey != highlightKey
        highlightKey = snapKey
        val moved = panel.location.distanceSquared(location) > MOVE_EPSILON_SQUARED
        if (!snap && !moved && withinDeadBand(panel.transformation, highlight.transformation)) return
        if (existing != null && (snap || moved)) {
            panel.teleportDuration = if (snap) 0 else INTERPOLATION_TICKS
            panel.teleport(location)
        }
        panel.glowColorOverride = org.bukkit.Color.fromRGB(color.red, color.green, color.blue)
        panel.interpolationDelay = 0
        panel.interpolationDuration = if (snap) 0 else INTERPOLATION_TICKS
        panel.transformation = highlight.transformation
    }

    private fun despawnHighlight() {
        highlight?.remove()
        highlight = null
        highlightKey = null
    }

    private fun withinDeadBand(current: Transformation, next: Transformation): Boolean =
        current.translation.distanceSquared(next.translation) < DEAD_BAND_DISTANCE_SQUARED &&
                current.scale.distanceSquared(next.scale) < DEAD_BAND_DISTANCE_SQUARED &&
                abs(current.leftRotation.dot(next.leftRotation)) > DEAD_BAND_ROTATION_DOT &&
                abs(current.rightRotation.dot(next.rightRotation)) > DEAD_BAND_ROTATION_DOT

    fun despawn() {
        lines.values.forEach { it.remove() }
        lines.clear()
        pieces = emptyList()
        highlight?.remove()
        highlight = null
        highlightKey = null
        placementKey = null
        renderKey = null
        builtScale = null
        anchor = null
        viewer = null
        awaitingChunks = false
        glided = false
    }

    // Lines spawn with instant teleports; a glide sets the duration only for its own move.
    private fun spawnDisplay(location: Location, material: Material): BlockDisplay =
        spawnLineDisplay(player, location, material, 0)

    // The highlight panel keeps gliding teleports, matching its interpolated pose changes.
    private fun spawnHighlight(location: Location): BlockDisplay =
        spawnLineDisplay(player, location, Material.WHITE_STAINED_GLASS, INTERPOLATION_TICKS)

    companion object {
        private const val LINE_THICKNESS = 0.055f
        private const val INTERPOLATION_TICKS = 2
        private const val MOVE_EPSILON_SQUARED = 0.0004

        // A player has to move a block before the visible window is recomputed.
        private const val VIEWER_MOVE_EPSILON_SQUARED = 1.0

        private const val DEAD_BAND_DISTANCE_SQUARED = 0.0004f

        // A quaternion dot of 0.99985 is about two degrees of rotation.
        private const val DEAD_BAND_ROTATION_DOT = 0.99985f

        /**
         * The rotation [com.typewritermc.region.data.ResolvedTransform.rotateLocalToWorld]
         * applies, as a quaternion: roll about Z, then pitch about X, then Minecraft yaw
         * about Y.
         */
        fun regionRotation(yawDegrees: Float, pitchDegrees: Float, rollDegrees: Float = 0f): Quaternionf =
            Quaternionf()
                .rotationY(-Math.toRadians(yawDegrees.toDouble()).toFloat())
                .rotateX(Math.toRadians(pitchDegrees.toDouble()).toFloat())
                .rotateZ(Math.toRadians(rollDegrees.toDouble()).toFloat())

        /**
         * A display transformation stretching the unit block into a thin box from [from] to
         * [to], both in the region's unrotated local frame, centered on the segment axis.
         */
        fun lineTransformation(rotation: Quaternionf, from: Vector, to: Vector, thickness: Float): Transformation {
            val direction = to - from
            val length = direction.length.toFloat().coerceAtLeast(0.001f)
            // A zero length segment, which a capsule with no half height produces, has no
            // direction to rotate towards: rotationTo would divide by its length and write a
            // NaN quaternion straight into a live display.
            val aim = if (direction.length < 1e-6) Quaternionf() else Quaternionf().rotationTo(
                0f, 0f, 1f,
                direction.x.toFloat(), direction.y.toFloat(), direction.z.toFloat(),
            )
            val left = Quaternionf(rotation).mul(aim)
            val corner = Vector3f(-thickness / 2f, -thickness / 2f, 0f).rotate(left)
            val start = Vector3f(from.x.toFloat(), from.y.toFloat(), from.z.toFloat()).rotate(Quaternionf(rotation))
            return Transformation(
                start.add(corner),
                left,
                Vector3f(thickness, thickness, length),
                Quaternionf(),
            )
        }

        /**
         * A display transformation for a thin panel spanning `2 halfU × 2 halfV` around
         * [center], oriented by the orthonormal local basis ([uBasis], [vBasis], [normal]).
         */
        fun panelTransformation(
            rotation: Quaternionf,
            center: Vector,
            uBasis: Vector,
            vBasis: Vector,
            normal: Vector,
            halfU: Double,
            halfV: Double,
        ): FaceHighlight {
            val orient = Quaternionf().setFromNormalized(
                Matrix3f(
                    uBasis.x.toFloat(), uBasis.y.toFloat(), uBasis.z.toFloat(),
                    vBasis.x.toFloat(), vBasis.y.toFloat(), vBasis.z.toFloat(),
                    normal.x.toFloat(), normal.y.toFloat(), normal.z.toFloat(),
                ),
            )
            val left = Quaternionf(rotation).mul(orient)
            val width = (2 * halfU).toFloat().coerceAtLeast(0.05f)
            val height = (2 * halfV).toFloat().coerceAtLeast(0.05f)
            val corner = Vector3f(-width / 2f, -height / 2f, -PANEL_THICKNESS / 2f).rotate(left)
            val at = Vector3f(center.x.toFloat(), center.y.toFloat(), center.z.toFloat()).rotate(Quaternionf(rotation))
            return FaceHighlight(
                at,
                Transformation(corner, left, Vector3f(width, height, PANEL_THICKNESS), Quaternionf()),
            )
        }

        private const val PANEL_THICKNESS = 0.04f

        private val CONCRETE_COLORS = listOf(
            Material.WHITE_CONCRETE to Triple(207, 213, 214),
            Material.ORANGE_CONCRETE to Triple(224, 97, 1),
            Material.MAGENTA_CONCRETE to Triple(169, 48, 159),
            Material.LIGHT_BLUE_CONCRETE to Triple(36, 137, 199),
            Material.YELLOW_CONCRETE to Triple(241, 175, 21),
            Material.LIME_CONCRETE to Triple(94, 169, 24),
            Material.PINK_CONCRETE to Triple(214, 101, 143),
            Material.GRAY_CONCRETE to Triple(55, 58, 62),
            Material.LIGHT_GRAY_CONCRETE to Triple(125, 125, 115),
            Material.CYAN_CONCRETE to Triple(21, 119, 136),
            Material.PURPLE_CONCRETE to Triple(100, 32, 156),
            Material.BLUE_CONCRETE to Triple(45, 47, 143),
            Material.BROWN_CONCRETE to Triple(96, 60, 32),
            Material.GREEN_CONCRETE to Triple(73, 91, 36),
            Material.RED_CONCRETE to Triple(142, 33, 33),
            Material.BLACK_CONCRETE to Triple(8, 10, 15),
        )

        /** The concrete block whose color sits closest to [color], for the line bodies. */
        fun nearestConcrete(color: Color): Material = CONCRETE_COLORS.minBy { (_, rgb) ->
            val (red, green, blue) = rgb
            val dr = red - color.red
            val dg = green - color.green
            val db = blue - color.blue
            dr * dr + dg * dg + db * db
        }.first
    }
}

/**
 * Glowing guide lines for the transform tools: the move axis and the rotation ring. The
 * same display entity technique as [RegionOutline], but each line is anchored at its own
 * start point relative to [anchorLocation] rather than sharing one entity anchor, so a
 * builder standing at the far end of a large region still receives every entity, and
 * updates snap instead of interpolating, since the guide follows the player's aim rather
 * than the region.
 *
 * Every method must run on the server main thread.
 */
internal class GuideDisplay(private val player: Player) {
    private val lines = mutableListOf<BlockDisplay>()
    private var geometryKey: Int? = null
    private var anchor: Location? = null

    fun update(
        anchorLocation: Location,
        segments: List<Pair<Vector, Vector>>,
        material: Material,
        glow: org.bukkit.Color,
        thickness: Float = GUIDE_THICKNESS,
    ) {
        if (anchorLocation.world != player.world || segments.isEmpty()) {
            despawn()
            return
        }

        // Where the guide is actually drawn, which is not the anchor when it hangs on a far
        // region's boundary. Spawning at the anchor would force that chunk to load, and gating
        // on it hides a guide standing right in front of the player because the region's own
        // center, far behind them, happens to be unloaded.
        val head = segments.first().first
        val spawnLocation = anchorLocation.clone().add(head.x, head.y, head.z)

        // world.spawn force loads its chunk, and a guide in an unloaded chunk is not visible
        // anyway, so it is skipped until the chunk loads.
        if (!spawnLocation.world.isChunkLoaded(spawnLocation.blockX shr 4, spawnLocation.blockZ shr 4)) {
            despawn()
            return
        }

        val key = Objects.hash(segments, material, thickness)
        val moved = anchor.let {
            it == null || it.world != anchorLocation.world ||
                    it.distanceSquared(anchorLocation) > MOVE_EPSILON_SQUARED
        }
        // Line displays are not persistent, so an unloading chunk removes one while the
        // geometry key stays the same. A missing line rebuilds the whole set.
        if (key == geometryKey && !moved && lines.all { it.isValid }) return

        if (lines.any { !it.isValid }) despawn()
        while (lines.size > segments.size) lines.removeAt(lines.size - 1).remove()
        while (lines.size < segments.size) lines.add(spawnLineDisplay(player, spawnLocation, material, 0))

        val identity = Quaternionf()
        for ((index, segment) in segments.withIndex()) {
            val (from, to) = segment
            val line = lines[index]
            line.teleport(anchorLocation.clone().add(from.x, from.y, from.z))
            line.block = material.createBlockData()
            line.glowColorOverride = glow
            line.interpolationDelay = 0
            line.interpolationDuration = 0
            line.transformation =
                RegionOutline.lineTransformation(identity, Vector.ZERO, to - from, thickness)
        }
        geometryKey = key
        anchor = anchorLocation.clone()
    }

    fun despawn() {
        lines.forEach { it.remove() }
        lines.clear()
        geometryKey = null
        anchor = null
    }

    companion object {
        private const val MOVE_EPSILON_SQUARED = 0.0004
    }
}

/** One glowing cube handle: where it sits, what it looks like, and how big it is. */
internal data class HandleSpec(
    val position: Vector,
    val material: Material,
    val glow: org.bukkit.Color,
    val size: Float,
)

/**
 * Small solid glowing cubes marking grabbable spots, like the polygon's corner handles.
 * Each cube's display entity sits at its own handle, so a handle at the far end of a large
 * region still reaches the client. Updates snap instead of interpolating: handles mark
 * discrete spots, and the carried one follows the crosshair where a glide would drag behind.
 *
 * Every method must run on the server main thread.
 */
internal class HandleDisplay(private val player: Player) {
    private val cubes = mutableListOf<BlockDisplay>()
    private var rendered: List<HandleSpec> = emptyList()

    fun update(world: org.bukkit.World, handles: List<HandleSpec>) {
        if (handles.isEmpty() || world != player.world) {
            despawn()
            return
        }
        // Spawning in an unloaded chunk would force it to load, so far handles wait until
        // their chunk is; a cube whose chunk unloads anyway reads as invalid and the set
        // rebuilds without it, which ends the load, unload, respawn cycle.
        val visible = handles.filter {
            world.isChunkLoaded(floor(it.position.x).toInt() shr 4, floor(it.position.z).toInt() shr 4)
        }
        if (visible.isEmpty()) {
            despawn()
            return
        }
        if (cubes.any { !it.isValid }) despawn()
        while (cubes.size > visible.size) cubes.removeAt(cubes.size - 1).remove()
        val previous = rendered
        for ((index, handle) in visible.withIndex()) {
            val location = Location(world, handle.position.x, handle.position.y, handle.position.z)
            if (index >= cubes.size) {
                cubes.add(spawnLineDisplay(player, location, handle.material, 0))
            } else if (previous.getOrNull(index) == handle) {
                continue
            }
            val cube = cubes[index]
            cube.teleport(location)
            cube.block = handle.material.createBlockData()
            cube.glowColorOverride = handle.glow
            cube.interpolationDelay = 0
            cube.interpolationDuration = 0
            cube.transformation = Transformation(
                Vector3f(-handle.size / 2f, -handle.size / 2f, -handle.size / 2f),
                Quaternionf(),
                Vector3f(handle.size, handle.size, handle.size),
                Quaternionf(),
            )
        }
        rendered = visible
    }

    fun despawn() {
        cubes.forEach { it.remove() }
        cubes.clear()
        rendered = emptyList()
    }
}
