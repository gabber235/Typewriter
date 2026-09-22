package com.typewritermc.region.entries.definition

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.content.ConeRegionContentMode
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.ConeShape
import com.typewritermc.region.shape.Shape
import java.util.Optional

@Entry("cone_region_definition", "A cone region (e.g. NPC field of view)", Colors.PURPLE, "mdi:cone")
/**
 * Defines a cone shaped region pointing along the local +Z axis. To make a guard's vision
 * cone, anchor [origin] to the guard's position variable and enable [rotateWithOrigin] so
 * the cone turns with the guard's facing.
 *
 * ## How could this be used?
 *
 * A vision cone: anchor to an NPC position variable, set `offset = (0, 1.6, 0)` for eye
 * height, enable `rotateWithOrigin`, `length = 12`, `halfAngleDegrees = 30`.
 */
class ConeRegionDefinitionEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("World position the cone's point is anchored to. The editor captures it from the apex you mark.")
    @ContentEditor(ConeRegionContentMode::class)
    override val origin: Var<Position> = RegionDefaults.ORIGIN,
    @Help(RegionDefaults.OFFSET_HELP)
    override val offset: Var<Vector> = RegionDefaults.OFFSET,
    @Help("Cone direction yaw. Tie to NPC/player yaw for a follow-the-look effect.")
    override val yaw: Var<Float> = RegionDefaults.YAW,
    @Help("Cone direction pitch. Tie to NPC/player pitch for vertical tracking.")
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
    @Help("How far the cone reaches from its point.")
    @Default("8.0")
    val length: Double = 8.0,
    @Min(1)
    @Max(89)
    @Help("Half-angle of the cone in degrees. A wider angle opens the cone; 89 is nearly a half sphere.")
    @Default("30.0")
    val halfAngleDegrees: Double = 30.0,
    @Min(1)
    @Help("How often a region that follows a variable re-checks where it is. Higher values cost less and lag further behind.")
    @Default("1")
    override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
) : RegionDefinitionEntry {
    override fun buildShape(): Shape = ConeShape(length, halfAngleDegrees)
}
