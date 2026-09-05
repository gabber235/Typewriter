package com.typewritermc.region.entries.definition

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.content.PolygonRegionContentMode
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.PolygonShape
import com.typewritermc.region.shape.Shape
import java.util.Optional

@Entry(
    "polygon_region_definition",
    "A polygon-prism region anchored to a position",
    Colors.PURPLE,
    "mdi:vector-polygon"
)
/**
 * Defines a polygonal prism region: the polygon spanned by [points] in the horizontal
 * plane, extruded [halfHeight] blocks up and down from the world resolved [origin] (plus
 * yaw rotated [offset]).
 *
 * Points are local frame coordinates relative to the resolved origin; only their X and Z
 * components are used. At least three points are required; the polygon may be concave but
 * must not self intersect.
 *
 * ## How could this be used?
 *
 * Trace the actual outline of a build that no box or sphere fits (a town wall, an
 * irregular arena floor) and hook enter/leave events or displays to it.
 */
class PolygonRegionDefinitionEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("World position the region is anchored to. The editor captures outline points walked in game.")
    @ContentEditor(PolygonRegionContentMode::class)
    override val origin: Var<Position> = RegionDefaults.ORIGIN,
    @Help("Translation from the resolved origin, in the yaw-rotated local frame.")
    override val offset: Var<Vector> = RegionDefaults.OFFSET,
    @Help("Rotation around the vertical axis, applied to the whole polygon.")
    override val yaw: Var<Float> = RegionDefaults.YAW,
    @Help("Rotation around the horizontal axis. Usually 0 for prisms.")
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
    @Help("Polygon outline points relative to the origin; only X and Z are used. Needs at least 3.")
    val points: List<Vector> = emptyList(),
    @Min(0)
    @Help("Half the prism's height in blocks; the prism spans origin Y ± this value.")
    @Default("2.0")
    val halfHeight: Double = 2.0,
    @Min(1)
    @Help("How often a region that follows a variable re-checks where it is. Higher values cost less and lag further behind.")
    @Default("1")
    override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
) : RegionDefinitionEntry {
    override fun buildShape(): Shape = PolygonShape(points, halfHeight)
}
