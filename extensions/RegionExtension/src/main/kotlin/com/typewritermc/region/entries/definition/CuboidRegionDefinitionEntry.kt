package com.typewritermc.region.entries.definition

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.content.CuboidRegionContentMode
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import java.util.Optional

@Entry("cuboid_region_definition", "A box region, rotatable on all three axes", Colors.PURPLE, "mdi:cube-outline")
/**
 * Defines a box shaped region centered on the resolved transform. The user specifies the
 * box's *half extents* along each axis; the geometric center sits at the resolved origin,
 * so to anchor by a corner set the [offset] accordingly.
 *
 * ## How could this be used?
 *
 * A 5×3×5 patio trigger box around a dialogue NPC: `halfX = 2.5, halfY = 1.5, halfZ = 2.5`,
 * origin set to the NPC's location, `offset = (0, 1.5, 0)` so the box rests on the ground.
 */
class CuboidRegionDefinitionEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("World position the region is anchored to. The editor captures two corners and fills the half-extents.")
    @ContentEditor(CuboidRegionContentMode::class)
    override val origin: Var<Position> = RegionDefaults.ORIGIN,
    @Help("Translation from the resolved origin, in the yaw-rotated local frame.")
    override val offset: Var<Vector> = RegionDefaults.OFFSET,
    @Help("Rotation around the vertical axis. Rotates the box itself and the offset's horizontal components.")
    override val yaw: Var<Float> = RegionDefaults.YAW,
    @Help("Rotation around the horizontal axis. Rotates the box only, not the offset.")
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
    @Help("Distance from the center to the east and west faces. The full width is twice this.")
    @Default("1.0")
    val halfX: Double = 1.0,
    @Min(0)
    @Help("Distance from the center to the floor and ceiling. The full height is twice this.")
    @Default("1.0")
    val halfY: Double = 1.0,
    @Min(0)
    @Help("Distance from the center to the north and south faces. The full depth is twice this.")
    @Default("1.0")
    val halfZ: Double = 1.0,
    @Min(1)
    @Help("How often a region that follows a variable re-checks where it is. Higher values cost less and lag further behind.")
    @Default("1")
    override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
) : RegionDefinitionEntry {
    override fun buildShape(): Shape = CuboidShape(halfX, halfY, halfZ)
}
