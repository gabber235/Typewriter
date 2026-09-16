package com.typewritermc.region.content

import com.google.gson.reflect.TypeToken
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.components.ItemComponent
import com.typewritermc.engine.paper.content.components.ItemInteractionType
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.round
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.PolygonShape
import kotlinx.coroutines.Dispatchers
import org.bukkit.FluidCollisionMode
import org.bukkit.GameMode
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.Sound
import org.bukkit.entity.Player
import java.util.concurrent.CopyOnWriteArrayList

/**
 * The player walks the outline and marks blocks along it. The moment three marks exist,
 * the outline derives into the working model (the centroid becomes `origin`, the prism
 * bottom sits at the lowest mark) and the marks turn into corner handles: from then on the
 * vertex list is the only outline model, shared with the resize tool's wall drags, so
 * nothing ever snaps back to the original marks.
 *
 * From then on each click keeps one meaning: left click adds a corner on the nearest
 * wall, right click removes the corner under the crosshair, and F turns the hovered
 * corner into an explicit selection. The selected corner shows a glowing push axis that
 * follows the way the player faces: left click pushes it along the axis, right click
 * pulls it back, sneak scroll slides it finely, sneak right click picks it up into a
 * carry that follows the crosshair, and F lets go. A spectator only has right click, so
 * it adds at the occupied block and sneak right click removes the hovered corner, while
 * the locked keys nudge the hovered or pinned corner the way the resize tool drives
 * faces.
 */
class PolygonRegionContentMode(context: ContentContext, player: Player) : RegionContentMode(context, player) {
    private val points = CopyOnWriteArrayList<CapturedBlock>()

    @Volatile
    private var hoveredIndex: Int? = null

    @Volatile
    private var selectedIndex: Int? = null

    @Volatile
    private var carriedIndex: Int? = null

    @Volatile
    private var pinnedCornerIndex: Int? = null

    @Volatile
    private var carryPointDistance = 8.0
    private var carryPointBase: Map<String, Any?>? = null

    private val handles = HandleDisplay(player)
    private val edgeHighlight = GuideDisplay(player)
    private val pointAxis = GuideDisplay(player)

    private val working by lazy {
        val shape = editedShape<PolygonShape>()
        // Seeded exactly as the entry holds it. A prism thinner than the resize step is a legal
        // thing to build on the panel, and rounding it up here would show the builder a region
        // that is not theirs and save that back the moment they applied anything.
        PolygonWorking(CopyOnWriteArrayList(shape?.points.orEmpty()), shape?.halfHeight ?: DEFAULT_HALF_HEIGHT)
    }

    private fun captured(): Boolean = working.points.size >= MIN_POINTS

    override fun workingShape(): PolygonShape? {
        if (!captured()) return null
        return PolygonShape(working.points.toList(), working.halfHeight)
    }

    override fun hologramSizeLine(): String {
        val count = if (captured()) working.points.size else points.size
        return "<#A9B2C3><white>$count</white> points <#A9B2C3>half height <white>${working.halfHeight}"
    }

    override fun faceSpec() = object : FaceSpec {
        override fun faces(localEye: Vector): List<RegionFace> {
            if (!captured()) return emptyList()
            val halfHeight = working.halfHeight
            val outline = working.points
            val boundsX = outline.maxOf { kotlin.math.abs(it.x) }
            val boundsZ = outline.maxOf { kotlin.math.abs(it.z) }
            val shape = PolygonShape(outline.toList(), halfHeight)

            val faces = mutableListOf(
                RegionFace(
                    "+y",
                    "top face",
                    Vector(0.0, halfHeight, 0.0),
                    Vector(0, 1, 0),
                    Vector(0, 0, 1),
                    Vector(1, 0, 0),
                    boundsZ * 0.6,
                    boundsX * 0.6
                ),
                RegionFace(
                    "-y",
                    "bottom face",
                    Vector(0.0, -halfHeight, 0.0),
                    Vector(0, -1, 0),
                    Vector(1, 0, 0),
                    Vector(0, 0, 1),
                    boundsX * 0.6,
                    boundsZ * 0.6
                ),
            )
            for (index in outline.indices) {
                val a = outline[index]
                val b = outline[(index + 1) % outline.size]
                val edge = Vector(b.x - a.x, 0.0, b.z - a.z)
                if (edge.length < Vector.EPSILON) continue
                val mid = Vector((a.x + b.x) / 2, 0.0, (a.z + b.z) / 2)
                val candidate = Vector(edge.z, 0.0, -edge.x).normalize()
                val probe = mid - candidate * PROBE_DISTANCE
                val normal = if (shape.contains(Vector(probe.x, 0.0, probe.z))) candidate else candidate * -1.0
                faces += RegionFace(
                    "edge$index",
                    "wall ${index + 1}",
                    mid,
                    normal,
                    Vector(0, 1, 0).cross(normal),
                    Vector(0, 1, 0),
                    edge.length / 2,
                    halfHeight,
                )
            }
            return faces
        }

        override fun moveFace(face: RegionFace, delta: Double): ResizeResult {
            if (face.id == "+y" || face.id == "-y") {
                val current = working.halfHeight
                val newHalf = (current + delta / 2).coerceAtLeast(MIN_HALF_HEIGHT).round(2)
                val applied = (newHalf - current) * 2
                // A region already thinner than the tool's own minimum would otherwise answer a
                // pull inward by jumping outward to that minimum, anchor and all.
                if (applied == 0.0 || applied * delta < 0.0) {
                    return ResizeResult("<red>The ${face.label} cannot move further.", changed = false)
                }
                if (!shiftResizeAnchor(face.normal, applied / 2)) {
                    return ResizeResult(
                        "<red>The origin is bound to a variable, the face cannot move.",
                        changed = false
                    )
                }
                working.halfHeight = newHalf
                restageSizeFields()
                return ResizeResult("<gold>${face.label} <white>half height $newHalf")
            }

            val index = face.id.removePrefix("edge").toIntOrNull()
                ?: return ResizeResult("<red>Unknown face.", changed = false)
            if (index >= working.points.size) return ResizeResult("<red>The wall no longer exists.", changed = false)
            val next = (index + 1) % working.points.size
            val shift = face.normal * delta
            working.points[index] = (working.points[index] + shift).rounded()
            working.points[next] = (working.points[next] + shift).rounded()
            stagePoints()
            return ResizeResult(
                "<gold>${face.label} <white>moved ${if (delta >= 0) "out" else "in"} ${
                    kotlin.math.abs(
                        delta
                    ).round(2)
                }"
            )
        }
    }

    override fun wandComponent(): ItemComponent = RegionWandComponent(
        title = "<gold><bold>Polygon Wand",
        loreText = """
            |
            |<line> <gray>Walk the outline left-clicking blocks for the first $MIN_POINTS points.
            |<line> <gray>Then left-click adds a corner on the nearest wall,
            |<line> <gray>right-click removes the corner you aim at.
            |<line> <gray><white>F</white> selects the aimed corner: left-click pushes it $MOVE_STEP,
            |<line> <gray>right-click pulls it back, sneak scroll slides it $MOVE_FINE_STEP,
            |<line> <gray>sneak right-click picks it up to carry, <white>F</white> lets go.
            |<line> <gray>Press <white>Q</white> to undo, sneak <white>Q</white> to redo.
        """.trimMargin(),
        onDrop = ::dropOrCancelGrab,
        onSwap = ::toggleSelection,
    ) { interaction, block ->
        val spectator = player.gameMode == GameMode.SPECTATOR
        when (interaction.type) {
            ItemInteractionType.LEFT_CLICK, ItemInteractionType.SHIFT_LEFT_CLICK ->
                if (!spectator) primaryAction(block)

            ItemInteractionType.RIGHT_CLICK, ItemInteractionType.SHIFT_RIGHT_CLICK -> {
                val sneak = interaction.type == ItemInteractionType.SHIFT_RIGHT_CLICK
                if (spectator) spectatorClick(block, sneak) else secondaryAction(sneak)
            }

            else -> return@RegionWandComponent
        }
    }

    private fun primaryAction(block: CapturedBlock) {
        if (carriedIndex != null) {
            cancelPointCarry()
            return
        }
        if (!captured()) {
            addPoint(block)
            return
        }
        val selected = selectedIndex
        if (selected != null) {
            nudgePoint(selected, MOVE_STEP)
            return
        }
        insertVertex(block)
    }

    private fun toggleSelection() {
        if (carriedIndex != null) {
            refuse(modeGestureRefusal())
            return
        }
        val hovered = hoveredIndex
        val selected = selectedIndex
        when {
            hovered != null && hovered != selected -> {
                selectedIndex = hovered
                player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.5f, 1.4f)
                player.sendActionBar(
                    ("<gold>Selected point <white>${hovered + 1}</white>. <gray>Left-click pushes, right-click pulls, " +
                            "sneak right-click carries, <white>F</white> lets go.").asMini(),
                )
            }

            selected != null -> {
                selectedIndex = null
                player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.3f, 1.0f)
                player.sendActionBar("<gray>Deselected.".asMini())
            }

            else -> player.sendActionBar("<gray>Aim at a corner and press <white>F</white> to select it.".asMini())
        }
    }

    private fun secondaryAction(sneak: Boolean) {
        if (carriedIndex != null) {
            placePointCarry()
            return
        }
        if (!captured()) {
            removeLastPoint()
            return
        }
        val selected = selectedIndex
        if (selected != null) {
            if (sneak) grabPoint(selected) else nudgePoint(selected, -MOVE_STEP)
            return
        }
        val hovered = hoveredIndex
        if (hovered == null) {
            player.sendActionBar("<gray>Aim at a corner to remove it, or press <white>F</white> to select one.".asMini())
            return
        }
        removePointAt(hovered)
    }

    /**
     * The spectator wand click, the only button a spectator client sends: right click adds
     * at the occupied block, sneak right click removes the hovered corner, mirroring the
     * resize tool's aim driven targeting.
     */
    private fun spectatorClick(block: CapturedBlock, sneak: Boolean) {
        // Putting a carried corner down comes first, exactly as on foot. A spectator has no other
        // button to end the carry with: left click, drop and swap are never sent, so without this
        // the corner stays glued to the crosshair and every other tool refuses to run.
        if (carriedIndex != null) {
            placePointCarry()
            return
        }
        if (!sneak) {
            addPoint(block)
            return
        }
        if (!captured()) {
            removeLastPoint()
            return
        }
        val hovered = hoveredIndex
        if (hovered == null) {
            player.sendActionBar("<gray>Aim at a corner to remove it.".asMini())
            return
        }
        removePointAt(hovered)
    }

    /** The sprint and sneak chord does nothing here; the hint names the gesture that does. */
    override fun spectatorSecondary(block: CapturedBlock) {
        player.sendActionBar("<gray>Sneak <white>right-click</white> removes the aimed corner.".asMini())
    }

    override fun spectatorHint(): String =
        "<white>right-click</white> adds a corner at your block, sneak <white>right-click</white> " +
                "removes the aimed one, <white>jump + sneak</white> locks for key nudging"

    override fun lockedWandHint(): String =
        "aim at a corner: <white>WASD</white> nudge it $MOVE_STEP, <white>space</white> pins it, " +
                "<white>jump + sneak</white> releases"

    override fun usesSelectionCube(): Boolean = false

    override fun onSpectatorLockReleased() {
        pinnedCornerIndex = null
    }

    /**
     * The locked spectator keys drive corners the way the resize tool drives faces: the
     * aim picks the corner, WASD nudge it along the yaw cardinals, and space pins it so
     * aim slip cannot switch targets mid adjustment.
     */
    override fun wandSpectatorKey(key: SpectatorKey) {
        if (!captured()) {
            player.sendActionBar("<gray>Fly onto a spot and <white>right-click</white> to add outline points.".asMini())
            return
        }
        if (key == SpectatorKey.UP) {
            toggleCornerPin()
            return
        }
        val direction = spectatorKeyDirection(key, player.location.yaw)
        if (direction == null || direction.y != 0.0) {
            player.sendActionBar("<gray>WASD nudge the aimed corner, <white>space</white> pins it.".asMini())
            return
        }
        val target = spectatorTargetCorner() ?: run {
            refuse("<red>Aim at a corner to nudge it, or pin one with <white>space</white>.")
            return
        }
        slidePointAlong(target, direction, MOVE_STEP, "Point ${target + 1} nudge", coalesce = false)
    }

    /** The corner the locked keys drive: the pinned one, or whichever the aim hovers. */
    private fun spectatorTargetCorner(): Int? =
        retainedIndex(pinnedCornerIndex, working.points.size) ?: hoveredIndex

    private fun toggleCornerPin() {
        if (pinnedCornerIndex != null) {
            pinnedCornerIndex = null
            player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.3f, 1.2f)
            player.sendActionBar("<gray>Corner released. The aim picks corners again.".asMini())
            return
        }
        val hovered = hoveredIndex ?: run {
            refuse("<red>Aim at a corner to pin it first.")
            return
        }
        pinnedCornerIndex = hovered
        player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.3f, 1.6f)
        player.sendActionBar(
            "<gold>Pinned point <white>${hovered + 1}</white>. <gray>WASD keep driving it; <white>space</white> releases.".asMini(),
        )
    }

    private fun dropOrCancelGrab() {
        if (carriedIndex != null) {
            cancelPointCarry()
            return
        }
        undoOrRedoHeldTool()
    }

    override fun modeGestureActive(): Boolean = carriedIndex != null

    override fun cancelModeGesture() = cancelPointCarry()

    override fun finishModeGesture() = placePointCarry()

    override fun modeGestureRefusal(): String = "<red>Place the point down first."

    override fun modeGestureActivity(): String = "is moving a point"

    private fun addPoint(block: CapturedBlock) {
        if (captured()) {
            insertVertex(block)
            return
        }
        // The refusal comes before the mark is taken, not after the third one derives the outline: the
        // capture clears the marks either way, so a refusal there throws away everything the
        // builder walked out.
        if (!placementWritable(rotation = true)) return
        var collinear = false
        val allowed = recorded(EditTool.WAND, "Outline point") {
            if (points.firstOrNull()?.world != block.world) points.clear()
            points.add(block)
            if (points.size < MIN_POINTS) return@recorded true
            // Three marks in a line enclose nothing. Deriving them anyway hands the builder an
            // outline the hologram is happy with and a published region that contains nobody,
            // which the console only mentions after the next publish. The earlier marks are kept,
            // so one more point off the line finishes the capture.
            if (!encloses(capture())) {
                refuse("<red>Those points lie in a straight line. Mark one off the line.")
                points.removeAt(points.lastIndex)
                collinear = true
                return@recorded false
            }
            deriveOutline()
            points.clear()
            true
        }
        if (!allowed || collinear) return
        if (captured()) {
            captureFeedback("<gold>Outline captured with <white>${working.points.size}</white> corners.", 1.4f)
            return
        }
        val pitch = (0.7f + points.size * 0.05f).coerceAtMost(1.8f)
        captureFeedback(
            "<gold>Point <white>${points.size}</white> added <white>(${block.x}, ${block.y}, ${block.z})",
            pitch
        )
    }

    private fun insertVertex(block: CapturedBlock) {
        val transform = workingTransform() ?: run {
            refuse("<red>The origin is bound to a variable, the outline cannot be edited here.")
            return
        }
        if (block.world.identifier != transform.world.identifier) {
            refuse("<red>The outline lives in another world.")
            return
        }
        val local = transform.toLocal(block.center)
        val point = Vector(local.x.round(2), 0.0, local.z.round(2))
        val index = insertionIndexFor(working.points, point)
        val allowed = recorded(EditTool.WAND, "Point ${index + 1} added") {
            working.points.add(index, point)
            // Every index at or above the insertion shifts up, and a pin or selection left
            // pointing at the old number would silently drive the neighbouring corner.
            if (pinnedCornerIndex?.let { it >= index } == true) pinnedCornerIndex = null
            if (selectedIndex?.let { it >= index } == true) selectedIndex = null
            stagePoints()
            true
        }
        if (!allowed) return
        captureFeedback(
            "<gold>Point <white>${index + 1}</white> added on the nearest wall, <white>${working.points.size}</white> corners",
            1.2f,
        )
    }

    private fun nudgePoint(index: Int, distance: Double) {
        slidePoint(index, distance, "Point ${index + 1} nudge", coalesce = false)
    }

    private fun slidePoint(index: Int, distance: Double, label: String, coalesce: Boolean) =
        slidePointAlong(index, cardinalFromYaw(player.location.yaw), distance, label, coalesce)

    private fun slidePointAlong(index: Int, direction: Vector, distance: Double, label: String, coalesce: Boolean) {
        val transform = workingTransform() ?: return
        if (index >= working.points.size) return
        val localShift = transform.toLocal(transform.worldOrigin + direction * distance) -
                transform.toLocal(transform.worldOrigin)
        recorded(EditTool.WAND, label, if (coalesce) SCROLL_COALESCE_MILLIS else 0) {
            val current = working.points[index]
            working.points[index] = Vector(
                (current.x + localShift.x).round(2),
                0.0,
                (current.z + localShift.z).round(2),
            )
            stagePoints()
            val world = transform.toWorld(working.points[index])
            toolFeedback(
                "<gold>Point ${index + 1} <white>${world.x.round(2)}, ${world.z.round(2)}",
                distance >= 0,
            )
            true
        }
    }

    private fun grabPoint(index: Int) {
        if (isFaceGrabbed()) {
            refuse("<red>Keep or put back the grabbed face first.")
            return
        }
        if (isCarryingRegion()) {
            refuse("<red>Place the region down first.")
            return
        }
        val transform = workingTransform() ?: run {
            refuse("<red>The origin is bound to a variable, the outline cannot be edited here.")
            return
        }
        if (index >= working.points.size) return

        carryPointBase = mapOf(KEY_POINTS to working.points.toList())
        carriedIndex = index
        val world = transform.toWorld(working.points[index])
        carryPointDistance = player.eyeLocation
            .distance(Location(player.world, world.x, world.y, world.z))
            .coerceIn(CARRY_MIN_DISTANCE, CARRY_MAX_DISTANCE)
        player.playSound(player.location, Sound.ENTITY_ITEM_FRAME_REMOVE_ITEM, 0.8f, 1.2f)
        player.sendActionBar(
            "<gold>Picked up point <white>${index + 1}</white>. <gray>It follows your crosshair; <white>right-click</white> places it.".asMini(),
        )
    }

    private fun placePointCarry() {
        val index = carriedIndex ?: return
        carriedIndex = null
        val base = carryPointBase
        carryPointBase = null
        val after = mapOf(KEY_POINTS to working.points.toList())
        base?.let { recordGestureEntry(EditTool.WAND, "Point ${index + 1} carry", it, after) }
        stagePoints()
        val world = workingTransform()?.toWorld(working.points.getOrNull(index) ?: Vector.ZERO)
        player.playSound(player.location, Sound.ENTITY_ITEM_FRAME_ADD_ITEM, 0.8f, 1.0f)
        val at = world?.let { " at <white>${it.x.round(2)}, ${it.z.round(2)}</white>" } ?: ""
        player.sendActionBar("<gold>Placed point <white>${index + 1}</white>$at.".asMini())
    }

    private fun cancelPointCarry() {
        if (carriedIndex == null) return
        carriedIndex = null
        carryPointBase?.let(::restoreGestureBase)
        carryPointBase = null
        player.playSound(player.location, Sound.ENTITY_ITEM_FRAME_ROTATE_ITEM, 0.8f, 0.8f)
        player.sendActionBar("<gray>Put the point back where it was.".asMini())
    }

    /**
     * While carried, the point hangs on the player's crosshair: its XZ follows the first
     * block the view ray hits, or floats at the carry distance the scroll adjusts,
     * half grid snapped unless sneaking. Main thread only.
     */
    override fun tickModeGesture() {
        val index = carriedIndex ?: return
        if (index >= working.points.size) {
            carriedIndex = null
            carryPointBase = null
            return
        }
        val transform = workingTransform() ?: return
        if (transform.world.identifier != player.world.uid.toString()) {
            cancelPointCarry()
            return
        }

        val eye = player.eyeLocation
        val direction = eye.direction
        val hit = player.world
            .rayTraceBlocks(eye, direction, carryPointDistance, FluidCollisionMode.NEVER, true)
            ?.hitPosition
        val targetX = hit?.x ?: (eye.x + direction.x * carryPointDistance)
        val targetZ = hit?.z ?: (eye.z + direction.z * carryPointDistance)
        val snap = !player.isSneaking
        fun settle(value: Double): Double = if (snap) snapToHalfGrid(value) else value.round(2)
        val local = transform.toLocal(Vector(settle(targetX), transform.worldOrigin.y, settle(targetZ)))
        working.points[index] = Vector(local.x.round(2), 0.0, local.z.round(2))
        stagePoints()
    }

    override fun onWandScroll(steps: Int): Boolean {
        if (carriedIndex != null) {
            carryPointDistance = (carryPointDistance + steps * CARRY_SCROLL_STEP)
                .coerceIn(CARRY_MIN_DISTANCE, CARRY_MAX_DISTANCE)
            return true
        }
        if (!player.isSneaking) return false
        val selected = selectedIndex ?: return false
        slidePoint(selected, steps * MOVE_FINE_STEP, "Point ${selected + 1} slide", coalesce = true)
        return true
    }

    private fun removePointAt(index: Int) {
        if (working.points.size <= MIN_POINTS) {
            refuse("<red>A polygon needs at least $MIN_POINTS points.")
            return
        }
        val allowed = recorded(EditTool.WAND, "Point ${index + 1} removed") {
            if (index >= working.points.size) return@recorded false
            working.points.removeAt(index)
            stagePoints()
            true
        }
        if (!allowed) return
        selectedIndex = null
        pinnedCornerIndex = null
        captureFeedback("<gold>Removed point <white>${index + 1}</white>, <white>${working.points.size}</white> left", 0.6f)
    }

    private fun removeLastPoint() {
        if (captured()) {
            removePointAt(working.points.size - 1)
            return
        }
        if (points.isEmpty()) {
            refuse("<red>No outline points to remove.")
            return
        }
        val allowed = recorded(EditTool.WAND, "Outline point") {
            points.removeLastOrNull() != null
        }
        if (!allowed) return
        captureFeedback("<gold>Removed the last point, <white>${points.size}</white> left", 0.6f)
    }

    override fun hasCapturedGeometry(): Boolean = captured()

    override fun instruction(): String {
        val carried = carriedIndex
        if (carried != null) {
            return "Carrying point <white>${carried + 1}</white>: it follows your aim, scroll sets the distance, " +
                    "<green>right-click</green> places it, <red>left-click</red> puts it back"
        }
        val selected = selectedIndex
        if (selected != null) {
            return "Point <white>${selected + 1}</white> selected: <red>left-click</red> pushes, " +
                    "<green>right-click</green> pulls, sneak <green>right-click</green> carries, " +
                    "<white>F</white> lets go"
        }
        if (!captured()) {
            return "Walk the outline: <red>left-click</red> blocks to add points (${points.size} of $MIN_POINTS minimum)"
        }
        return "${working.points.size} corners. <red>Left-click</red> adds on the nearest wall, " +
                "<green>right-click</green> removes the aimed corner, <white>F</white> selects it"
    }

    /**
     * Aim based corner hover plus the handle rendering. The whole vertical corner edge
     * hovers, straight through terrain, because outline corners usually sit inside walls.
     * F turns the hover into the sticky selection the click gestures act on; a spectator
     * has no F, so the locked keys act on the hover or the pinned corner directly.
     */
    override fun updateModeOverlays() {
        val previous = hoveredIndex
        val hovered = pickHovered()
        hoveredIndex = hovered
        if (player.gameMode == GameMode.SPECTATOR) {
            selectedIndex = null
        } else {
            pinnedCornerIndex = null
            if (player.inventory.heldItemSlot != WAND_SLOT) selectedIndex = null
        }
        if (hovered != null && hovered != previous) {
            player.playSound(player.location, Sound.UI_BUTTON_CLICK, 0.3f, 1.7f)
        }
        renderHandles()
    }

    private fun pickHovered(): Int? {
        if (carriedIndex != null) return null
        if (isCarryingRegion() || isFaceGrabbed()) return null
        if (!captured()) return null
        val spectator = player.gameMode == GameMode.SPECTATOR
        if (!spectator && player.inventory.heldItemSlot != WAND_SLOT) return null
        val transform = workingTransform() ?: return null
        if (transform.world.identifier != player.world.uid.toString()) return null
        val eye = player.eyeLocation
        val direction = eye.direction
        return pickVertexEdge(
            vertexEdges(transform),
            Vector(eye.x, eye.y, eye.z),
            Vector(direction.x, direction.y, direction.z),
            PICK_RANGE,
            hoveredIndex,
        )
    }

    /** Each corner's vertical edge in the world frame, bottom ring point to top ring point. */
    private fun vertexEdges(transform: ResolvedTransform): List<Pair<Vector, Vector>> =
        working.points.map { point ->
            transform.toWorld(Vector(point.x, -working.halfHeight, point.z)) to
                    transform.toWorld(Vector(point.x, working.halfHeight, point.z))
        }

    private fun renderHandles() {
        val playerWorldId = player.world.uid.toString()
        if (!captured()) {
            val marks = points.filter { it.world.identifier == playerWorldId }
            handles.update(player.world, marks.map { HandleSpec(it.center, normalMaterial(), normalGlow(), HANDLE_SIZE) })
            edgeHighlight.despawn()
            pointAxis.despawn()
            return
        }
        val transform = workingTransform()
        if (transform == null || transform.world.identifier != playerWorldId) {
            handles.despawn()
            edgeHighlight.despawn()
            pointAxis.despawn()
            return
        }
        val edges = vertexEdges(transform)
        val specs = buildList {
            for ((index, edge) in edges.withIndex()) {
                val (material, glow, size) = handleAppearance(index)
                add(HandleSpec(edge.first, material, glow, size))
                add(HandleSpec(edge.second, material, glow, size))
            }
        }
        handles.update(player.world, specs)
        renderPointAxis(edges)

        val highlighted = carriedIndex ?: selectedIndex ?: retainedIndex(pinnedCornerIndex, edges.size)
        if (highlighted == null || highlighted >= edges.size) {
            edgeHighlight.despawn()
            return
        }
        val edge = edges[highlighted]
        edgeHighlight.update(
            Location(player.world, edge.first.x, edge.first.y, edge.first.z),
            listOf(Vector.ZERO to edge.second - edge.first),
            Material.YELLOW_CONCRETE,
            SELECTED_GLOW,
            EDGE_HIGHLIGHT_THICKNESS,
        )
    }

    /**
     * The glowing push axis through the corner the gestures would move: the selection on
     * foot, the hovered or pinned corner for a locked spectator. It follows the way the
     * player faces, colored per world axis like the move guide, with the arrowhead
     * marking the push direction so a step's effect is visible before it happens.
     */
    private fun renderPointAxis(edges: List<Pair<Vector, Vector>>) {
        val spectator = player.gameMode == GameMode.SPECTATOR
        val target = when {
            carriedIndex != null -> null
            spectator -> if (isSpectatorLocked()) spectatorTargetCorner() else null
            player.inventory.heldItemSlot != WAND_SLOT -> null
            else -> selectedIndex
        }
        if (target == null || target >= edges.size) {
            pointAxis.despawn()
            return
        }
        val direction = cardinalFromYaw(player.location.yaw)
        val edge = edges[target]
        val mid = (edge.first + edge.second) * 0.5
        val eye = player.eyeLocation
        val view = (mid + direction * PUSH_AXIS_REACH - Vector(eye.x, eye.y, eye.z))
            .takeIf { it.length > Vector.EPSILON }?.normalize() ?: direction
        val (material, glow) = axisAppearance(direction)
        pointAxis.update(
            Location(player.world, mid.x, mid.y, mid.z),
            pushAxisSegments(direction, view),
            material,
            glow,
        )
    }

    private fun handleAppearance(index: Int): Triple<Material, org.bukkit.Color, Float> = when (index) {
        carriedIndex -> Triple(Material.YELLOW_CONCRETE, SELECTED_GLOW, HANDLE_SELECTED_SIZE)
        selectedIndex -> Triple(Material.YELLOW_CONCRETE, SELECTED_GLOW, HANDLE_SELECTED_SIZE)
        pinnedCornerIndex -> Triple(Material.YELLOW_CONCRETE, SELECTED_GLOW, HANDLE_SELECTED_SIZE)
        hoveredIndex -> Triple(Material.WHITE_CONCRETE, org.bukkit.Color.WHITE, hoverPulseSize())
        else -> Triple(normalMaterial(), normalGlow(), HANDLE_SIZE)
    }

    /**
     * The hovered handle pulses: the size swings on a short sine so the corner the aim
     * would select stands out from the still ones without needing yet another color.
     */
    private fun hoverPulseSize(): Float {
        val phase = System.currentTimeMillis() % HOVER_PULSE_MILLIS / HOVER_PULSE_MILLIS.toDouble()
        return HANDLE_HOVER_SIZE + HOVER_PULSE_AMPLITUDE * kotlin.math.sin(phase * 2.0 * Math.PI).toFloat()
    }

    private fun normalMaterial(): Material = RegionOutline.nearestConcrete(editColor())

    private fun normalGlow(): org.bukkit.Color {
        val color = editColor()
        return org.bukkit.Color.fromRGB(color.red, color.green, color.blue)
    }

    override suspend fun dispose() {
        carriedIndex = null
        carryPointBase = null
        pinnedCornerIndex = null
        super.dispose()
        Dispatchers.Sync.switchContext {
            handles.despawn()
            edgeHighlight.despawn()
            pointAxis.despawn()
        }
    }

    override fun collectState(state: MutableMap<String, Any?>) {
        state[KEY_MARKED] = points.toList()
        state[KEY_POINTS] = working.points.toList()
        state[KEY_HALF_HEIGHT] = working.halfHeight
    }

    override fun restoreStateValue(key: String, value: Any?) {
        when (key) {
            KEY_MARKED -> {
                points.clear()
                (value as? List<*>)?.filterIsInstance<CapturedBlock>()?.let(points::addAll)
            }

            KEY_POINTS -> {
                working.points.clear()
                (value as? List<*>)?.filterIsInstance<Vector>()?.let(working.points::addAll)
                selectedIndex = retainedIndex(selectedIndex, working.points.size)
                pinnedCornerIndex = retainedIndex(pinnedCornerIndex, working.points.size)
                if (retainedIndex(carriedIndex, working.points.size) == null) {
                    carriedIndex = null
                    carryPointBase = null
                }
            }

            KEY_HALF_HEIGHT -> working.halfHeight = value as? Double ?: working.halfHeight
        }
    }

    override fun restageSizeFields() {
        val shape = editedShape<PolygonShape>()
        restageShapeField("points", working.points.toList(), shape?.points, object : TypeToken<List<Vector>>() {}.type)
        restageShapeField("halfHeight", working.halfHeight, shape?.halfHeight)
    }

    private fun stagePoints() {
        restageSizeFields()
    }

    /**
     * The one shot capture transition: the marks become the vertex model. Never runs again
     * after that, so resize edits can never be derived away again.
     */
    private fun deriveOutline() {
        val capture = capture() ?: return
        if (!placementWritable(rotation = true)) return
        resetResizeShift()
        // The captured vertices are world axis offsets from the centroid, and the working
        // transform would rotate them again by the entry's stored yaw. The box captures reset
        // the rotation for the same reason.
        resetWorkingRotation()
        updateWorkingOrigin(originMovedTo(capture.world, capture.origin.x, capture.origin.y, capture.origin.z))
        working.points.clear()
        working.points.addAll(capture.relativePoints)
        stagePoints()
    }

    /**
     * Whether [capture] describes a floor rather than a line or a single point.
     *
     * The height is deliberately not part of the question. A prism with no height is unusable
     * too, but that is a number the builder can see and change, while an outline that encloses
     * nothing fails with nothing visible to correct.
     */
    private fun encloses(capture: PolygonCapture?): Boolean {
        val points = capture?.relativePoints ?: return false
        return PolygonShape(points, halfHeight = 1.0).usable
    }

    private fun capture(): PolygonCapture? {
        val outline = points.toList()
        if (outline.size < MIN_POINTS) return null

        val world = outline.first().world
        val centroidX = (outline.sumOf { it.center.x } / outline.size).round(2)
        val centroidZ = (outline.sumOf { it.center.z } / outline.size).round(2)
        val bottomY = outline.minOf { it.y }.toDouble()
        val halfHeight = working.halfHeight

        val origin = Vector(centroidX, bottomY + halfHeight, centroidZ)
        val relativePoints = outline.map {
            Vector((it.center.x - centroidX).round(2), 0.0, (it.center.z - centroidZ).round(2))
        }
        return PolygonCapture(world, origin, relativePoints, halfHeight)
    }

    private fun Vector.rounded(): Vector = Vector(x.round(2), y.round(2), z.round(2))

    private data class PolygonCapture(
        val world: World,
        val origin: Vector,
        val relativePoints: List<Vector>,
        val halfHeight: Double,
    )

    private class PolygonWorking(val points: MutableList<Vector>, var halfHeight: Double)

    companion object {
        private const val MIN_POINTS = 3
        private const val DEFAULT_HALF_HEIGHT = 2.0
        private const val MIN_HALF_HEIGHT = 0.5
        private const val PROBE_DISTANCE = 0.05
        private const val PICK_RANGE = 32.0
        private const val HANDLE_SIZE = 0.22f
        private const val HANDLE_HOVER_SIZE = 0.28f
        private const val HANDLE_SELECTED_SIZE = 0.32f
        private const val HOVER_PULSE_AMPLITUDE = 0.06f
        private const val HOVER_PULSE_MILLIS = 700L
        private val SELECTED_GLOW = org.bukkit.Color.fromRGB(255, 200, 0)
        private const val EDGE_HIGHLIGHT_THICKNESS = 0.08f
    }
}

private const val KEY_MARKED = "poly.marked"
private const val KEY_POINTS = "poly.points"
private const val KEY_HALF_HEIGHT = "poly.halfHeight"

/** The XZ distance from [point] to the segment [a] to [b], all in the polygon's local frame. */
internal fun pointSegmentDistanceXZ(point: Vector, a: Vector, b: Vector): Double {
    val abx = b.x - a.x
    val abz = b.z - a.z
    val apx = point.x - a.x
    val apz = point.z - a.z
    val lengthSquared = abx * abx + abz * abz
    val s = if (lengthSquared < 1e-12) 0.0 else ((apx * abx + apz * abz) / lengthSquared).coerceIn(0.0, 1.0)
    val dx = apx - abx * s
    val dz = apz - abz * s
    return kotlin.math.sqrt(dx * dx + dz * dz)
}

/**
 * Where a new outline point belongs: after the start vertex of the nearest wall, so a
 * click extends the wall the builder is looking at instead of appending at the end and
 * crossing the polygon.
 */
internal fun insertionIndexFor(points: List<Vector>, point: Vector): Int {
    if (points.size < 2) return points.size
    var bestIndex = points.size
    var bestDistance = Double.MAX_VALUE
    for (index in points.indices) {
        val a = points[index]
        val b = points[(index + 1) % points.size]
        val distance = pointSegmentDistanceXZ(point, a, b)
        if (distance < bestDistance) {
            bestDistance = distance
            bestIndex = index + 1
        }
    }
    return bestIndex
}

/** [index] when it still points into a list of [size] entries, else `null`. */
internal fun retainedIndex(index: Int?, size: Int): Int? = index?.takeIf { it in 0 until size }
