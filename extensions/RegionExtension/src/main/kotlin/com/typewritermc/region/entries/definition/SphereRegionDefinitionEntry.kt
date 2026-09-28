package com.typewritermc.region.entries.definition

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.content.SphereRegionContentMode
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.SphereShape
import java.util.Optional

@Entry("sphere_region_definition", "A spherical region anchored to a position", Colors.PURPLE, "mdi:sphere")
/**
 * Defines a spherical region: a ball of radius [radius] centered on the world resolved
 * [origin] (plus yaw rotated [offset]).
 *
 * ## How could this be used?
 *
 * Anchor [origin] to a fixed position for a static merchant zone, or to an NPC location
 * variable to make a no trespass sphere that follows the NPC.
 */
class SphereRegionDefinitionEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("World position the region is anchored to. The editor captures the center and a boundary point.")
    @ContentEditor(SphereRegionContentMode::class)
    override val origin: Var<Position> = RegionDefaults.ORIGIN,
    @Help("Translation from the resolved origin, in the yaw-rotated local frame.")
    override val offset: Var<Vector> = RegionDefaults.OFFSET,
    @Help("Rotation around the vertical axis. Spheres are rotationally symmetric so this only matters for the offset.")
    override val yaw: Var<Float> = RegionDefaults.YAW,
    @Help("Rotation around the horizontal axis. Spheres are rotationally symmetric.")
    override val pitch: Var<Float> = RegionDefaults.PITCH,
    @Help("Rotation around the facing axis. Spheres are rotationally symmetric, and the offset is placed by yaw alone, so this changes nothing here.")
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
    @Help("Sphere radius in blocks.")
    @Default("5.0")
    val radius: Double = 5.0,
    @Min(1)
    @Help("How often a region that follows a variable re-checks where it is. Higher values cost less and lag further behind.")
    @Default("1")
    override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
) : RegionDefinitionEntry {
    override fun buildShape(): Shape = SphereShape(radius)
}
