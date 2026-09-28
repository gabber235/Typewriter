package com.typewritermc.region.entries.definition

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.content.EllipsoidRegionContentMode
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.EllipsoidShape
import com.typewritermc.region.shape.Shape
import java.util.Optional

@Entry("ellipsoid_region_definition", "A triaxial ellipsoid region", Colors.PURPLE, "mdi:ellipse-outline")
/**
 * Defines an ellipsoidal region with independent radii along X, Y, and Z. Useful when a
 * sphere is too symmetric, like a wide low dome or a tall narrow column.
 *
 * ## How could this be used?
 *
 * A flat arena floor zone (`radiusX = radiusZ = 10`, `radiusY = 1.5`) that triggers an
 * effect on players standing on it but ignores spectators in the stands above.
 */
class EllipsoidRegionDefinitionEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("World position the region is anchored to. The editor captures it from the box you mark.")
    @ContentEditor(EllipsoidRegionContentMode::class)
    override val origin: Var<Position> = RegionDefaults.ORIGIN,
    @Help(RegionDefaults.OFFSET_HELP)
    override val offset: Var<Vector> = RegionDefaults.OFFSET,
    @Help(RegionDefaults.YAW_HELP)
    override val yaw: Var<Float> = RegionDefaults.YAW,
    @Help(RegionDefaults.PITCH_HELP)
    override val pitch: Var<Float> = RegionDefaults.PITCH,
    @Help("Rotation around the facing axis. Lets the region tilt in any vertical plane.")
    override val roll: Var<Float> = RegionDefaults.ROLL,
    @Help("Add the origin position's own yaw and pitch to the region's rotation.")
    override val rotateWithOrigin: Boolean = RegionDefaults.ROTATE_WITH_ORIGIN,
    @Help(RegionDefaults.COLOR_HELP)
    @WithAlpha
    @Default(RegionDefaults.COLOR_DEFAULT)
    override val color: Color = RegionDefaults.COLOR,
    @Help("Which region wins where two overlap. Higher wins. Defaults to the page's priority.")
    override val priorityOverride: Optional<Int> = Optional.empty(),
    @Help("The rules this region carries: what may and may not happen inside it.")
    override val modifiers: List<Ref<out RegionModifierEntry>> = emptyList(),
    @Min(0)
    @Help("Half-extent along the local X axis.")
    @Default("5.0")
    val radiusX: Double = 5.0,
    @Min(0)
    @Help("Half-extent along the local Y axis (vertical before pitch).")
    @Default("5.0")
    val radiusY: Double = 5.0,
    @Min(0)
    @Help("Half-extent along the local Z axis.")
    @Default("5.0")
    val radiusZ: Double = 5.0,
    @Min(1)
    @Help("How often a region that follows a variable re-checks where it is. Higher values cost less and lag further behind.")
    @Default("1")
    override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
) : RegionDefinitionEntry {
    override fun buildShape(): Shape = EllipsoidShape(radiusX, radiusY, radiusZ)
}
