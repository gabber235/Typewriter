package com.typewritermc.region.entries.definition

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.content.CapsuleRegionContentMode
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CapsuleShape
import com.typewritermc.region.shape.Shape
import java.util.Optional

@Entry("capsule_region_definition", "A capsule region (cylinder with hemispherical caps)", Colors.PURPLE, "mdi:pill")
/**
 * Defines a capsule shaped region aligned with the local Y axis: a cylinder of [radius]
 * and total cylindrical height `2 * halfHeight`, capped by two hemispheres of [radius].
 *
 * ## How could this be used?
 *
 * Make a personal bubble around a player by anchoring the origin to the player's location,
 * with `radius = 1.5` and `halfHeight = 1.0` to cover a standing player.
 */
class CapsuleRegionDefinitionEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("World position the region is anchored to. The editor captures it from the box you mark.")
    @ContentEditor(CapsuleRegionContentMode::class)
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
    @Help("Radius of the capsule, both of its rounded ends and of the column between them.")
    @Default("1.0")
    val radius: Double = 1.0,
    @Min(0)
    @Help("Distance from the center to where each rounded end begins, before the radius is added.")
    @Default("1.0")
    val halfHeight: Double = 1.0,
    @Min(1)
    @Help("How often a region that follows a variable re-checks where it is. Higher values cost less and lag further behind.")
    @Default("1")
    override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
) : RegionDefinitionEntry {
    override fun buildShape(): Shape = CapsuleShape(radius, halfHeight)
}
